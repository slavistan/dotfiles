"""Der gemeinsame Editor-Kern -- bewusst OHNE kitty-Importe.

Wird von zwei Tueren benutzt: launch.py (fzf-Tuer, laeuft im
kitty-Prozess) und edit-cmdline (zsh-Tuer, laeuft als gewoehnliches
Vordergrundprogramm aus edit-command-line heraus). Deshalb darf hier
nichts stehen, was kitty-Module braucht.
"""

# DCS, mit dem ein verstecktes Overlay (overlay_behind) sich sichtbar
# meldet -- kitty/vt-parser.c: dispatch('overlay-ready|').
READY_DCS = '\x1bP@kitty-overlay-ready|\x1b\\'


def editor_argv(context_path: str, anchor_line: int, edit_path: str, ok_path: str,
                context_lines: int) -> list:
    """Der gemeinsame Editor-Kern: nvim, oben Kontext, unten die Kommandozeile.

    Oben ein Terminal-Buffer mit dem Scrollback-Bild (Farben, r/o, volle
    nvim-Navigation zum Vergleichen und Yanken), geankert auf anchor_line --
    dieselbe Optik wie die fzf-Vorschau. Unten der Edit-Buffer. Kontrakt:
    Schreiben heisst Annehmen (:w/:x legt das ok-Flag ab und beendet),
    Beenden ohne Schreiben heisst Abbruch.

    Bewusst eine eigenstaendige, kontextfreie Funktion: die spaetere
    zsh-Tuer (edit-command-line per zstyle) soll denselben Kern ansteuern.
    Hinweis fuers Erweitern: vim akzeptiert maximal 10 -c-Argumente, deshalb
    sind die Schritte mit | gebuendelt; nach :autocmd und :normal darf in
    derselben -c nichts mehr folgen, beide schlucken den Rest der Zeile.
    """
    return [
        'nvim', edit_path,
        # --cmd laeuft VOR dem Laden der Datei: eine Kommandozeile mit
        # 'vim:'-Modeline im Text darf keine Optionen setzen.
        '--cmd', 'set nomodeline',
        '-c', ('setlocal filetype=zsh | autocmd BufWritePost <buffer> '
               f'call writefile([], "{ok_path}") | silent! qa!'),
        # 'cat datei -': nach der Datei liest cat stdin und bleibt am Leben --
        # nvim druckt so keine '[Process exited]'-Zeile in den Kontext.
        # qa! beim Beenden raeumt den Job ab.
        # Gutter global aus, BEVOR :terminal die Breite einfriert: 'number'
        # ist fensterlokal, aber buffergebunden -- :terminal wechselt den
        # Buffer und stellt sonst den Globalwert der User-Config wieder her,
        # der Terminal-Buffer wuerde ~4 Spalten schmaler und volle
        # Rasterzeilen (man-Header!) braechen um. Die Originalwerte werden
        # gemerkt und unten im Edit-Fenster lokal restauriert.
        '-c', (f'let g:cmdjump_opts = [&number, &relativenumber, &signcolumn] | '
               f'set scrollback=100000 nonumber norelativenumber signcolumn=no | '
               f'aboveleft split | terminal cat {context_path} -'),
        # Auf das RENDERN warten statt auf das Job-Ende (der Job endet ja
        # absichtlich nicht): wait() pollt, bis alle Zeilen im Buffer sind.
        # 70/30-Split; scrolloff lokal aus, sonst laesst die User-Config
        # (scrolloff=3) das zt nicht bis ganz nach oben.
        '-c', (f'call wait(3000, {{-> line("$") >= {context_lines}}}) | '
               f'execute "resize " . float2nr(&lines * 0.7) | '
               f'setlocal scrolloff=0 | '
               f'call cursor({anchor_line}, 1) | execute "normal! zt" | wincmd p | '
               f'let &l:number = g:cmdjump_opts[0] | '
               f'let &l:relativenumber = g:cmdjump_opts[1] | '
               f'let &l:signcolumn = g:cmdjump_opts[2]'),
        # Das Edit-Fenster IST die Session: wird es geschlossen (:q, :q!,
        # <C-w>c, ZZ ohne Aenderung), endet nvim komplett -- ohne Flag also
        # als Abbruch. WinClosed (mit expliziter Fenster-ID, aktuelles
        # Fenster ist nach wincmd p das Edit-Fenster) statt QuitPre oder
        # BufWinLeave: es feuert NACH dem Schliessen -- ein qa! mitten im
        # laufenden :close waere unzulaessig und bliebe wirkungslos.
        '-c', 'execute "autocmd WinClosed " . win_getid() . " silent! qa!"',
        # Overlay startet versteckt (overlay_behind); erst wenn alles steht,
        # nach vorn -- derselbe Anti-Flacker-Mechanismus wie beim fzf-Menue.
        # chansend(v:stderr, ...): nvims stderr ist das Terminal; /dev/tty
        # ist aus nvim heraus NICHT beschreibbar (E482 -- der Core haengt
        # nicht am Terminal, Jobs auch nicht). Die Bytes kommen unveraendert
        # aus READY_DCS, ohne Escape-Kaskade durch Python, vim und Shell.
        '-c', "call chansend(v:stderr, '" + READY_DCS + "')",
    ]
