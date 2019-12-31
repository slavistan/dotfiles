# Prompt setup

PS1='%F{138}%B[%l]%b%f %F{159}%B%n@%m%b%f %Bin%b %F{154}%B%(4~|%-1~/.../%2~|%~)%b%f
%B%(?.%F{green}.%F{red})➤%b%f '
RPROMPT=''

autoload -U edit-command-line

# Load completion system and stuff the zcompdump file somewhere I don't see
# them. However.. the -d flag is bullshit and does not do what it's supposed to.
autoload -Uz compinit && compinit -d $XDG_CACHE_HOME/zsh/.zcompdump
autoload -Uz bashcompinit && bashcompinit -d $XDG_CACHE_HOME/zsh/.zbashcompdump

# Recreate familiar word boundaries
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

# Display files when changing directories
function chpwd() {
    emulate -L zsh
    exa -T -a -L 1 -F --group-directories-first
}

# Edit commmand-line in vim
zle -N edit-command-line
bindkey -M vicmd '^e' edit-command-line

# Enable vi-mode; Navigate completions menu via vim-keys
bindkey -v
KEYTIMEOUT=1
zstyle ':completion:*' menu select # select completions from menu
zmodload zsh/complist
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'l' vi-forward-char
bindkey -M menuselect 'j' vi-down-line-or-history

# <TAB> to accept a selection and expand immediately again
function my-accept-and-expand {
  zle accept-search
  zle expand-or-complete
}
zle -N my-accept-and-expand
bindkey -M menuselect '^I' my-accept-and-expand

# Misc keybindings
bindkey -r '^c'
bindkey '^?' backward-delete-char
bindkey '^h' backward-delete-char

# Options
setopt globdots # tab-complete dotfiles
setopt menucomplete # tab-expand to first option immediately
setopt autocd # change dirs without 'cd'
setopt hist_ignore_dups # don't add duplicate cmd to hist
disable r # Remove irritating alias

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
