INSPS1="%F{default}%K{255}%K{255}%F{magenta}%Bi%b %F{black}💻%n %#%F{255}%K{244}%K{244]}%F{255} %(4~|%-1~/.../%2~|%~) %F{244}%K{default}%f%k"
NORPS1="%F{default}%K{255}%K{255}%F{magenta}%Bn%b %F{black}💻%n %#%F{255}%K{244}%K{244]}%F{255} %(4~|%-1~/.../%2~|%~) %F{244}%K{default}%f%k"
RPROMPT="%F{%(?.28.160)}%K{default}%K{%(?.28.160)]}%F{255}%B %? %b⏎ %F{255}%K{%(?.28.160)}%K{255]}%F{16} /dev/pts/4 🖳 %F{default}%K{255}%f%k"

# Widgets: https://sgeb.io/posts/2014/04/zsh-zle-custom-widgets/
function _widgy() {
  zle kill-whole-line
  zle -U "git status"
  zle accept-line
}
zle -N _widgy
# vi-mode
bindkey -v
bindkey -r '^c'
bindkey '^[OP' where-is
bindkey '^[OQ' beginning-of-line
bindkey '^?' backward-delete-char
bindkey '^h' backward-delete-char
bindkey '^w' backward-kill-word
bindkey '^a' beginning-of-line
bindkey '^q' _widgy
bindkey '^e' end-of-line
function zle-line-init zle-keymap-select {
  case $KEYMAP in
    vicmd) printf "\033[0 q"; PS1=$NORPS1;;
    viins|main) printf "\033[5 q"; PS1=$INSPS1;;
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

# Remove the useless whitespace at the rhs of the RPROMPT.
# TODO: This is bugged. Causes the cursor to be misplaced by 1 character.
# ZLE_RPROMPT_INDENT=0

alias view='nvim -R'
alias vim=nvim
alias gst='git status'

# Load zsh-syntax-highlighting; should be last.
source $DOTFILES/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
