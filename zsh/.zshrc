source ~/.profile

# TODO: Make TAB complete the word until ambiguous and display the suggestions.
#       Currently this requires two TABs.
setopt globdots # tab-complete dotfiles

# Path to your oh-my-zsh installation.
export DOTFILES=$HOME'/projects/dotfiles'
export ZSH=$HOME'/.config/zsh/oh-my-zsh'
export ZSH_HOME=$HOME'/.config/zsh'
export ZSH_DISABLE_COMPFIX="true"
export ZSH_COMPDUMP=$ZSH_HOME/backup/.zsh_compdump
export HISTFILE=$ZSH_HOME/backup/.zsh_history
ZSH_THEME="milton/milton"
COMPLETION_WAITING_DOTS="true"

# Configure the completion system. Allow bash completion scripts to be used.
# Check out 'man zshbuiltins' for details.
autoload -Uz +X compinit && compinit -d $ZSH_HOME/backup
autoload -Uz +X bashcompinit && bashcompinit -d $ZSH_HOME/backup

plugins=(
  git wd colored-man-pages extract zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

# Source setup-specific configuration which shall not be committed to the repo.
[[ -r $ZSH_HOME/setup-specific.zsh ]] && source $ZSH_HOME/setup-specific.zsh

# TODO: Clean this up. Everything's crazy.
source $ZSH_HOME/envvars.zsh

# Source completion scripts
source $ZSH_HOME/completions/cf # Cloud-Foundry CLI

export EDITOR='nvim'
export LS_COLORS=$($ZSH_HOME/scripts/dircolors.zsh)
export TREE_COLORS=$($ZSH_HOME/scripts/dircolors.zsh)

alias vim=nvim
alias t='tree -aL 1 --dirsfirst'
alias l='\ls --color=tty -Aog --si --time-style=long-iso --group-directories-first'


# TODO: What the fuck is this?
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
