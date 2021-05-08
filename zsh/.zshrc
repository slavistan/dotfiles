## Zsh global options

setopt globdots             # tab-complete dotfiles
setopt menucomplete         # tab-expand to first option immediately
setopt autocd               # change dirs without 'cd'
setopt hist_ignore_dups     # don't add duplicate cmd to hist
setopt no_autoremoveslash   # keep trailing slash after dir completion
ZLE_REMOVE_SUFFIX_CHARS=    # keep trailing space after completion
disable r                   # remove irritating alias
zle_highlight+=(paste:none) # Don't highlight pasted text

## Prompt setup

# TODO(fix): Unfuck path expansion. 'prj' is abbrev'd to '...'.
PS1='%F{138}%B[%l]%b%f %F{159}%B%n@%m%b%f %Bin%b %F{154}%B%(4~|%-1~/.../%2~|%~)%b%f
%B%(?.%F{green}.%F{red})➤%b%f '
PS2='%B➤ %b'

# EOL indicator
setopt PROMPT_CR
setopt PROMPT_SP
export PROMPT_EOL_MARK='%F{black}%K{white}❱❱%k'


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

# Additional completion files
# TODO: Iterate over existing files. Don't hardcode.
source $DOTFILES/zsh/completions/cf # Cloud-Foundry CLI
#source $DOTFILES/zsh/completions/cds # @sap/cds-dk


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

# lf alias for ueberzug and dir change
source "${XDG_CONFIG_HOME:-$HOME/.config}/lf-shellcd/lf-shellcd"

## Interactive shell aliases & functions

alias view='nvim -R'
alias gst='git status'

# TODO: Completion of commands
mango() {
	go doc "$@" | less
}

mkcd() {
	[ "$#" -eq 1 ] && mkdir -p "$1" && cd "$1" || echo "Nothing done."
}

mkcdt() {
  cd $(mktemp -d)
}

gsap() {
	if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
		git add -u
		git commit -am "stuff"
		git push
	else
		echo "This is not a git repository. Nothing done."
		return 1
	fi
}


## Plugins

for plug in \
	"$DOTFILES/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
	do
	[ -f "$plug" ] && source "$plug"
done

# TODO: Speedup zsh startup. Can some functions be moved to a once-per-session file?
