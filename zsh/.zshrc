# Prompt setup

PS1='%F{138}%B[%l]%b%f %F{159}%B%n@%m%b%f %Bin%b %F{154}%B%(4~|%-1~/.../%2~|%~)%b%f
%B%(?.%F{green}.%F{red})➤%b%f '
RPROMPT=''

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

# Execute
function chpwd() {
    emulate -L zsh
    exa -T -L 1 -F --group-directories-first
}

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

# Load completion system and stuff the zcompdump file somewhere I don't see
# them. However.. the -d flag is bullshit and does not do what it's supposed to.
autoload -Uz compinit && compinit -d $XDG_CACHE_HOME/zsh/.zcompdump
autoload -Uz bashcompinit && bashcompinit -d $XDG_CACHE_HOME/zsh/.zbashcompdump

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

# Source machine-specific part
if [ -f $DOTFILES/zsh/.machinerc ]; then
  source $DOTFILES/zsh/.machinerc
fi
