"""Stufe 1 -- laeuft ohne eigene Oberflaeche direkt im kitty-Prozess.

Nur hier sind die Screen-Interna erreichbar: die Zeilenattribute ueber
dump_lines_with_attrs, der Zeilentext ueber Line.as_ansi und der vom
Watcher am Fenster gefuehrte Kommando-Log. Stufe 1 baut daraus die Bloecke,
legt die Ausgaben im Spool ab und startet die UI mit einer fertigen Session.

Der Rueckweg laeuft ueber custom_callback, nicht ueber handle_result -- so
haelt der Dispatch die Session, ohne sie global zwischenlagern zu muessen.

kitty.conf:
    watcher cmdjump/watcher.py
    map ctrl+r kitten cmdjump/launch.py
"""

import json
import os
import re
import shutil
import tempfile
from dataclasses import asdict, dataclass
from functools import partial

from kittens.tui.handler import result_handler
from kitty.clipboard import set_clipboard_string
from kitty.tabs import SpecialWindow
from kitty.utils import kitty_ansi_sanitizer_pat

from editor import editor_argv
from model import Block, CommandRun, Selection, Session, from_dict

# Kopfzeile eines Eintrags von Screen.dump_lines_with_attrs (kitty/screen.c):
#   "\x1b[31m{y}: \x1b[39m" + [kind] + ["continued "] + ["dirty "] + "\n" + text
DUMP_HDR = re.compile(r'\x1b\[31m(-?\d+): \x1b\[39m(.*)')
SANITIZE = kitty_ansi_sanitizer_pat()
# Line.as_ansi() schreibt die Prompt-Marke mit in den Text. Die Art der
# Zeile steht schon in Row.kind, im Text ist sie nur Rauschen -- und im
# Pager wuerde sie sichtbar. Hyperlinks (OSC 8) bleiben erhalten.
PROMPT_MARK = re.compile(r'\x1b\]133;[^\x1b\x07]*(?:\x1b\\|\x07)')
BUFFER_FILE = 'buffer'
DIM_FILE = 'buffer.dim'
# Jede SGR-Sequenz einer Zeile bekommt ein angehaengtes ';2' (faint) -- so
# ueberlebt das Dimmen jeden Farbwechsel und jeden Reset innerhalb der Zeile,
# denn nach JEDER Attributaenderung wird faint sofort wieder gesetzt. Wie
# stark kitty faint rendert, steuert die Option dim_opacity.
SGR = re.compile(r'\x1b\[([0-9;:]*)m')
# Vor jede Zeile, sonst laeuft eine nicht geschlossene Farbe in alle folgenden
# Zeilen weiter. Line.as_ansi() setzt SGR relativ zum Zeilenanfang und nimmt
# dabei den Default-Zustand an -- kittys eigenes as_text_generic macht deshalb
# genau dasselbe. Konkreter Ausloeser hier: PROMPT_EOL_MARK setzt %F ohne %f.
SGR_RESET = '\x1b[m'

@dataclass
class Row:
    """Eine physische Terminalzeile -- rein launch-intern, wandert nie
    ueber die Prozessgrenze (deshalb nicht in model.py)."""

    kind: str                         # '' | 'prompt' | 'secondary' | 'output'
    ansi: str                         # Zeilentext mit SGR, ohne Zeilenende
    wrapped: bool                     # Zeile laeuft in die naechste weiter


KIND_MARKERS = (
    ('\x1b[32msecondary_prompt ', 'secondary'),
    ('\x1b[32mprompt ', 'prompt'),
    ('\x1b[33moutput ', 'output'),
)


def plain(s: str) -> str:
    return SANITIZE.sub('', s)


def faint(line: str) -> str:
    """Dieselbe Zeile, durchgehend SGR-2-gedimmt.

    Ein leerer Parameter wird explizit zu 0: nach ECMA-48 sind \\x1b[m und
    \\x1b[0m gleichwertig, aber fzfs ANSI-Parser behandelt den leeren ersten
    Parameter in \\x1b[;2m nicht als Reset -- die vorige Farbe wuerde in die
    gedimmte Zeile durchbluten.
    """
    return '\x1b[2m' + SGR.sub(lambda m: f'\x1b[{m.group(1) or "0"};2m', line)


def line_kinds(screen) -> dict:
    """y -> Art der Zeile, fuer den gesamten Scrollback plus Bildschirm.

    prompt_kind steht in den Line-Attributen; Line exportiert das Feld nicht
    nach Python, dieser Debug-Dump ist der einzige Weg dorthin.

    Achtung beim Erweitern: das ebenfalls enthaltene 'continued' ist um eins
    verschoben und beschreibt y+1 (kitty inkrementiert y im Format-Aufruf,
    bevor es range_line_is_continued aufruft). Wer die Umbruchinfo braucht,
    nimmt Line.last_char_has_wrapped_flag().
    """
    acc = []
    screen.dump_lines_with_attrs(acc.append)
    kinds = {}
    for m in DUMP_HDR.finditer(''.join(acc)):
        flags = m.group(2)
        kinds[int(m.group(1))] = next(
            (name for marker, name in KIND_MARKERS if flags.startswith(marker)), '')
    return kinds


def detab(line, ansi_text: str) -> str:
    """Ersetzt Tabs durch exakt die Spalten, die sie im Grid einnehmen.

    as_ansi() gibt fuer einen Tab nur '\\t' aus. Wie viele Spalten er beim
    Schreiben belegte, steht im Grid: kitty speichert die Spannweite als
    zweites Zeichen im Zelltext der Tab-Zelle (screen_tab, kitty/screen.c).
    Renderer, die '\\t' per Tabstop expandieren, treffen das nur, solange
    die Spans zu den Stops passen -- nach einem Rewrap durch Resize nicht
    mehr. Sichtbar als verschobene ls-Spalten zwischen Vorschau und
    Terminal.

    Zusaetzlich verschluckt kittys Serialisierer eine Spalte, wenn dem
    Tab-Bereich direkt ein echtes Leerzeichen folgt: die Skip-Schleife in
    line_as_ansi ueberspringt bis zu span Leerzellen, der Tab deckt aber
    nur span-1 Spacer ab (ls trennt Spalten genau so: Tabs plus Spaces).
    Deshalb wird hier beides aus den Zellen rekonstruiert: span Spalten
    fuer den Tab, plus die gefressene, falls die Zelle dahinter ein
    Leerzeichen ist.
    """
    if '\t' not in ansi_text:
        return ansi_text
    widths = []
    for x in range(len(line)):
        cell = line[x]
        if cell.startswith('\t'):
            span = ord(cell[1]) if len(cell) > 1 else 1
            eaten = 1 if x + span < len(line) and line[x + span] == ' ' else 0
            widths.append(max(1, span + eaten))
    it = iter(widths)
    return re.sub('\t', lambda m: ' ' * next(it, 8), ansi_text)


def read_rows(screen) -> list:
    """Alle Zeilen als Row, aufsteigend nach y.

    Listenindex i entspricht der Koordinate y = i - historybuf.count, in
    der auch scrolled_by rechnet: die oberste sichtbare Zeile liegt bei
    y == -scrolled_by.
    """
    kinds = line_kinds(screen)
    hb = screen.historybuf
    rows = []
    for y in sorted(kinds):
        # historybuf waechst nach oben, Index 0 ist die juengste Zeile.
        # Beide line()-Aufrufe geben ein wiederverwendetes Line-Objekt
        # zurueck, der Text muss also sofort geholt werden.
        line = hb.line(-y - 1) if y < 0 else screen.line(y)
        rows.append(Row(kind=kinds[y],
                        ansi=PROMPT_MARK.sub('', detab(line, line.as_ansi())),
                        wrapped=line.last_char_has_wrapped_flag()))
    return rows


@dataclass
class _Group:
    """Zeilenbereich eines Blocks, vor dem Materialisieren."""

    start: int                    # Index in rows, die PROMPT_START-Zeile
    out_start: int | None = None  # Index in rows, die OUTPUT_START-Zeile
    end: int = 0                  # exklusiv

    def prompt_slice(self, rows: list) -> list:
        stop = self.out_start if self.out_start is not None else self.end
        part = rows[self.start:stop]
        while len(part) > 1 and not plain(part[-1].ansi).strip():
            part.pop()
        return part

    def output_slice(self, rows: list) -> list:
        if self.out_start is None:
            return []
        part = rows[self.out_start:self.end]
        # Shells fuellen vor dem Prompt eine Zeile mit Leerzeichen bis zum
        # Zeilenende auf, damit eine unvollstaendige letzte Ausgabezeile
        # sichtbar bleibt (zsh: PROMPT_SP, per Default an). Diese Zeile faellt
        # in die Ausgabe des Blocks, gehoert dort aber nicht hin.
        #
        # Erkennungsmerkmal ist rein strukturell und unabhaengig davon, was
        # die Shell in die Zeile schreibt: sie traegt das Umbruch-Flag, laeuft
        # also in die PROMPT_START-Zeile des naechsten Blocks weiter, UND sie
        # ist mit Leerzeichen aufgefuellt. Beides zusammen entsteht nur durch
        # dieses Auffuellen -- eine echt umbrochene Ausgabezeile hat weitere
        # Ausgabe als Fortsetzung, eine echte Zeile in voller Breite ist nicht
        # rechts mit Leerzeichen gepolstert.
        if part:
            text = plain(part[-1].ansi)
            if part[-1].wrapped and text != text.rstrip():
                part.pop()
        while part and not plain(part[-1].ansi).strip():
            part.pop()          # ein Kommando ohne Ausgabe laesst eine leere Zeile
        return part


def group_rows(rows: list) -> list:
    groups = []
    cur = None
    for i, row in enumerate(rows):
        if row.kind == 'prompt':
            cur = _Group(start=i)
            groups.append(cur)
        if cur is None:
            continue
        if row.kind == 'output' and cur.out_start is None:
            cur.out_start = i
        cur.end = i + 1
    return groups


def join_wrapped(part: list, ansi: bool = True) -> list:
    """Fuegt Zeilen zusammen, die das Terminal nur weich umbrochen hat.

    Eine Zeile mit gesetztem Umbruch-Flag laeuft in die naechste weiter --
    dort steht kein echter Zeilenumbruch, sondern nur das Ende der
    Terminalbreite. Wer das nicht rueckgaengig macht, friert die Breite ein,
    bei der die Ausgabe entstanden ist: eine bei 156 Spalten erzeugte
    man-Seite liegt nach dem Verkleinern auf 82 als 82+73 im Buffer und wird
    in jeder schmaleren Ansicht ein zweites Mal umbrochen -- mit
    Vier-Zeichen-Stummeln als Ergebnis.
    """
    prefix = SGR_RESET if ansi else ''
    out, cur = [], prefix
    for row in part:
        cur += row.ansi if ansi else plain(row.ansi)
        if not row.wrapped:
            out.append(cur)
            cur = prefix
    if cur != prefix:
        out.append(cur)
    return out


def logical_lines(part: list) -> list:
    """Wie join_wrapped, aber ohne Steuersequenzen -- fuer Textvergleiche."""
    return join_wrapped(part, ansi=False)


def squeeze(text: str) -> str:
    """Whitespace vereinheitlichen -- das Terminal expandiert Tabs zu Spalten."""
    return ' '.join(text.split())


def pair_runs(groups: list, rows: list, runs: list) -> dict:
    """Ordnet den Kommando-Log den Prompt-Gruppen zu, von neu nach alt.

    Zwei Signale stehen zur Verfuegung, keines allein reicht:

    OUTPUT_START. Ein OSC 133;C setzt die Marke und erzeugt den Log-Eintrag
    in einem Zug (kitty/screen.c, shell_prompt_marking, Zweig 'C'). Ist die
    Marke da, hat die Gruppe garantiert ein Kommando ausgefuehrt. Sie kann
    aber verlorengehen: ein Kommando ohne Ausgabe laesst den Cursor auf
    Spalte 0 stehen, das 133;A des naechsten Prompts landet in derselben
    Zeile und ueberschreibt sie. Fehlt die Marke, heisst das also nicht,
    dass kein Kommando lief.

    Der Kommandotext. Die letzte Prompt-Zeile endet auf das Kommando -- egal
    wie der Prompt davor aussieht. Der Vergleich normalisiert Whitespace,
    weil auf dem Schirm die vom Terminal expandierte Fassung steht: ein Tab
    im Kommando ist dort eine Folge von Leerzeichen. Verlassen kann man sich
    darauf trotzdem nicht, weil ZLE beim Neuzeichnen langer Zeilen anders
    umbrechen kann als eine schlichte Verkettung.

    Deshalb entscheidet die Struktur, wo sie etwas sagt, und der Text nur da,
    wo sie schweigt: Marke vorhanden -> zugeordnet. Marke fehlt -> nur wenn
    der Text es bestaetigt, sonst war es ein blankes Enter und nur die
    Gruppe rueckt weiter.
    """
    paired = {}
    ri = len(runs) - 1
    for gi in range(len(groups) - 1, -1, -1):
        if ri < 0:
            break
        lines = logical_lines(groups[gi].prompt_slice(rows))
        tail = squeeze((runs[ri]['cmdline'].splitlines() or [''])[-1])
        confirmed_by_text = bool(lines) and bool(tail) and squeeze(lines[-1]).endswith(tail)
        if groups[gi].out_start is not None or confirmed_by_text:
            paired[gi] = runs[ri]
            ri -= 1
    return paired


def block_at_or_above(blocks: list, row_index: int) -> int:
    """Neuester Block, dessen Prompt auf oder ueber row_index beginnt."""
    for i in range(len(blocks) - 1, -1, -1):
        if blocks[i].prompt_line - 1 <= row_index:
            return i
    return 0


def preselect(screen, rows: list, blocks: list, receipt) -> int:
    """Welcher Block beim Oeffnen vorgewaehlt ist -- der Kontext des Views.

    Gescrollt zeigt die oberste Zeile, was der Nutzer betrachtet: der Block,
    in dem sie liegt (deckt tiefe Spruenge und manuelles Scrollen). Bei
    scrolled_by == 0 ist das Bild mehrdeutig: der Auffuell-Sprung hinterlaesst
    absichtlich einen Zustand, der von einer natuerlichen Session nicht
    unterscheidbar ist. Dafuer gibt es die Quittung des letzten Sprungs
    (Fenster-Attribut cmdjump_viewed, k des Ziels von unten): passt sie zum
    Prompt in der obersten Zeile, war das ein Sprung -- sonst Normalzustand,
    und es gilt der neueste Block. Die Quittung kann nicht stillschweigend
    veralten: jede Aenderung der Prompt-Folge verschiebt k und laesst den
    Vergleich fehlschlagen; Enter loescht sie explizit.
    """
    top = screen.historybuf.count - screen.scrolled_by
    if screen.scrolled_by > 0:
        return block_at_or_above(blocks, top)
    if rows[top].kind == 'prompt' and receipt is not None:
        prompts = [i for i, r in enumerate(rows) if r.kind == 'prompt']
        k = len(prompts) - 1 - prompts.index(top)
        if k == receipt:
            return block_at_or_above(blocks, top)
    return len(blocks) - 1


def collect(window) -> Session | None:
    """Baut die Session und legt die Ausgaben im Spool ab."""
    rows = read_rows(window.screen)
    groups = group_rows(rows)
    if not groups:
        return None
    paired = pair_runs(groups, rows, list(getattr(window, 'cmdjump_runs', ())))

    spool = tempfile.mkdtemp(
        prefix='cmdjump-',
        dir=os.environ.get('XDG_RUNTIME_DIR') or tempfile.gettempdir())

    # Der Scrollback, Zeile fuer Zeile so wie er im Terminal steht -- bewusst
    # OHNE join_wrapped. Die Vorschau soll das Terminalbild zeigen, und die
    # Sprungziele funktionieren nur, wenn Vorschauzeile N gleich Rasterzeile N
    # ist. Pager und Zwischenablage bekommen weiter zusammengefuegte Zeilen.
    with open(os.path.join(spool, BUFFER_FILE), 'w') as f:
        f.write('\n'.join(SGR_RESET + r.ansi for r in rows))
        f.write('\n')
    # Zeilengleiche gedimmte Fassung. Die UI mischt daraus die Vorschau:
    # der selektierte Block kommt aus der normalen Datei, der Rest aus
    # dieser -- alles ausser dem gewaehlten Kommando verblasst.
    with open(os.path.join(spool, DIM_FILE), 'w') as f:
        f.write('\n'.join(faint(SGR_RESET + r.ansi) for r in rows))
        f.write('\n')
    blocks = []
    for gi, group in enumerate(groups):
        run = paired.get(gi)
        if run is None:
            # Kein zugeordnetes Kommando: Live-Prompt, blankes Enter, oder
            # aelter als der Watcher. Alles nichts, worauf man springen oder
            # was man kopieren wollte.
            continue
        out = group.output_slice(rows)
        prompt = group.prompt_slice(rows)
        # Kopf des Prompt-Blocks: alles bis zur ersten PS2-Zeile, also
        # PS1-Kontext plus erste Kommandozeile. Die PS2-Zeilen kommen als
        # SECONDARY_PROMPT aus den Line-Attributen (OSC 133;A;k=s); fehlen
        # die Marken, bleibt der Kopf eine Zeile und die UI kuerzt wie eh.
        first_ps2 = next((i for i, r in enumerate(prompt) if r.kind == 'secondary'), None)
        head = 1 if first_ps2 is None else max(1, len(join_wrapped(prompt[:first_ps2])))
        body = join_wrapped(out)
        name = f'{len(blocks)}.out'
        with open(os.path.join(spool, name), 'w') as f:
            f.write('\n'.join(body))
            f.write('\n')
        blocks.append(Block(
            index=gi,
            prompt_lines=join_wrapped(prompt),
            head_lines=head,
            n_output=len(body),
            output_file=name,
            prompt_line=group.start + 1,
            end_line=group.end,
            run=CommandRun(**run),
        ))
    if not blocks:
        shutil.rmtree(spool, ignore_errors=True)
        return None
    return Session(spool=spool, buffer=BUFFER_FILE, buffer_dim=DIM_FILE,
                   n_prompts=len(groups), blocks=blocks,
                   selected=preselect(window.screen, rows, blocks,
                                      getattr(window, 'cmdjump_viewed', None)))


def dispatch(session: Session, data: dict, target_window_id: int, boss) -> None:
    """Rueckweg aus der UI. Raeumt den Spool auf -- ausser der Editor
    laeuft noch, dann uebernimmt finish_edit das am Ende."""
    cleanup = True
    try:
        sel = from_dict(Selection, data)
        w = boss.window_id_map.get(target_window_id)
        if w is None or sel.action == 'none' or not 0 <= sel.block_index < len(session.blocks):
            return
        block = session.blocks[sel.block_index]
        if sel.action == 'edit':
            cleanup = not open_editor(boss, w, session, block)
            return
        if sel.action == 'paste':
            # Nur in den Hauptpuffer: waehrend das Menue offen war, kann im
            # Fenster ein Vollbildprogramm gestartet sein -- dann wuerde die
            # Kommandozeile dort hineingetippt statt in die Shell.
            if w.screen.is_main_linebuf():
                scroll_to_bottom(w)         # zur Kommandozeile, gleich wird getippt
                paste_command(w, block.run.cmdline)
                w.cmdjump_viewed = None     # zurueck zur Arbeit: Quittung weg
            return
        # Alles andere laesst die Ansicht dort stehen, wo die Vorschau sie
        # gezeigt hat: das Menue verschwindet, der Bereich darueber bleibt.
        jump_to(w, session, block)
        if sel.action == 'pager':
            show_in_pager(boss, w, session, block)
        elif sel.action == 'clipboard':
            set_clipboard_string(plain(read_output(session, block)))
    finally:
        if cleanup:
            shutil.rmtree(session.spool, ignore_errors=True)


def scroll_to_bottom(w) -> None:
    if w.screen.is_main_linebuf():
        w.finish_scroll_animation()
        w.screen.scroll_to_absolute(0.0)


def nth_prompt_from_bottom(screen, k: int) -> int | None:
    """y der k-ten PROMPT_START-Zeile von unten, None wenn es keine gibt."""
    ys = sorted(y for y, kind in line_kinds(screen).items() if kind == 'prompt')
    if not ys:
        return None
    return ys[-1 - min(k, len(ys) - 1)]


def jump_to(w, session: Session, block: Block) -> None:
    """Springt an den Prompt des Blocks, gezaehlt von unten.

    Die Aufloesung passiert hier und nicht in Stufe 1, damit zwischenzeitlich
    hinzugekommene Ausgabe das Ziel nicht verschiebt.
    """
    if not w.screen.is_main_linebuf():
        return
    k = session.n_prompts - 1 - block.index
    y = nth_prompt_from_bottom(w.screen, k)
    if y is None:
        return
    if y > 0:
        # Ziel liegt in der untersten Bildschirmhoehe: dorthin kann der
        # Viewport nicht scrollen, unter dem Inhalt gibt es nichts
        # (scrolled_by ist auf [0, historybuf.count] geklemmt). Also die
        # fehlenden Zeilen real machen: kittys eingebautes
        # scroll_until_cursor_prompt -- der Motor der scroll_prompt_to_top-
        # Aktion -- schiebt alles oberhalb des Live-Prompts per echten
        # Linefeeds in den Scrollback. True = History behalten.
        w.screen.scroll_until_cursor_prompt(True)
        y = nth_prompt_from_bottom(w.screen, k)   # Koordinaten sind verschoben
        if y is None:
            return
        # Dann das Zuviel zurueckholen, bis das Ziel in Bildschirmzeile 0
        # steht (dieselbe Mechanik wie kittys scroll_prompt_to_bottom:
        # reverse_scroll fuellt von oben aus dem Scrollback nach, der Cursor
        # wandert mit). Ergebnis: Ziel oben BEI scrolled_by == 0. Das ist
        # der Punkt fuer die visuelle Konstanz -- kitty springt bei
        # Tastendruck nur dann ans Ende, wenn scrolled_by != 0 (keys.c),
        # Tippen bewegt die Ansicht danach also gar nicht mehr. Und es
        # bleibt nur so viel Leere unten, wie das Ziel wirklich braucht;
        # die juengeren Kommandos stehen weiter ueber dem Live-Prompt.
        excess = -y
        if excess > 0:
            w.screen.reverse_scroll(excess, True)
            w.screen.cursor_down(excess)
        y = 0
    w.finish_scroll_animation()
    w.screen.scroll_to_absolute(float(max(0, -y)))
    w.screen.set_last_visited_prompt(0)
    # Quittung fuer das naechste Oeffnen: dieser Prompt ist jetzt der Kontext.
    w.cmdjump_viewed = k


def read_output(session: Session, block: Block) -> str:
    with open(os.path.join(session.spool, block.output_file)) as f:
        return f.read()


def show_in_pager(boss, w, session: Session, block: Block) -> None:
    body = read_output(session, block)
    head = '\n'.join(block.prompt_lines)
    # Der Titel kommt aus dem Kommando, nicht aus der Prompt-Zeile: bei
    # mehrzeiligen Kommandos traegt die letzte Prompt-Zeile nur deren Rest.
    title = ' '.join(block.run.cmdline.split())[:70]
    # input_line_number ersetzt kitty im Pager-Kommando; 1 heisst: oben
    # anfangen. Der Default 0 wuerde bei 'normal! 0G' ans Ende springen.
    boss.display_scrollback(w, f'{head}\n{body}', input_line_number=1,
                            title=title or 'Ausgabe', report_cursor=False)


EDIT_FILE = 'edit.zsh'
ACCEPT_FLAG = 'accepted'
def open_editor(boss, w, session: Session, block: Block) -> bool:
    """Tuer 1: Editor-Overlay fuer die selektierte historische Kommandozeile.

    True = Overlay laeuft, der Spool muss es ueberleben (finish_edit raeumt
    dann auf). Die Ansicht darunter bleibt unangetastet -- gesprungen wird
    erst beim Annehmen, und zwar ans Ende, wie beim Enter-Pfad.
    """
    tab = w.tabref()
    if tab is None:
        return False
    edit_path = os.path.join(session.spool, EDIT_FILE)
    with open(edit_path, 'w') as f:
        f.write(block.run.cmdline)
        if not block.run.cmdline.endswith('\n'):
            f.write('\n')
    ctx = os.path.join(session.spool, session.buffer)
    with open(ctx) as f:
        ctx_lines = sum(1 for _ in f)
    argv = editor_argv(ctx, block.prompt_line, edit_path,
                       os.path.join(session.spool, ACCEPT_FLAG), ctx_lines)
    win = tab.new_special_window(
        SpecialWindow(argv, override_title=f'edit: {squeeze(block.run.cmdline)[:50]}',
                      overlay_for=w.id, overlay_behind=True),
        copy_colors_from=w)
    win.actions_on_close.append(partial(finish_edit, boss, session, w.id))
    return True


def finish_edit(boss, session: Session, target_window_id: int, editor_window) -> None:
    """Schliessen des Editors: ok-Flag da -> uebernehmen, sonst Abbruch."""
    try:
        if not os.path.exists(os.path.join(session.spool, ACCEPT_FLAG)):
            return                        # :q!/:qa -- Ansicht bleibt, nichts passiert
        with open(os.path.join(session.spool, EDIT_FILE)) as f:
            cmdline = f.read().rstrip('\n')
        w = boss.window_id_map.get(target_window_id)
        if not cmdline or w is None or not w.screen.is_main_linebuf():
            return
        scroll_to_bottom(w)               # zur Kommandozeile, gleich wird gefeuert
        paste_command(w, cmdline)
        w.cmdjump_viewed = None
    finally:
        shutil.rmtree(session.spool, ignore_errors=True)


# Accept-Protokoll: hat die Shell den Empfaenger aus cmdjump.zsh geladen,
# meldet sie das als Fenster-Variable an (OSC 1337 SetUserVar). Der Paste
# traegt dann dieses Praefix, und der zsh-Wrapper ERSETZT die Kommandozeile
# statt anzuhaengen. Muss mit _CMDJUMP_MAGIC in cmdjump.zsh uebereinstimmen.
PASTE_MAGIC = '%%cmdjump-paste%%'


def paste_command(w, cmdline: str) -> None:
    """Legt das Kommando in die Kommandozeile, ohne es auszufuehren.

    Mit angemeldetem cmdjump.zsh-Empfaenger wird die Zeile ersetzt; sonst
    universeller Paste (anhaengen) -- fremde Shells und ssh ohne Dotfiles
    bekommen nie Protokoll-Bytes zu sehen.
    """
    if w.user_vars.get('cmdjump') and w.screen.in_bracketed_paste_mode:
        w.paste_text(PASTE_MAGIC + cmdline)
        return
    if not w.screen.in_bracketed_paste_mode:
        # Ohne Bracketed Paste macht paste_text aus \n ein \r -- ein
        # mehrzeiliges Kommando wuerde damit sofort losfahren.
        cmdline = cmdline.replace('\n', ' ')
    w.paste_text(cmdline)


def main(args: list) -> None:
    """Wird bei no_ui nie aufgerufen, muss aber existieren."""


@result_handler(no_ui=True)
def handle_result(args: list, answer, target_window_id: int, boss) -> None:
    w = boss.window_id_map.get(target_window_id)
    if w is None or not w.screen.is_main_linebuf():
        return
    session = collect(w)
    if session is None:
        return                            # nichts aufzuzaehlen -> Noop
    boss.run_kitten_with_metadata(
        'cmdjump/ui.py',
        input_data=json.dumps(asdict(session)),
        window=w,
        custom_callback=partial(dispatch, session),
        # sorgt dafuer, dass der Callback auch beim Abbruch laeuft und
        # den Spool aufraeumt
        default_data=asdict(Selection(action='none')),
    )
