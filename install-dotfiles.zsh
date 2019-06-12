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
onfigure_st=true
configure_i3=true
configure_tmux=true
configure_git=true
config_dir=$HOME'/.config'

##
# Script
##
dotfiles_dir=$(dirname "$0:A")
temp_dir=$(mktemp -d)
echo 'Dotfiles: '$dotfiles_dir
echo 'Config: '$config_dir
echo 'Tempdir: '$temp_dir

read "pw?Enter your sudo password: "
sudo -kSp '' true <<<"${pw}" > /dev/null 2>&1
if [[ "$?" != "0" ]]; then
  echo 'Invalid password. Abort.'
  exit 1
fi
echo 'OK.'
function _sudo {
  sudo -Sp '' "$@" <<<${pw}
}

###########
## .profile - Create barebone and add content depending on installed modules
###########
echo '# This file was created automatically.'                                                       > $HOME/.profile
echo 'export XDG_CONFIG_HOME='"$XDG_CONFIG_HOME"                                                   >> $HOME/.profile
echo 'export LANG=de_DE.utf8'                                                                      >> $HOME/.profile
echo 'export TZ="Europe/Berlin"'                                                                   >> $HOME/.profile
echo '[[ ! -z $(command -v wslpath) ]] && export BROWSER="firefox.exe" || export BROWSER="firefox"'>> $HOME/.profile
echo '[[ ! -z $(command -v wslpath) ]] && export DISPLAY=localhost:0.0'                            >> $HOME/.profile

###########
## Keyboard Layout
###########
cd /usr/share/X11/xkb/symbols/
# Can't use symlink on CentOS :( Hardcopy instead
_sudo cp $dotfiles_dir/xkb/symbols/stan /usr/share/X11/xkb/symbols
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
    '# /etc/zsh/zshenv: system-wide .zshenv file for zsh(1).'"\n"'# Global Order: zshenv, zprofile, zshrc, zlogin'"\n"'[[ ! -z "$XDG_CONFIG_HOME" ]] && export ZDOTDIR="$XDG_CONFIG_HOME/zsh/"'"\n" > $temp_dir/zshenv
  _sudo cp -f $temp_dir/zshenv /etc/zshenv

# Export shell variable in profile
  echo "export SHELL=/usr/bin/zsh" >> $HOME/.profile

# Install OhMyZsh
  cd $dotfiles_dir/zsh
  rm -rf oh-my-zsh # remove oh-my-zsh files
  git clone https://github.com/robbyrussell/oh-my-zsh.git
  cd oh-my-zsh # clone oh-my-zsh and submodules ..
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ./plugins/zsh-syntax-highlighting # ..
  git clone https://github.com/romkatv/powerlevel10k.git ./themes/powerlevel10k # ..

# Symlink XDG path to dotfiles
  mkdir -p $XDG_CONFIG_HOME && cd "$_" # enter config dir
  ln -fs $dotfiles_dir/zsh # create symlink

# Create barebone envvars file
  touch $dotfiles_dir/zsh/envvars.zsh
fi


###########
## NVim
###########
if [[ $configure_nvim == true ]]; then
  echo "Configuring nvim ..."
  rm -rf $dotfiles_dir/nvim/plug_plugins/*/
  rm -f $config_dir/nvim
  mkdir -p $config_dir && cd "$_" && ln -s $dotfiles_dir/nvim .
  nvim +PlugClean +PlugInstall +quitall

  echo "export EDITOR=nvim" >> $HOME/.profile
  echo "alias view=$EDITOR -R" >> $dotfiles_dir/zsh/envvars.zsh
fi

###########
## ST
###########
if [[ $configure_st == true ]]; then
  echo 'Configuring st ...'
  mkdir -p $temp_dir/st
  git clone https://github.com/slavistan/st.git $temp_dir/sh && cd "$_"
  sudo -Sp '' make clean install <<<${pw}
fi

###########
## i3wm
###########
if [[ $configure_i3 == true ]]; then
  echo 'Configuring i3 ...'
  mkdir -p $config_dir && cd "$_" && rm -rf i3
  ln -s $dotfiles_dir/i3 i3
  ln -fs $config_dir/i3/config-i3 $config_dir/i3/config
fi

###########
## tmux
###########
if [[ $configure_tmux == true ]]; then
  echo 'Configuring tmux ...'
  rm -f $config_dir/tmux && ln -s $dotfiles_dir/tmux $config_dir/tmux
# TODO: Make envvars unique
  echo "alias tmux='tmux -f $config_dir/tmux/config'" >> $dotfiles_dir/zsh/envvars.zsh
fi

###########
## git
###########
if [[ $configure_git == true ]]; then
  echo 'Configuring git ...'
  mkdir -p $config_dir && cd "$_" && rm -rf git
  ln -s $dotfiles_dir/git git
  ln -fs $config_dir/git/config ~/.gitconfig
fi

source $XDG_CONFIG_HOME/zsh/.zshrc

# TODO:
## Blocks
## .profile
## ~/.zcompdump
