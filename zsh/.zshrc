source ~/.profile

# Path to your oh-my-zsh installation.
export ZSH=$HOME'/.config/zsh/oh-my-zsh'
export ZSH_HOME=$HOME'/.config/zsh'
export ZSH_DISABLE_COMPFIX="true"
export ZSH_COMPDUMP=$ZSH_HOME/backup
export HISTFILE=$ZSH_HOME/backup
ZSH_THEME="powerlevel10k/powerlevel10k"
COMPLETION_WAITING_DOTS="true"

autoload -Uz compinit
compinit -d $ZSH_HOME/backup

plugins=(
  git wd colored-man-pages extract zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh
[[ -r $ZSH_HOME/setup-specific.zsh ]] && source $ZSH_HOME/setup-specific.zh
source $ZSH_HOME/envvars.zsh

# User configuration

export EDITOR='nvim'
export LS_COLORS=$($ZSH_HOME/scripts/dircolors.zsh)
export TREE_COLORS=$($ZSH_HOME/scripts/dircolors.zsh)

alias xclip='xclip -selection clipboard'
alias vim=nvim
alias sed='sed -r'
alias t='tree -aL 1 --dirsfirst'
alias l='\ls --color=tty -Aog --si --time-style=long-iso --group-directories-first'

export SPACK_ROOT=~/bin/program-files/spack
source $SPACK_ROOT/share/spack/setup-env.sh

export DOTFILES=$HOME'/projects/dotfiles'

# TODO: --> .profile