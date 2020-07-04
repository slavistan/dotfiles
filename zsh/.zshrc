## Zsh global options

setopt globdots         # tab-complete dotfiles
setopt menucomplete     # tab-expand to first option immediately
setopt autocd           # change dirs without 'cd'
setopt hist_ignore_dups # don't add duplicate cmd to hist
disable r               # Remove irritating alias


## Prompt setup

PS1='%F{138}%B[%l]%b%f %F{159}%B%n@%m%b%f %Bin%b %F{154}%B%(4~|%-1~/.../%2~|%~)%b%f
%B%(?.%F{green}.%F{red})➤%b%f '
PS2='%B➤ %b'


## Completion system init

# Load completion system and stuff the zcompdump file somewhere I don't see
# them. However.. the -d flag is bullshit and does not do what it's supposed to.
autoload -Uz compinit && compinit -d $XDG_CACHE_HOME/zsh/.zcompdump
autoload -Uz bashcompinit && bashcompinit -d $XDG_CACHE_HOME/zsh/.zbashcompdump
# zstyle ':completion:*' menu select # select completions from menu
zstyle ':completion:*' matcher-list \
  'M:{a-zA-Z}={a-zA-Z}' \
  'm:{a-zA-Z}={A-Za-z}' \
  'm:{a-zA-Z}={A-Za-z} l:|=*'
zstyle ':completion:*' accept-exact false

# TODO(fix): Check with marlonrichert/zsh-autocomplete #65
# TODO(fix): Show as many results as fit inside max-lines. Issue?
# source /home/stan/prj/dotfiles/zsh/plugins/zsh-autocomplete/zsh-autocomplete.plugin.zsh
# zstyle ':autocomplete:list-choices*' max-lines 60
# zstyle ':autocomplete:*' fuzzy-search off
# zstyle ':autocomplete:*' frecent-dirs off
# zstyle ':autocomplete:*' groups off
# add-zsh-hook precmd use-my-matcher-list
# use-my-matcher-list() {
#   zstyle ':completion:*' matcher-list \
#     'M:{a-zA-Z}={a-zA-Z}' \
#     'm:{a-zA-Z}={A-Za-z}' \
#     'm:{a-zA-Z}={A-Za-z} l:|=*'
# }

# Additional completion files
source $DOTFILES/zsh/completions/cf # Cloud-Foundry CLI
source $DOTFILES/zsh/completions/cds # @sap/cds-dk


## Key bindings

bindkey -v # Enable vi-mode
KEYTIMEOUT=1 # Remove timeout after <ESC>

# ⌫  ,^w, ^h may delete beyond start of current insert
bindkey -M viins '^?' backward-delete-char
bindkey -M viins '^H' backward-delete-char
bindkey -M viins '^w' backward-delete-word

# Unbind/rebind some defaults
# TODO(perf): Improve startup latency
for k in '^a' '^b' '^c' '^d' '^f' '^n' '^n' '^o' '^p' '^q' '^r' '^s' '^t' '^j' '^x' '^y' '^z' '^X~' \
  '^[,' '^[/' '^[OA' '^[OB' '^[OC' '^[OD' '^[[1~' '^[[2~' '^[[3~' '^[[4~' '^[[A' '^[[B' \
  '^[[C' '^[[D' '^[~'; do
  bindkey -M viins -r "$k"
done
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


## Proper cursor setup

zle -N zle-line-init vicursor # Change cursor according to vi-mode.
zle -N zle-keymap-select vicursor # Change cursor according to vi-mode.
function vicursor {
  case $KEYMAP in
    vicmd) printf "\033[0 q";;
    viins|main) printf "\033[5 q";;
  esac
  zle reset-prompt
}


## Display files when changing directories. Triggers automatically.

function chpwd {
  exa -T -a -L 1 -F --group-directories-first 2>/dev/null || ls -A
}


## Interactive shell aliases & functions

alias view='nvim -R'
alias gst='git status'

function mkcd {
  [ "$#" -eq 1 ] && mkdir -p "$1" && cd "$1" || echo "Nothing done."
}

function mkcdt {
  cd $(mktemp -d)
}

function gsap {
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git add -u
    git commit -am "stuff"
    git push
  else
    echo "This is not a git repository. Nothing done."
    return 1
  fi
}


## Load zsh-syntax-highlighting; should be last.

source $DOTFILES/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh


## Source machine-specific setup

[ -f $DOTFILES/zsh/.machinerc ] && source $DOTFILES/zsh/.machinerc
