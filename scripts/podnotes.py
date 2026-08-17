#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""Transkribiert Audiodateien mit Whisper und schreibt JSON + Obsidian-Markdown.

Die Rechenarbeit laeuft per Default auf einem entfernten Rechner mit GPU. Dieses
Script hat selbst keine Abhaengigkeiten: es bootstrappt drueben ein venv, schiebt
die Audiodatei hin, streamt den Worker-Code durch stdin und liest das Ergebnis-JSON
von stdout zurueck.

SSH-Konfiguration ist absichtlich NICHT Teil der CLI. Uebergeben wird nur ein
ssh-Destination-String; User, Port, Key, ProxyJump usw. gehoeren nach
~/.ssh/config. Aufloesung des Ziels in dieser Reihenfolge:

    --host <dest>  ->  $PODNOTES_HOST  ->  ~/.config/podnotes/host

Zusaetzliche ssh-Optionen bei Bedarf ueber $PODNOTES_SSH_OPTS.

    podnotes.py folge-42.mp3                  # -> folge-42.json + folge-42.md
    podnotes.py *.mp3 --outdir ~/wiki/podcasts
    podnotes.py folge-42.mp3 --local          # ohne ssh, auf dieser Maschine
    podnotes.py folge-42.mp3                  # JSON existiert schon -> nur neu rendern
"""

from __future__ import annotations

import argparse
import json
import os
import re
import shlex
import subprocess
import sys
from pathlib import Path

HOST_FILE = Path.home() / ".config" / "podnotes" / "host"
REMOTE_WORKDIR = "~/.cache/podnotes"
# Auf aktuellen Arch-Kisten ist das System-Python oft neuer als die
# ctranslate2-Wheels. Darum eine bekannt funktionierende Version pinnen.
REMOTE_PYTHON = "3.12"
PIP_PACKAGES = "faster-whisper nvidia-cublas-cu12 nvidia-cudnn-cu12"

AUDIO_SUFFIXES = {".mp3", ".m4a", ".m4b", ".opus", ".ogg", ".oga", ".wav",
                  ".flac", ".aac", ".wma", ".webm", ".mp4", ".mkv"}

# ---------------------------------------------------------------- Worker (remote)

WORKER = r'''
import json, os, sys

audio, model_name, language, batch_size = sys.argv[1], sys.argv[2], sys.argv[3], int(sys.argv[4])
language = language or None

from faster_whisper import WhisperModel

def log(msg):
    print(msg, file=sys.stderr, flush=True)

try:
    model = WhisperModel(model_name, device="cuda", compute_type="float16")
    device = "cuda/float16"
except Exception as exc:
    log(f"cuda nicht verfuegbar ({type(exc).__name__}), fallback auf cpu/int8")
    model = WhisperModel(model_name, device="cpu", compute_type="int8")
    device = "cpu/int8"
log(f"modell {model_name} geladen ({device})")

kw = dict(language=language, vad_filter=True, word_timestamps=True)
try:
    from faster_whisper import BatchedInferencePipeline
    segments, info = BatchedInferencePipeline(model=model).transcribe(
        audio, batch_size=batch_size, **kw)
    mode = f"batched({batch_size})"
except Exception as exc:
    log(f"batched pipeline nicht verfuegbar ({type(exc).__name__}), sequentiell")
    segments, info = model.transcribe(audio, **kw)
    mode = "sequential"
log(f"audio {info.duration:.0f}s, sprache {info.language}, modus {mode}")

segs, nwords = [], 0
for s in segments:
    words = [{"s": round(w.start, 2), "e": round(w.end, 2), "w": w.word,
              "p": round(w.probability, 3)} for w in (s.words or [])]
    nwords += len(words)
    segs.append({
        "start": s.start, "end": s.end, "text": s.text.strip(),
        "avg_logprob": round(s.avg_logprob, 3),
        "no_speech_prob": round(s.no_speech_prob, 3),
        "compression_ratio": round(s.compression_ratio, 3),
        "words": words,
    })
    if len(segs) % 50 == 0:
        log(f"  {nwords} woerter, bei minute {s.end / 60:.0f} von {info.duration / 60:.0f}")

log(f"fertig: {nwords} woerter in {len(segs)} segmenten")
json.dump({"model": model_name, "device": device, "mode": mode,
           "language": info.language, "duration": info.duration,
           "segments": segs}, sys.stdout)
'''

# ------------------------------------------------------------------- Segmentierung

# Abkuerzungen, nach denen ein Punkt kein Satzende markiert
ABBREV = {
    "mr", "mrs", "ms", "dr", "prof", "st", "jr", "sr", "vs", "etc", "inc", "ltd",
    "co", "sen", "rep", "gov", "gen", "col", "lt", "sgt", "capt", "no", "vol",
    "approx", "dept", "est", "fig", "i.e", "e.g", "u.s", "u.k", "a.m", "p.m",
    "z.b", "bzw", "ggf", "usw", "evtl", "ca", "nr", "abs", "vgl", "bspw",
}
PAUSE_BREAK = 1.5           # Sprechpause in s, die einen Blockumbruch erzwingt
MIN_WORDS = 8               # kleiner als das wird in den Nachbarn eingeschmolzen
HARD_MAX_SECONDS = 45.0     # Notbremse, wenn Whisper keine Satzzeichen setzt
HARD_MAX_WORDS = 120


def is_sentence_end(token: str) -> bool:
    t = token.strip()
    if not re.search(r"[.!?]['\")\]]*$", t):
        return False
    core = re.sub(r"[^\w.]", "", t).rstrip(".").lower()
    if core in ABBREV:
        return False
    return not (len(core) == 1 and core.isalpha())  # Initialen wie "J."


def build_blocks(words: list[dict], target_seconds: float, max_words: int) -> list[list[dict]]:
    """Gruppiert Woerter zu Bloecken, die moeglichst an Satzgrenzen beginnen."""
    sentences, cur = [], []
    for w in words:
        cur.append(w)
        if is_sentence_end(w["w"]):
            sentences.append(cur)
            cur = []
    if cur:
        sentences.append(cur)

    # Saetze zu Bloecken buendeln, bis Zielspanne oder Wortgrenze erreicht ist
    grouped, cur = [], []
    for sent in sentences:
        cur.append(sent)
        span = cur[-1][-1]["e"] - cur[0][0]["s"]
        if span >= target_seconds or sum(len(s) for s in cur) >= max_words:
            grouped.append(cur)
            cur = []
    if cur:
        grouped.append(cur)

    # An langen Sprechpausen zusaetzlich trennen (bei Clip-Shows: Schnitte)
    pieces = []
    for blk in grouped:
        piece = []
        for i, sent in enumerate(blk):
            piece.append(sent)
            if i + 1 < len(blk):
                gap = blk[i + 1][0]["s"] - sent[-1]["e"]
                if gap > PAUSE_BREAK and sum(len(s) for s in piece) >= MIN_WORDS:
                    pieces.append(piece)
                    piece = []
        if piece:
            pieces.append(piece)

    runs = [[w for sent in p for w in sent] for p in pieces]
    runs = [r for r in runs if r]

    # Notbremse mitskalieren, sonst zersaegt sie bei grossem --block-seconds
    # genau die Bloecke, die man haben wollte.
    hard_seconds = max(HARD_MAX_SECONDS, target_seconds * 2.25)
    hard_words = max(HARD_MAX_WORDS, max_words * 2)

    def split_oversized(run: list[dict]) -> list[list[dict]]:
        span = run[-1]["e"] - run[0]["s"]
        if span <= hard_seconds and len(run) <= hard_words:
            return [run]
        lo, hi = int(len(run) * 0.25), int(len(run) * 0.75)
        mid = (len(run) // 2 if hi - lo < 2
               else max(range(lo, hi), key=lambda i: run[i]["s"] - run[i - 1]["e"]))
        return split_oversized(run[:mid]) + split_oversized(run[mid:])

    runs = [part for r in runs for part in split_oversized(r)]

    merged: list[list[dict]] = []
    for run in runs:
        if merged and len(run) < MIN_WORDS:
            merged[-1].extend(run)
        else:
            merged.append(run)
    if len(merged) > 1 and len(merged[0]) < MIN_WORDS:
        merged[1] = merged[0] + merged[1]
        merged.pop(0)
    return merged


def summarize(run: list[dict]) -> dict:
    probs = [w["p"] for w in run]
    return {
        "start": run[0]["s"],
        "end": run[-1]["e"],
        "text": re.sub(r"\s+", " ", "".join(w["w"] for w in run).strip()),
        "nwords": len(run),
        "mean_prob": round(sum(probs) / len(probs), 3),
        "min_prob": round(min(probs), 3),
    }


# ------------------------------------------------------------------------ Rendering

def hms(t: float) -> str:
    t = int(t)
    if t >= 3600:
        return f"{t // 3600:d}:{t % 3600 // 60:02d}:{t % 60:02d}"
    return f"{t // 60:02d}:{t % 60:02d}"


def render_markdown(data: dict, asset: str, embed_every: float) -> str:
    blocks = data["blocks"]
    words = sum(b["nwords"] for b in blocks)
    fragments = sum(1 for b in blocks if b["text"][:1].islower())
    worst = min((b["mean_prob"] for b in blocks), default=1.0)

    lines = [
        f"# {Path(asset).stem.replace('_', ' ').replace('-', ' ').strip()}",
        "",
        f"- Quelle: `{asset}`",
        f"- Laenge: {hms(data['duration'])} · {len(blocks)} Bloecke · {words} Woerter",
        f"- Modell: `{data['model']}` ({data['mode']}, {data['device']}) · Sprache: {data['language']}",
        f"- Schlechtester Block: mean_prob {worst:.3f}",
    ]
    if fragments:
        lines.append(f"- `…` am Blockanfang: faengt mitten im Satz an ({fragments} Stueck)")
    lines += ["", "---", ""]

    next_embed = 0.0
    for b in blocks:
        if b["start"] >= next_embed:
            lines.append(f"![[{asset}#t={int(b['start'])}]]")
            next_embed = b["start"] + embed_every if embed_every > 0 else 0.0
        text = ("… " if b["text"][:1].islower() else "") + b["text"]
        lines += [f"**{hms(b['start'])}** {text}", ""]
    return "\n".join(lines)


# ----------------------------------------------------------------------- Ausfuehrung

def resolve_host(explicit: str | None) -> str:
    if explicit:
        return explicit
    if os.environ.get("PODNOTES_HOST"):
        return os.environ["PODNOTES_HOST"]
    if HOST_FILE.is_file():
        for line in HOST_FILE.read_text().splitlines():
            line = line.strip()
            if line and not line.startswith("#"):
                return line
    sys.exit(
        f"Kein Ziel bekannt. Entweder --host <ssh-dest>, oder $PODNOTES_HOST setzen,\n"
        f"oder den Destination-String in {HOST_FILE} schreiben:\n"
        f"    mkdir -p {HOST_FILE.parent} && echo meine-gpu-kiste > {HOST_FILE}\n"
        f"User/Port/Key gehoeren nach ~/.ssh/config, nicht hierher. Alternativ --local."
    )


def ssh_opts() -> list[str]:
    return shlex.split(os.environ.get("PODNOTES_SSH_OPTS", ""))


def bootstrap_script() -> str:
    """Idempotentes Setup des venv drueben (bzw. lokal bei --local)."""
    return f"""
set -eu
WORKDIR=$(eval echo {REMOTE_WORKDIR})
VENV="$WORKDIR/venv"
mkdir -p "$WORKDIR/audio"
command -v uv >/dev/null || {{ echo "uv fehlt auf dem Zielrechner" >&2; exit 1; }}
if [ ! -x "$VENV/bin/python" ]; then
    echo "podnotes: venv anlegen (python {REMOTE_PYTHON})" >&2
    uv venv --python {REMOTE_PYTHON} "$VENV" >&2 </dev/null
fi
if ! "$VENV/bin/python" -c 'import faster_whisper' 2>/dev/null </dev/null; then
    echo "podnotes: faster-whisper installieren (einmalig, ~2 GB)" >&2
    uv pip install --quiet --python "$VENV/bin/python" {PIP_PACKAGES} >&2 </dev/null
fi
"""


def worker_script(audio_assign: str, model: str, language: str, batch_size: int) -> str:
    """Setup + Worker-Aufruf. Der Worker-Code kommt ueber ein Here-Doc.

    audio_assign ist ein Shell-Snippet, das AUDIO_PATH setzt. Der Pfad wird
    absichtlich in der Shell zusammengebaut, damit ~ dort expandiert wird und
    nicht als Literal bei Python landet.
    """
    args = " ".join(shlex.quote(a) for a in (model, language or "", str(batch_size)))
    return bootstrap_script() + f"""
{audio_assign}
NVLIBS=$(printf '%s:' "$VENV"/lib/python*/site-packages/nvidia/*/lib 2>/dev/null || true)
export LD_LIBRARY_PATH="$NVLIBS${{LD_LIBRARY_PATH:-}}"
export HF_HOME="$WORKDIR/hf"
"$VENV/bin/python" - "$AUDIO_PATH" {args} <<'PODNOTES_WORKER_EOF'
{WORKER}
PODNOTES_WORKER_EOF
"""


def run(cmd: list[str]) -> None:
    """Fuehrt cmd aus; stderr laeuft direkt ins Terminal (Progress)."""
    if subprocess.run(cmd, check=False).returncode != 0:
        sys.exit(f"podnotes: Kommando fehlgeschlagen: {shlex.join(cmd)}")


def transcribe_remote(audio: Path, host: str, args: argparse.Namespace) -> dict:
    opts = ssh_opts()
    print(f"podnotes: {audio.name} -> {host}", file=sys.stderr)
    run(["ssh", *opts, host, f"mkdir -p {REMOTE_WORKDIR}/audio"])
    run(["scp", "-q", *opts, str(audio), f"{host}:{REMOTE_WORKDIR}/audio/"])

    # Script ueber stdin an eine Remote-Shell geben, JSON von stdout lesen
    audio_assign = (f"AUDIO_NAME={shlex.quote(audio.name)}\n"
                    f'AUDIO_PATH="$WORKDIR/audio/$AUDIO_NAME"')
    script = worker_script(audio_assign, args.model, args.language, args.batch_size)
    proc = subprocess.run(["ssh", *opts, host, "sh -s"], input=script.encode(),
                          stdout=subprocess.PIPE, check=False)
    if proc.returncode != 0 or not proc.stdout.strip():
        sys.exit(f"podnotes: Transkription auf {host} fehlgeschlagen ({proc.returncode})")

    if not args.keep_remote:
        # Tilde unquoted lassen (Shell expandiert), nur den Dateinamen quoten
        run(["ssh", *opts, host, f"rm -f {REMOTE_WORKDIR}/audio/{shlex.quote(audio.name)}"])
    return json.loads(proc.stdout)


def transcribe_local(audio: Path, args: argparse.Namespace) -> dict:
    print(f"podnotes: {audio.name} lokal", file=sys.stderr)
    audio_assign = f"AUDIO_PATH={shlex.quote(str(audio.resolve()))}"
    script = worker_script(audio_assign, args.model, args.language, args.batch_size)
    proc = subprocess.run(["sh", "-s"], input=script.encode(), stdout=subprocess.PIPE, check=False)
    if proc.returncode != 0 or not proc.stdout.strip():
        sys.exit(f"podnotes: lokale Transkription fehlgeschlagen ({proc.returncode})")
    return json.loads(proc.stdout)


def process(audio: Path, args: argparse.Namespace) -> None:
    outdir = Path(args.outdir).expanduser() if args.outdir else audio.parent
    outdir.mkdir(parents=True, exist_ok=True)
    json_path, md_path = outdir / f"{audio.stem}.json", outdir / f"{audio.stem}.md"

    if json_path.is_file() and not args.force:
        print(f"podnotes: {json_path.name} existiert, rendere neu (--force transkribiert neu)",
              file=sys.stderr)
        data = json.loads(json_path.read_text())
    else:
        data = (transcribe_local(audio, args) if args.local
                else transcribe_remote(audio, resolve_host(args.host), args))
        data["audio"] = audio.name

    words = [w for s in data["segments"] for w in s["words"]]
    if not words:
        sys.exit(f"podnotes: keine Wort-Timestamps fuer {audio.name} — nichts zu rendern")
    data["blocks"] = [summarize(r) for r in
                      build_blocks(words, args.block_seconds, args.max_words)]

    json_path.write_text(json.dumps(data))
    md_path.write_text(render_markdown(data, data.get("audio", audio.name), args.embed_every))

    blocks = data["blocks"]
    spans = sorted(b["end"] - b["start"] for b in blocks)
    print(f"podnotes: {md_path} ({len(blocks)} Bloecke, median "
          f"{spans[len(spans) // 2]:.0f}s) + {json_path.name}", file=sys.stderr)


def main() -> None:
    p = argparse.ArgumentParser(
        description="Transkribiert Audio via Whisper zu JSON + Obsidian-Markdown.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="SSH-Ziel: --host, sonst $PODNOTES_HOST, sonst ~/.config/podnotes/host.\n"
               "User/Port/Key gehoeren nach ~/.ssh/config. Extra-Flags: $PODNOTES_SSH_OPTS.",
    )
    p.add_argument("audio", nargs="+", type=Path, help="Audiodatei(en)")
    p.add_argument("--host", help="ssh-Destination des Rechners mit GPU")
    p.add_argument("--local", action="store_true", help="auf dieser Maschine rechnen")
    p.add_argument("-o", "--outdir", help="Zielverzeichnis (Default: neben der Audiodatei)")
    p.add_argument("--model", default="large-v3", help="Whisper-Modell (Default: large-v3)")
    p.add_argument("--language", default="", help="Sprachcode, z.B. de/en (Default: automatisch)")
    p.add_argument("--block-seconds", type=float, default=20.0,
                   help="Zielspanne pro Textblock in s (Default: 20)")
    p.add_argument("--max-words", type=int, default=None,
                   help="Wortgrenze pro Block (Default: 3x --block-seconds, also 60 bei 20s)")
    p.add_argument("--embed-every", type=float, default=120.0,
                   help="Abstand der ![[...#t=]]-Sprungmarken in s; 0 = jeder Block (Default: 120)")
    p.add_argument("--batch-size", type=int, default=16, help="GPU-Batchgroesse (Default: 16)")
    p.add_argument("--force", action="store_true", help="neu transkribieren, auch wenn JSON existiert")
    p.add_argument("--keep-remote", action="store_true",
                   help="kopierte Audiodatei auf dem Zielrechner nicht loeschen")
    args = p.parse_args()
    # Rund 3 Woerter pro Sekunde gesprochene Sprache: so bleibt --block-seconds
    # der eine wirksame Regler, statt von einer festen Wortgrenze ausgebremst zu werden.
    if args.max_words is None:
        args.max_words = max(MIN_WORDS + 1, int(args.block_seconds * 3))

    files = []
    for a in args.audio:
        a = a.expanduser()
        if not a.is_file():
            sys.exit(f"podnotes: keine Datei: {a}")
        if a.suffix.lower() not in AUDIO_SUFFIXES:
            print(f"podnotes: warnung: {a.name} sieht nicht wie Audio aus", file=sys.stderr)
        files.append(a)

    for audio in files:
        process(audio, args)


if __name__ == "__main__":
    main()
