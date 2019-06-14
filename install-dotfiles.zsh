#!/bin/zsh

setopt +o nomatch # disable errors from empty globs
set -e # abort on error

# We use the XDG_... conventions. Enfore definition.
if [[ -z "$XDG_CONFIG_HOME" ]]; then 
  echo "XDG_CONFIG_HOME is not defined. Abort."
  exit 1
fi

if [[ "$1" == "--check-dependencies" ]]; then
  return_code=0
  # Binaries
  for dep in {git,nvim,i3,i3blocks,st}; do
    echo -n "$dep: "
    if [[ ! -z $(command -v $dep) ]]; then
      echo $(command -v $dep)
    else
      echo -- missing --
      return_code=1
    fi
  done

  # Hack font
  echo 'Hack font: '$(fc-list | grep Hack | head -n 1)
  [[ -z "$(fc-list | grep Hack)" ]] && return_code=1
  echo 'FontAwesome font: '$(fc-list | grep FontAwesome | head -n 1)
  [[ -z "$(fc-list | grep Hack)" ]] && return_code=1

  exit $return_code
fi



##
# Options - Adjust according to setup
##
configure_zsh=true
configure_nvim=true
configure_st=true
configure_i3=true
configure_tmux=true
configure_git=true
configure_xkb=false

##
# Script
##
[[ -z $DOTFILES ]] && export DOTFILES=$(dirname "$0:A")
temp=$(mktemp -d)
echo "Using the following directories: "
echo "  DOTFILES:        $DOTFILES"
echo "  XDG_CONFIG_HOME: $XDG_CONFIG_HOME"
echo "  Temporary:       $temp"
read -qs "reply?> Continue? [Y/n]: "
if [[ ! "$reply" == "y" ]]; then
  echo "Exiting. Nothing done."
  exit 0
else
  echo "Continuing installation."
fi

# Enter user password and check it
read -s "pw?> Enter your sudo password: "
sudo -kSp '' true <<<"${pw}" > /dev/null 2>&1
if [[ "$?" != "0" ]]; then
  echo 'Invalid password. Abort.'
  exit 1
fi
echo 'OK.'
# sudo wrapper
function _sudo {
  sudo -Sp '' "$@" <<<${pw}
}

# create config directory, if it does not already exist.
mkdir -p $XDG_CONFIG_HOME

###########
## .profile - Create barebone and add content depending on installed modules
###########
echo '# This file was created automatically.'                                                       > $HOME/.profile
echo 'export XDG_CONFIG_HOME='"$XDG_CONFIG_HOME"                                                   >> $HOME/.profile
echo 'export LANG=en_US.utf8'                                                                      >> $HOME/.profile
echo 'export TZ="Europe/Berlin"'                                                                   >> $HOME/.profile
echo '[[ ! -z $(command -v wslpath) ]] && export BROWSER="firefox.exe" || export BROWSER="firefox"'>> $HOME/.profile
echo '[[ ! -z $(command -v wslpath) ]] && export DISPLAY=localhost:0.0'                            >> $HOME/.profile

###########
## Keyboard Layout
###########
cd /usr/share/X11/xkb/symbols/
_sudo ln -fs $DOTFILES/xkb/symbols/stan
echo 'setxkbmap -layout stan' >> $HOME/.profile

###########
## ZSH + OhMyZsh
###########
if [[ $configure_zsh == true ]]; then
  echo 'Configuring zsh ...'

# Make zsh use XDG_CONFIG_HOME
# Cannot send output to a file using sudo thus we stuff a dummy file and sudo-copy it in place.
# Shell scripting is a royal pain the ass.
  _sudo printf \
    '# /etc/zsh/zshenv: system-wide .zshenv file for zsh(1).'"\n"'# Global Order: zshenv, zprofile, zshrc, zlogin'"\n"'[[ ! -z "$XDG_CONFIG_HOME" ]] && export ZDOTDIR="$XDG_CONFIG_HOME/zsh/"'"\n" > $temp/zshenv
  _sudo cp -f $temp/zshenv /etc/zshenv

  echo "export SHELL=/usr/bin/zsh" >> $HOME/.profile

# Install OhMyZsh
# Delete existing files, clone oh-my-zsh, install plugins and themes
  cd $DOTFILES/zsh
  rm -rf oh-my-zsh # remove oh-my-zsh files
  git clone https://github.com/robbyrussell/oh-my-zsh.git
  cd oh-my-zsh
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ./plugins/zsh-syntax-highlighting # ..
  git clone https://github.com/slavistan/milton-oh-my-zsh-theme.git ./themes/milton

# Symlink XDG path to dotfiles
  mkdir -p $XDG_CONFIG_HOME && cd "$_" # enter config dir
  ln -fs $DOTFILES/zsh # create symlink

# Create barebone envvars file
  rm $DOTFILES/zsh/envvars.zsh
  touch $DOTFILES/zsh/envvars.zsh
fi


###########
## NVim
###########
if [[ $configure_nvim == true ]]; then
  echo "Configuring nvim ..."
  rm -rf $DOTFILES/nvim/plug_plugins/*/
  rm -f $XDG_CONFIG_HOME/nvim
  mkdir -p $XDG_CONFIG_HOME && cd "$_" && ln -s $DOTFILES/nvim .
  nvim +PlugClean +PlugInstall +quitall

  echo "export EDITOR=nvim" >> $HOME/.profile
  echo "alias view=$EDITOR -R" >> $DOTFILES/zsh/envvars.zsh
fi

###########
## ST
###########
if [[ $configure_st == true ]]; then
  echo 'Configuring st ...'
  mkdir -p $temp/st
  git clone https://github.com/slavistan/st.git $temp/st
  cd $temp/st
  _sudo make clean install
fi

###########
## i3wm
###########
if [[ $configure_i3 == true ]]; then
  echo 'Configuring i3 ...'
  rm -rf $XDG_CONFIG_HOME/i3
  ln -sT $DOTFILES/i3 $XDG_CONFIG_HOME/i3
fi

###########
## tmux
###########
if [[ $configure_tmux == true ]]; then
  echo 'Configuring tmux ...'
  rm -f $XDG_CONFIG_HOME/tmux && ln -s $DOTFILES/tmux $XDG_CONFIG_HOME/tmux
# TODO: Make envvars unique
  echo "alias tmux='tmux -f $XDG_CONFIG_HOME/tmux/config'" >> $DOTFILES/zsh/envvars.zsh
fi

###########
## git
###########
if [[ $configure_git == true ]]; then
  echo 'Configuring git ...'
  mkdir -p $XDG_CONFIG_HOME && cd "$_" && rm -rf git
  ln -s $DOTFILES/git git
  ln -fs $XDG_CONFIG_HOME/git/config ~/.gitconfig
fi

source $XDG_CONFIG_HOME/zsh/.zshrc

# TODO:
## Blocks
## .profile
## ~/.zcompdump
