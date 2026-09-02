# cmdjump: Accept-Protokoll fuer das kitty-Ctrl+R-Menue.
#
# kitty haengt uebernommene Kommandos normalerweise per Paste an die
# Kommandozeile an -- mehr erlaubt ein Terminal von aussen nicht. Dieser
# Empfaenger macht daraus ein ERSETZEN: kitty schickt einen Bracketed
# Paste mit Magic-Praefix, der Wrapper unten faengt ihn ab und tauscht
# $BUFFER atomar (keymap-unabhaengig, mehrzeilensicher). Jeder andere
# Paste laeuft unveraendert durch.
#
# Damit kitty das Protokoll nur benutzt, wo dieser Empfaenger existiert,
# meldet sich die Shell per Fenster-Variable an (OSC 1337 SetUserVar,
# von kitty offiziell geparst) und beim Beenden wieder ab. Ohne Anmeldung
# faellt kitty auf den universellen Paste zurueck -- eine fremde Shell
# bekommt nie Protokoll-Bytes zu sehen.
#
# Einbinden (interaktive zsh):  source .../kitty/cmdjump/cmdjump.zsh

[[ -o interactive && -n $KITTY_WINDOW_ID ]] || return 0

typeset -g _CMDJUMP_MAGIC='%%cmdjump-paste%%'
typeset -g _CMDJUMP_DIR=${0:A:h}

_cmdjump_bracketed_paste() {
    local content
    zle .bracketed-paste content
    if [[ $content == "$_CMDJUMP_MAGIC"* ]]; then
        BUFFER=${content#"$_CMDJUMP_MAGIC"}
        CURSOR=$#BUFFER
    else
        LBUFFER+=$content
    fi
}
zle -N bracketed-paste _cmdjump_bracketed_paste

# MQ== ist base64("1"); SetUserVar ohne Wert loescht die Variable.
_cmdjump_announce() { printf '\033]1337;SetUserVar=cmdjump=MQ==\007'; }
_cmdjump_retract()  { printf '\033]1337;SetUserVar=cmdjump\007'; }

autoload -Uz add-zsh-hook
add-zsh-hook zshexit _cmdjump_retract
_cmdjump_announce

# Tuer 2: ^E bekommt in kitty den Kontext-Editor -- gleicher Kern wie
# Ctrl-E im Ctrl+R-Menue. Der Wrapper-Name enthaelt 'vim', damit
# edit-command-line seinen vim-Zweig nimmt und die Cursorposition als
# Byteoffset anhaengt. Das eigene Widget exportiert zusaetzlich den
# zle-Modus (viins -> Insert, vicmd -> Normal). Ausserhalb von kitty
# greift dieses Skript nicht (Guard oben), dann bleibt $EDITOR wie gehabt.
autoload -Uz edit-command-line
zle -N edit-command-line
# Beide Kontexte: edit-command-line schaut unter :zle:$WIDGET nach, und
# WIDGET bleibt beim Aufruf aus unserem Wrapper-Widget 'cmdjump-edit'.
zstyle ':zle:edit-command-line' editor "$_CMDJUMP_DIR/edit-cmdline-nvim"
zstyle ':zle:cmdjump-edit'      editor "$_CMDJUMP_DIR/edit-cmdline-nvim"

_cmdjump_edit() {
    local -x CMDJUMP_KEYMAP=$KEYMAP
    zle edit-command-line
}
zle -N cmdjump-edit _cmdjump_edit
bindkey -M viins '^e' cmdjump-edit
bindkey -M vicmd '^e' cmdjump-edit
