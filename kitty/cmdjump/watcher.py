"""kitty-Watcher: fuehrt pro Fenster Buch ueber die ausgefuehrten Kommandos.

kitty ermittelt Startzeit, Dauer, Kommandozeile und Exit-Status ohnehin --
es braucht sie fuer notify_on_cmd_finish -- behaelt davon aber nur den
jeweils letzten Satz in Window.last_cmd_*. on_cmd_startstop ist der dafuer
vorgesehene Haken, um mehr davon aufzuheben.

Der Log haengt am Window-Objekt und stirbt mit ihm. Das ist Absicht: was
aus dem Scrollback gerollt ist, hat ohnehin keinen Block mehr, zu dem die
Metadaten gehoeren koennten.

Bewusst ohne Importe aus diesem Paket: der Callback laeuft bei jedem
Kommando auf kittys Main-Thread, also so wenig Angriffsflaeche wie moeglich.
Die Uebersetzung in CommandRun macht Stufe 1.

kitty.conf:  watcher cmdjump/watcher.py
"""

from collections import deque
from time import time

from kitty.utils import path_from_osc7_url

# ~90 Byte pro Eintrag. Mehr als der Scrollback fasst bringt nichts.
MAX_RUNS = 4000

ATTR = 'cmdjump_runs'


def _log(window):
    log = getattr(window, ATTR, None)
    if log is None:
        log = deque(maxlen=MAX_RUNS)
        setattr(window, ATTR, log)
    return log


def on_cmd_startstop(boss, window, data):
    """data: is_start, time (monotonic!), cmdline, exit_status."""
    log = _log(window)
    if data['is_start']:
        log.append({
            # data['time'] ist monotonic() und taugt nicht als Uhrzeit,
            # deshalb hier zusaetzlich die Wanduhr stempeln.
            'cmdline': data['cmdline'],
            # OSC 7, von der Shell bei jedem Prompt gemeldet. Zum Zeitpunkt
            # des Kommandostarts steht hier das Verzeichnis, in dem das
            # Kommando laeuft -- bei 'cd x' also noch das alte.
            'cwd': path_from_osc7_url(window.screen.last_reported_cwd or b''),
            'started_at': time(),
            'started_mono': data['time'],
            'duration': None,
            'exit_status': None,
        })
        return
    if log and log[-1]['duration'] is None:
        run = log[-1]
        run['duration'] = data['time'] - run['started_mono']
        run['exit_status'] = data['exit_status']


def on_close(boss, window, data):
    try:
        delattr(window, ATTR)
    except AttributeError:
        pass
