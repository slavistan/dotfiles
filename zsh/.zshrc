PS1="%F{default}%K{255}%K{255}%F{black}💻%n %#%F{255}%K{244}%K{244]}%F{255} %(4~|%-1~/.../%2~|%~) %F{244}%K{default}%f%k"
RPROMPT="%F{%(?.28.160)}%K{default}%K{%(?.28.160)]}%F{255}%B %? %b⏎ %F{255}%K{%(?.28.160)}%K{255]}%F{16} /dev/pts/4 🖳 %F{default}%K{255}%f%k"

# Bound words by '/'
default-backward-delete-word () {
  local WORDCHARS='*?_[]~=&;!#$%^(){}<>'
  zle backward-delete-word
}
zle -N default-backward-delete-word
bindkey '^W' default-backward-delete-word

# Change cursor when switching modes
function zle-line-init zle-keymap-select {
  case $KEYMAP in
    vicmd) printf "\033[0 q";;
    viins|main) printf "\033[5 q";;
  esac
  zle reset-prompt
}
zle -N zle-line-init
zle -N zle-keymap-select

# vi-mode
# TODO: Create keybinding to vifm
bindkey -v
bindkey -r '^c'
bindkey '^[OP' where-is
bindkey '^[OQ' beginning-of-line
bindkey '^?' backward-delete-char
bindkey '^h' backward-delete-char
bindkey '^a' beginning-of-line
bindkey '^e' end-of-line
KEYTIMEOUT=1

# Misc
disable r
setopt autocd # change dirs without 'cd'

# Completion
setopt globdots # tab-complete dotfiles
setopt menucomplete # tab-expand to first option immediately
autoload -U compinit && compinit -d $XDG_CACHE_HOME/zsh
autoload -U bashcompinit && bashcompinit -d $XDG_CACHE_HOME/zsh
zstyle ':completion:*' menu select # select completions from menu
zstyle ':completion:*' matcher-list \
  'm:{a-zA-Z}={A-Za-z} l:|=* r:|=*' # case ins. & infix
source $DOTFILES/zsh/completions/cf # Cloud-Foundry CLI

ZLE_RPROMPT_INDENT="-1" # removes rprompt's indent (use -1, not 0)

# Aliases

alias view='nvim -R'
alias vim=nvim
alias gst='git status'
mkcd () {
  if [ "$#" -eq 1 ]; then 
    mkdir -p "$@" && cd "$@"
  else
    echo "Requires exactly one argument. Nothing done" 1>&2
    return 1
  fi
}

# Load zsh-syntax-highlighting; should be last.
source $DOTFILES/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
