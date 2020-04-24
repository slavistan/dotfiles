# Zsh global options

setopt globdots         # tab-complete dotfiles
setopt menucomplete     # tab-expand to first option immediately
setopt autocd           # change dirs without 'cd'
setopt hist_ignore_dups # don't add duplicate cmd to hist
disable r               # Remove irritating alias


# Prompt setup

PS1='%F{138}%B[%l]%b%f %F{159}%B%n@%m%b%f %Bin%b %F{154}%B%(4~|%-1~/.../%2~|%~)%b%f
%B%(?.%F{green}.%F{red})➤%b%f '
RPROMPT=''


# Completion system init

# Load completion system and stuff the zcompdump file somewhere I don't see
# them. However.. the -d flag is bullshit and does not do what it's supposed to.
autoload -Uz compinit && compinit -d $XDG_CACHE_HOME/zsh/.zcompdump
autoload -Uz bashcompinit && bashcompinit -d $XDG_CACHE_HOME/zsh/.zbashcompdump
zstyle ':completion:*' menu select # select completions from menu
zstyle ':completion:*' matcher-list \
  'm:{a-zA-Z}={A-Za-z} l:|=* r:|=*' # case ins. & infix


# vi-mode line edit

bindkey -v # Enable vi-mode
KEYTIMEOUT=1 # Remove timeout after <ESC>
bindkey -M viins '^?' backward-delete-char # Backspace, ^W and ^H may delete ...
bindkey -M viins '^H' backward-delete-char # ... beyond start of current insert
bindkey -M viins '^w' backward-delete-word


# Change cursor when switching between insert and normal mode

zle -N zle-line-init vicursor # Change cursor according to vi-mode.
zle -N zle-keymap-select vicursor # Change cursor according to vi-mode.
function vicursor {
  case $KEYMAP in
    vicmd) printf "\033[0 q";;
    viins|main) printf "\033[5 q";;
  esac
  zle reset-prompt
}


# Display files when changing directories. Triggers automatically.

function chpwd() {
  exa -T -a -L 1 -F --group-directories-first 2>/dev/null || ls
}


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


# Source completion files

source $DOTFILES/zsh/completions/cf # Cloud-Foundry CLI
source $DOTFILES/zsh/completions/npm.plugin.zsh # npm


# Interactive shell aliases & functions

alias view='nvim -R'
alias vim=nvim
alias gst='git status'

function mkcd () {
  [ "$#" -eq 1 ] && mkdir -p "$1" && cd "$1" || echo "Nothing done."
}

function gsap () {
  if [ "$(git rev-parse --is-inside-work-tree 2>&1)" = "true" ]; then
    git add -u
    git commit -am "stuff"
    git push
  else
    echo "This is not a git repository. Nothing done."
    return 1
  fi
}


# Load zsh-syntax-highlighting; should be last.

source $DOTFILES/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh


# Source machine-specific part

[ -f $DOTFILES/zsh/.machinerc ] && source $DOTFILES/zsh/.machinerc
