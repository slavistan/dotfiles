"""Datenstrukturen, die zwischen den Prozessen wandern.

Drei Prozesse sind beteiligt: der kitty-Prozess (Watcher und Stufe 1), der
UI-Prozess (Stufe 2, fzf) und wieder der kitty-Prozess (Dispatch). Die
Prozessgrenze liegt zwischen Stufe 1 und Stufe 2 -- dort wandert eine
Session als JSON in die stdin der UI, zurueck kommt eine Selection.

Die Klassen hier sind die einzige Stelle, an der die Form dieser Daten
steht; beide Seiten bauen ihre Objekte ueber from_dict/asdict daraus.
"""

from dataclasses import dataclass, fields, is_dataclass
from types import UnionType
from typing import Union, get_args, get_origin, get_type_hints


@dataclass
class CommandRun:
    """Was der Watcher zu einem ausgefuehrten Kommando mitbekommen hat.

    Quelle ist OSC 133;C bzw. ;D, das kitty ohnehin auswertet -- die cmdline
    ist von kitty bereits entquotet (kitty/window.py: decode_cmdline). Das
    cwd kommt aus der OSC-7-Meldung der Shell und ist damit unabhaengig
    davon, ob der Prompt es anzeigt.
    """

    cmdline: str
    cwd: str                          # Arbeitsverzeichnis, in dem es lief
    started_at: float                 # Wanduhr, time.time()
    started_mono: float               # monotonic, nur Basis fuer duration
    duration: float | None            # None -> laeuft noch
    exit_status: int | None


@dataclass
class Block:
    """Ein abgeschickter Befehl samt seiner Ausgabe.

    Ein Block reicht von einer PROMPT_START-Zeile bis ausschliesslich zur
    naechsten. Die Zeilen davor OUTPUT_START sind Prompt und getipptes
    Kommando, ab OUTPUT_START die Ausgabe.

    Es gibt Bloecke nur mit zugeordnetem CommandRun. Prompt-Gruppen ohne
    Kommando -- der Live-Prompt, ein blankes Enter, alles was aelter ist als
    der Watcher -- werden in Stufe 1 verworfen, statt halbe Bloecke durch die
    ganze Kette zu reichen.
    """

    index: int                        # Position in der Prompt-Folge, 0 = aeltester
    prompt_lines: list[str]           # ANSI, Prompt und getipptes Kommando
    head_lines: int                   # Zeilen davon bis einschl. erster Kommandozeile
    n_output: int                     # Anzahl Ausgabezeilen
    output_file: str                  # Datei im Spool: Ausgabe fuer Pager und Zwischenablage
    prompt_line: int                  # 1-basierte Zeile des Prompts in Session.buffer
    end_line: int                     # 1-basierte letzte Zeile des Blocks
    run: CommandRun                   # immer gesetzt -- ohne Zuordnung kein Block


@dataclass
class Session:
    """Was Stufe 1 der UI reicht."""

    spool: str                        # Verzeichnis mit den Dateien unten
    buffer: str                       # Datei im Spool: der Scrollback, Zeile fuer Zeile
    buffer_dim: str                   # dieselben Zeilen, alle SGR-2-gedimmt
    n_prompts: int                    # alle PROMPT_START-Zeilen, auch gefilterte
    blocks: list[Block]               # nur die angezeigten, aelteste zuerst
    selected: int                     # Index in blocks, den die UI vorwaehlt


@dataclass
class Selection:
    """Was die UI zurueckgibt."""

    action: str                       # 'jump' | 'pager' | 'paste' | 'none'
    block_index: int = -1             # Index in Session.blocks


def from_dict(cls, raw):
    """Baut eine dataclass aus verschachtelten dicts (JSON-Rueckweg)."""
    hints = get_type_hints(cls)
    return cls(**{f.name: _coerce(hints[f.name], raw.get(f.name))
                  for f in fields(cls)})


def _coerce(hint, value):
    if value is None:
        return None
    origin = get_origin(hint)
    if origin in (Union, UnionType):          # X | None
        inner = [a for a in get_args(hint) if a is not type(None)]
        return _coerce(inner[0], value) if len(inner) == 1 else value
    if origin is list:
        (inner,) = get_args(hint)
        return [_coerce(inner, v) for v in value]
    if is_dataclass(hint):
        return from_dict(hint, value)
    return value
