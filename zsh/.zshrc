## Zsh global options

setopt globdots             # tab-complete dotfiles
setopt menucomplete         # tab-expand to first option immediately
setopt autocd               # change dirs without 'cd'
setopt no_unset             # throw error when using undefined vars
setopt hist_ignore_dups     # don't add duplicate cmd to hist
setopt no_autoremoveslash   # keep trailing slash after dir completion
setopt interactivecomments  # enable comments in shell commands
ZLE_REMOVE_SUFFIX_CHARS=    # keep trailing space after completion
disable r                   # remove irritating alias
zle_highlight+=(paste:none) # Don't highlight pasted text

WORDCHARS=${WORDCHARS/\/}

## Prompt setup

# xterm 8-bit color codes
grey85=253
dark_olive_green3=149
hot_pink3=132
light_goldenrod3=179
light_salmon3=173
steel_blue=67
pale_turquoise=159
rosy_brown=138
indian_red1=203
medium_purple2=140

# TODO(fix): Unfuck path expansion. 'prj' is abbrev'd to '...'.
PS1="%F{$rosy_brown}%B[%l]%f %F{$pale_turquoise}%n@%m %F{$grey85}in %F{$dark_olive_green3}%(4~|%-1~/.../%2~|%~)%b%f
%(?.%F{$dark_olive_green3}.%F{$indian_red1})➤ %f%b"
PS2="%(?.%F{$dark_olive_green3}.%F{$indian_red1})➤ %f%b"

# EOL indicator
setopt PROMPT_CR
setopt PROMPT_SP
export PROMPT_EOL_MARK="%F{$light_goldenrod3}⤬%k"


# direnv plugin
# -------------

# . /home/stan/prj/dotfiles/zsh/plugins/zsh-autoenv/autoenv.zsh
# ". scripts/testSetup.sh && node --inspect-brk node_modules/.bin/jest --testTimeout=36000000 --runInBand",



## Completion system init

# Load completion system and stuff the zcompdump file somewhere I don't see
# them. However.. the -d flag is bullshit and does not do what it's supposed to.
autoload -Uz compinit && compinit -d $XDG_CACHE_HOME/zsh/.zcompdump
autoload -Uz bashcompinit && bashcompinit -d $XDG_CACHE_HOME/zsh/.zbashcompdump
# zstyle ':completion:*' menu select # select completions from menu
zstyle ':completion:*:complete:*' matcher-list \
	'M:{a-zA-Z}={a-zA-Z}' \
	'm:{a-zA-Z}={A-Za-z}' \
	'm:{a-zA-Z}={A-Za-z} l:|=*'
zstyle ':completion:*' accept-exact false

# Load additional completion files
# NOTE: (.N) sets the NULL_GLOB options for a single glob.
for file in $DOTFILES/zsh/completions/*.zshcomp(.N); do
	source $file
done


## Key bindings

bindkey -v # Enable vi-mode
KEYTIMEOUT=1 # Remove timeout after <ESC>

# ⌫  ,^w, ^h may delete beyond start of current insert
bindkey -M viins '^?' backward-delete-char
bindkey -M viins '^H' backward-delete-char
bindkey -M viins '^w' backward-delete-word

bindkey -M viins '^ ' list-choices
bindkey -M viins '^p' up-history
bindkey -M viins '^n' down-history

# Edit line-buffer in vim
autoload -U edit-command-line && zle -N edit-command-line
bindkey -M vicmd '^e' edit-command-line # Edit line-buffer in vim
bindkey -M viins '^e' edit-command-line # Edit line-buffer in vim

# vi-keys selection menu navigation
zmodload zsh/complist
bindkey -M menuselect 'h' vi-backward-char # Menu navigation using vi-keys
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'l' vi-forward-char
bindkey -M menuselect 'j' vi-down-line-or-history

# swallow opened window
bindkey -M vicmd '^X^m' accept-line-swallow # if you're using vim bindings in zsh
bindkey -M viins '^X^m' accept-line-swallow # if you're using vim bindings in zsh
bindkey '^X^m' accept-line-swallow
zle -N accept-line-swallow acceptandswallow
acceptandswallow() {
	dwmswallow $WINDOWID
	zle accept-line
}

# FIXME: ^l coincides with clear
# bind lf to hotkey ^l
# bindkey -M vicmd "^l" zsh-lf # if you're using vim bindings in zsh
# bindkey -M viins "^l" zsh-lf # if you're using vim bindings in zsh
# zle -N zsh-lf _zshlf
# _zshlf() {
# 	BUFFER=lf
# 	zle end-of-line
# 	zle accept-line
# }

## Proper cursor setup

zle -N zle-line-init vicursor # Change cursor according to vi-mode.
zle -N zle-keymap-select vicursor # Change cursor according to vi-mode.
vicursor() {
	case $KEYMAP in
		vicmd) printf "\033[0 q";;
		viins|main) printf "\033[5 q";;
	esac
	zle reset-prompt
}

# environment for java to play nice with non-reparenting window managers
javaenv() {
	export _JAVA_OPTIONS='-Dswing.defaultlaf=com.sun.java.swing.plaf.gtk.GTKLookAndFeel -Dawt.useSystemAAFontSettings=gasp' 
	export _JAVA_AWT_WM_NONREPARENTING=1
}

## Interactive shell aliases & functions

alias view='nvim -R'
alias gst='git status'

mkcd() {
	[ "$#" -eq 1 ] && mkdir -p "$1" && cd "$1" || echo "Nothing done."
}

mkcdt() {
  cd $(mktemp -d)
}

gsap() {
	git add -u &&
		git commit --allow-empty-message -m "" &&
		git push
}


if [[ -f "$XDG_CONFIG_HOME/lfbundle/lfbundle.zshrc" ]]; then
	source "$XDG_CONFIG_HOME/lfbundle/lfbundle.zshrc"
fi


if [[ ${USERSVDIR+x} ]]; then
	alias sv="SVDIR='$USERSVDIR' sv" # shell alias; 'sudo sv' will use system dir
fi


# Syntax Highlighting
# ===================

source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main)

ZSH_HIGHLIGHT_STYLES[default]=fg=$grey85,bold
ZSH_HIGHLIGHT_STYLES[path]=fg=$grey85,bold

# Shell built-ins and keywords
ZSH_HIGHLIGHT_STYLES[builtin]=fg=$light_goldenrod3,bold # e.g. echo, printf
ZSH_HIGHLIGHT_STYLES[reserved-word]=fg=$light_goldenrod3,bold # e.g. while, for
ZSH_HIGHLIGHT_STYLES[precommand]=fg=$light_goldenrod3,bold # e.g. command, builtin
ZSH_HIGHLIGHT_STYLES[command]=fg=$dark_olive_green3,bold # regular binaries
ZSH_HIGHLIGHT_STYLES[arg0]=fg=$dark_olive_green3,bold # ???

ZSH_HIGHLIGHT_STYLES[comment]=fg=243,bold
ZSH_HIGHLIGHT_STYLES[unknown-token]=fg=203,bold
ZSH_HIGHLIGHT_STYLES[globbing]=fg=$steel_blue,bold # e.g. path globs ~/foo/*
ZSH_HIGHLIGHT_STYLES[commandseparator]=fg=$pale_turquoise,bold # ; && |

# Strings
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]=fg=$grey85,bold
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]=fg=$grey85,bold
ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument]=fg=$grey85,bold
ZSH_HIGHLIGHT_STYLES[dollar-double-quoted-argument]=fg=$grey85,bold
ZSH_HIGHLIGHT_STYLES[single-quoted-argument-unclosed]=fg=$grey85
ZSH_HIGHLIGHT_STYLES[double-quoted-argument-unclosed]=fg=$grey85
ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument-unclosed]=fg=$grey85
ZSH_HIGHLIGHT_STYLES[dollar-double-quoted-argument-unclosed]=fg=$light_goldenrod3
ZSH_HIGHLIGHT_STYLES[back-double-quoted-argument]=fg=$light_salmon3
ZSH_HIGHLIGHT_STYLES[back-dollar-quoted-argument]=fg=$light_salmon3

ZSH_HIGHLIGHT_STYLES[single-hyphen-option]=fg=$light_goldenrod3,bold
ZSH_HIGHLIGHT_STYLES[double-hyphen-option]=fg=$light_goldenrod3,bold

ZSH_HIGHLIGHT_STYLES[command-substitution-delimiter]=fg=$medium_purple2,bold
ZSH_HIGHLIGHT_STYLES[command-substitution-delimiter-unquoted]=fg=$medium_purple2,bold
ZSH_HIGHLIGHT_STYLES[process-substitution-delimiter]=fg=$medium_purple2,bold

# TODO: Speedup zsh startup. Can some functions be moved to a once-per-session file?
source ${XDG_CONFIG_HOME}/lfbundle/lfbundle.zshrc

# Initialize conda on demand only. Delete any conda.sh in /etc/profile.d/.
conda() {
	unset -f conda
	. /opt/miniconda3/etc/profile.d/conda.sh
	conda $@
}

start.sh() {
	~/prj/js-wp07-local-module/bundle/linux-x64/start.sh --nocd "$@"
}
