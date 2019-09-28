# TODO: Make TAB complete the word until ambiguous and display the suggestions.
#       Currently this requires two TABs.
source ~/.profile

PROMPT="%F{default}%K{255}%K{255]}%F{16} 💻%n %#%F{255}%K{244}%K{244]}%F{255} %(4~|%-1~/.../%2~|%~) %F{244}%K{default}%f%k"
RPROMPT="%F{%(?.28.160)}%K{default}%K{%(?.28.160)]}%F{255}%B %? %b⏎ %F{255}%K{%(?.28.160)}%K{255]}%F{16} /dev/pts/4 🖳 %F{default}%K{255}%f%k"

setopt autocd # change dirs without 'cd'
setopt globdots # tab-complete dotfiles
setopt menucomplete # tab-expand to first option immediately
setopt markdirs # append / to globbed dirs

COMPLETION_WAITING_DOTS="true"
autoload -Uz +X compinit && compinit -d $ZSH_HOME/backup
autoload -Uz +X bashcompinit && bashcompinit -d $ZSH_HOME/backup # allow bash-comps

zstyle ':completion:*' menu select # select completions from menu
zstyle ':completion:*' matcher-list \
  'm:{a-zA-Z}={A-Za-z} l:|=* r:|=*' # case ins. & infix

export DOTFILES=$HOME'/projects/dotfiles'
export ZSH=$HOME'/.config/zsh/oh-my-zsh'
export ZSH_HOME=$HOME'/.config/zsh'
export ZSH_DISABLE_COMPFIX="true"
export ZSH_COMPDUMP=$ZSH_HOME/backup/.zsh_compdump
export HISTFILE=$ZSH_HOME/backup/.zsh_history

# Remove the useless whitespace at the rhs of the RPROMPT.
# TODO: This is bugged. Causes the cursor to be misplaced by 1 character.
# ZLE_RPROMPT_INDENT=0


plugins=(
  git wd colored-man-pages extract zsh-syntax-highlighting
)

# source $ZSH/oh-my-zsh.sh

# Source setup-specific configuration which shall not be committed to the repo.
[[ -r $ZSH_HOME/setup-specific.zsh ]] && source $ZSH_HOME/setup-specific.zsh

# TODO: Clean this up. Everything's crazy.
source $ZSH_HOME/envvars.zsh

# Source completion scripts
source $ZSH_HOME/completions/cf # Cloud-Foundry CLI

export EDITOR='nvim'
export LS_COLORS=$($ZSH_HOME/scripts/dircolors.zsh)
export TREE_COLORS=$($ZSH_HOME/scripts/dircolors.zsh)
export XDG_DATA_HOME=$HOME'/.local'

alias vim=nvim
alias t='tree -aL 1 --dirsfirst'
alias l='\ls --color=tty -Aog --si --time-style=long-iso --group-directories-first'

# Disable zsh built-in
disable r

# Load zsh-syntax-highlighting; should be last.
source $DOTFILES/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source $DOTFILES/zsh/plugins/fzf/shell/completion.zsh
