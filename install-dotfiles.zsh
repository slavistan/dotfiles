#!/bin/zsh

# TODO:
# - Make this posix-compliant
# - Don't delete and recreate .profile. Insert lines only if the file does not
#   contain them. This way we can put setup specific stuff into the .profile
#   without that being wiped when running this install script.

setopt +o nomatch # disable errors from empty globs
set -e # abort on error

# We use the XDG_... conventions. Enfore definition.
if [ -z "$XDG_CONFIG_HOME" ] || [ -z "$XDG_DATA_HOME" ]; then
  echo "XDG_CONFIG_HOME or XDG_DATA_HOME is not defined. Abort."
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
configure_st=false
configure_i3=false
configure_tmux=false
configure_git=true
configure_xkb=false
configure_acpi=false

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
if [[ $configure_xkb == true ]]; then
  cd /usr/share/X11/xkb/symbols/
  _sudo ln -fs $DOTFILES/xkb/symbols/stan
  echo 'setxkbmap -layout stan' >> $HOME/.profile
fi

###########
## zsh
###########
if [[ $configure_zsh == true ]]; then
  printf 'Configuring zsh ...\n'

  echo "export SHELL=/usr/bin/zsh" >> $HOME/.profile
  echo "export ZDOTDIR=$XDG_CONFIG_HOME/zsh" >> $HOME/.profile

# Symlink XDG path to dotfiles
  mkdir -p $XDG_CONFIG_HOME && cd "$_" # enter config dir
  ln -fs $DOTFILES/zsh # create symlink

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
  echo "export TERMINAL="$(command -v st) >> $HOME/.profile
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

###########
## ACPI
###########
# TODO: Configure systemd to ignore the corresponding events
if [ $configure_acpi = "true" ]; then
  _sudo rm -rf /etc/acpi/events /etc/acpi/actions
  _sudo cp -r $DOTFILES/acpi/events /etc/acpi
  _sudo cp -r $DOTFILES/acpi/actions /etc/acpi
fi

###########
## Misc
###########
# Makes jupyter use XDG paths
echo "export JUPYTER_CONFIG_DIR=$XDG_CONFIG_HOME/jupyter" >> ~/.profile

source $XDG_CONFIG_HOME/zsh/.zshrc
