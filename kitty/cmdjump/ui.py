"""Stufe 2 -- die Oberflaeche.

Bekommt eine fertige Session auf stdin und gibt eine Selection zurueck.
Kennt weder kitty-Interna noch den Scrollback: alles, was angezeigt wird,
steht in der Session, die Ausgaben liegen als Dateien im Spool.

Beim Oeffnen ist der Block vorgewaehlt, den der View gerade zeigt -- nach
einem Esc-Sprung also derselbe wie zuvor, das Menue kommt im alten Zustand
zurueck. Die Vorschau oben zeigt den Scrollback ab dem markierten Prompt:
die erste Vorschauzeile ist der Prompt selbst. Die Liste darunter laeuft chronologisch
wie der Scrollback -- aeltestes oben, neuestes unten am Eingabefeld -- damit
ctrl-p/n in Liste und Vorschau in dieselbe Richtung gehen. Beim Schliessen
landet der markierte Prompt in der obersten Terminalzeile; fehlt dafuer
unten Inhalt, macht der Dispatch die Zeilen real (History bleibt erhalten)
und landet bei scrolled_by == 0 -- Tippen bewegt die Ansicht dann nicht.

  Enter   Kommandozeile in die Shell legen; Ansicht springt ans Ende
  Ctrl-O  Prompt und Ausgabe im scrollback_pager oeffnen
  Ctrl-Y  Prompt und Ausgabe in die Zwischenablage
  Esc     schliessen, Ansicht bleibt beim markierten Prompt

Die Beschriftungen sind englisch, der Rest des Codes deutsch.
"""

import json
import os
import re
import shlex
import subprocess
import sys
from dataclasses import asdict
from datetime import datetime

from model import Selection, Session, from_dict

# OSC-Zweig von kitty_ansi_sanitizer_pat: entfernt Marker und Hyperlinks,
# laesst die Farben stehen. fzf laeuft mit --ansi und kann SGR, mit OSC
# wuerde es das Terminal beschreiben.
OSC_ONLY = re.compile(r'\x1b\].*?\x1b\\')

MAX_PROMPT_LINES = 5      # laengere Prompt-Bloecke werden gekuerzt

DIM = '\x1b[90m'
RED = '\x1b[31m'
OFF = '\x1b[m'


def colored(s: str) -> str:
    return OSC_ONLY.sub('', s)


def format_duration(seconds: float) -> str:
    if seconds < 1:
        return f'{seconds * 1000:.0f}ms'
    if seconds < 60:
        return f'{seconds:.1f}s'
    return f'{int(seconds) // 60}m{int(seconds) % 60:02d}s'


def format_when(started_at: float) -> str:
    when = datetime.fromtimestamp(started_at)
    same_day = when.date() == datetime.now().date()
    return when.strftime('%H:%M' if same_day else '%d.%m. %H:%M')


def format_meta(block) -> str:
    """Gedimmter Zusatz hinter dem Kommando."""
    run = block.run
    parts = [
        'no output' if block.n_output == 0 else
        '1 line' if block.n_output == 1 else f'{block.n_output} lines',
        'running' if run.duration is None else format_duration(run.duration),
        format_when(run.started_at),
    ]
    text = f'{DIM}({" · ".join(parts)}){OFF}'
    if run.exit_status:
        text += f' {RED}[{run.exit_status}]{OFF}'
    return text


def elide(lines: list, head: int) -> list:
    """Kuerzt zu hohe Prompt-Bloecke in der Mitte.

    Ein mehrzeiliges Kommando kann beliebig viele Fortsetzungszeilen haben
    und wuerde sonst die ganze Liste fuellen. Behalten wird der Kopf --
    PS1-Kontext samt erster Kommandozeile, von Stufe 1 ueber die
    SECONDARY_PROMPT-Marken bestimmt -- und das Ende des Kommandos; die
    PS2-Zeilen dazwischen fallen raus.
    """
    if len(lines) <= MAX_PROMPT_LINES:
        return lines
    head = max(1, min(head, MAX_PROMPT_LINES - 2))
    tail = MAX_PROMPT_LINES - head - 1
    hidden = len(lines) - head - tail
    return lines[:head] + [f'{DIM}   ⋮ {hidden} more lines{OFF}'] + lines[-tail:]


def build_items(session: Session) -> list:
    """Eine NUL-getrennte fzf-Zeile pro Block, neueste zuerst.

    Der Prompt bleibt mehrzeilig und behaelt seine Farben; fzf stellt Items
    mit Zeilenumbruechen ab 0.53 mehrzeilig dar, sofern die Eingabe mit
    --read0 kommt.
    """
    items = []
    for n, block in enumerate(reversed(session.blocks)):
        lines = elide([colored(a).rstrip() for a in block.prompt_lines] or ['?'],
                      block.head_lines)
        lines[-1] += f'{OFF}  {format_meta(block)}'
        # Feld 1: Index in session.blocks, kommt in der Selection zurueck.
        # Feld 2: Rasterzeile des Prompts -- fzf setzt die Vorschau dorthin.
        # Feld 3: letzte Zeile des Blocks -- Ende des ungedimmten Bereichs.
        idx = len(session.blocks) - 1 - n
        items.append(f'{idx}\t{block.prompt_line}\t{block.end_line}\t'
                     + '\n'.join(lines))
    return items


def preview_cmd(session: Session) -> str:
    """Vorschau: selektierter Block in voller Intensitaet, Rest verblasst.

    Die gedimmte Fassung liegt vorberechnet neben dem Puffer (launch.py:
    faint), beide Dateien sind zeilengleich. Hier wird nur noch nach
    Zeilennummern gemischt -- Kopf und Schwanz aus der gedimmten Datei,
    der Block ({2}..{3}) aus der normalen. Kein Escape-Code-Gebastel im
    Shell-Kommando; wie blass "blass" ist, regelt kittys dim_opacity.
    """
    orig = shlex.quote(os.path.join(session.spool, session.buffer))
    dim = shlex.quote(os.path.join(session.spool, session.buffer_dim))
    # fzf setzt {2}/{3} shell-QUOTIERT ein ('4'); in $((...)) waere das ein
    # Syntaxfehler. Deshalb zuerst als Variablen uebernehmen, dann rechnen.
    return (f'a={{2}} b={{3}}; '
            f'head -n "$(( a - 1 ))" {dim}; '
            f'sed -n "${{a}},${{b}}p" {orig}; '
            f'tail -n "+$(( b + 1 ))" {dim}')


def run_fzf(session: Session, items: list) -> tuple:
    """fzf zeichnet seine UI selbst auf /dev/tty; stdin/stdout sind Pipes."""
    argv = [
        'fzf', '--read0', '--print0', '--ansi', '--no-sort', '--gap',
        '--delimiter=\t', '--with-nth=4..',
        '--expect=ctrl-o,ctrl-y,esc', '--prompt=cmd> ', '--info=inline',
        # Kontext des Views vorwaehlen (Stufe 1 hat ihn bestimmt): Stream ist
        # neuester-zuerst, Block b liegt also an Match-Position len - b.
        # --sync stellt sicher, dass die Position erst nach dem Einlesen
        # gesetzt wird.
        '--sync', f'--bind=start:pos({len(session.blocks) - session.selected})',
        # Beim Beenden raeumt fzf sonst seine Oberflaeche ab (Alternate
        # Screen verlassen) -- das Overlay zeigt dann fuer ein paar Frames
        # seinen leeren Hauptpuffer: sichtbares Flackern. Mit --no-clear
        # bleibt das letzte Bild stehen, bis kitty das Fenster schliesst;
        # der Sprung passiert davor im selben Tick (boss.py: actions_on_close
        # laufen vor remove_window), das Terminal erscheint also fertig
        # gescrollt, ohne Zwischenbild.
        '--no-clear',
        # Ohne --layout=reverse liegt der erste Eintrag (der juengste) unten
        # am Eingabefeld, aeltere stapeln sich darueber -- dieselbe Richtung
        # wie im Scrollback. ctrl-p/n sind fzf-Defaults fuer up/down und
        # laufen damit in Liste, Vorschau und Terminal gleichsinnig.
        #
        # Der Scrollbalken der Vorschau wuerde eine Spalte kosten; dann
        # brechen die Rasterzeilen um und alle Sprungziele verschieben sich.
        '--no-scrollbar',
        '--preview', preview_cmd(session),
        # noinfo: fzf malt sonst oben rechts in die Vorschau einen
        # Scroll-Indikator ('20/60' = zeige ab Zeile 20 von 60). Unsere
        # Offsets sind Sprungziele, keine Leseposition -- die Zahl
        # kommuniziert hier nichts.
        '--preview-window=up,70%,border-none,wrap,noinfo,+{2}',
        # Position von unten gezaehlt: der juengste Eintrag ist n/n, jedes
        # ctrl-p eins weniger. Zeigt zugleich, wieviel Historie noch da ist.
        '--info-command=echo $(( FZF_MATCH_COUNT - ${FZF_POS:-1} + 1 ))/$FZF_MATCH_COUNT',
        # Trennlinie, damit die Liste nicht wie Ausgabe des letzten Prompts
        # in der Vorschau aussieht.
        '--list-border=top',
        '--header=enter: to shell   ctrl-o: pager   ctrl-y: copy   '
        'ctrl-p/n: older/newer',
    ]
    proc = subprocess.run(argv, input='\0'.join(items) + '\0',
                          stdout=subprocess.PIPE, text=True)
    if proc.returncode not in (0, 1):
        return '', ''
    recs = proc.stdout.split('\0')
    return (recs[0] if recs else ''), (recs[1] if len(recs) > 1 else '')


# Esc laeuft ueber --expect, damit wir wissen, welcher Prompt markiert war
# und die Ansicht dort stehen lassen koennen.
ACTIONS = {'': 'paste', 'ctrl-o': 'pager', 'ctrl-y': 'clipboard', 'esc': 'jump'}


def main(args: list) -> dict:
    session = from_dict(Session, json.loads(sys.stdin.read()))
    key, sel = run_fzf(session, build_items(session))
    if not sel:
        return asdict(Selection(action='none'))
    index = int(sel.split('\t', 1)[0])
    return asdict(Selection(action=ACTIONS.get(key, 'paste'), block_index=index))
