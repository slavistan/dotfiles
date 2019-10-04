PS1="%F{default}%K{255}%K{255}%F{black}💻%n %#%F{255}%K{244}%K{244]}%F{255} %(4~|%-1~/.../%2~|%~) %F{244}%K{default}%f%k"
RPROMPT="%F{%(?.28.160)}%K{default}%K{%(?.28.160)]}%F{255}%B %? %b⏎ %F{255}%K{%(?.28.160)}%K{255]}%F{16} /dev/pts/4 🖳 %F{default}%K{255}%f%k"

# vi-mode
bindkey -v
bindkey -r '^c'
bindkey '^[OP' where-is
bindkey '^[OQ' beginning-of-line
bindkey '^?' backward-delete-char
bindkey '^h' backward-delete-char
bindkey '^w' backward-kill-word
bindkey '^a' beginning-of-line
bindkey '^e' end-of-line
function zle-line-init zle-keymap-select {
  case $KEYMAP in
    vicmd) printf "\033[0 q";;
    viins|main) printf "\033[5 q";;
  esac
  zle reset-prompt
}
zle -N zle-line-init
zle -N zle-keymap-select
KEYTIMEOUT=1

# Misc
disable r
setopt autocd # change dirs without 'cd'

# Completion
setopt globdots # tab-complete dotfiles
setopt menucomplete # tab-expand to first option immediately
autoload -U compinit && compinit -D # -D prevents dumpfile
autoload -U bashcompinit && bashcompinit
zstyle ':completion:*' menu select # select completions from menu
zstyle ':completion:*' matcher-list \
  'm:{a-zA-Z}={A-Za-z} l:|=* r:|=*' # case ins. & infix
source $DOTFILES/zsh/completions/cf # Cloud-Foundry CLI

ZLE_RPROMPT_INDENT="-1" # removes rprompt's indent (use -1, not 0)

alias view='nvim -R'
alias vim=nvim
alias gst='git status'

# Load zsh-syntax-highlighting; should be last.
source $DOTFILES/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
