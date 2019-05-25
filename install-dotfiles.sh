#!/bin/bash

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

set -e

##
# Options - Adjust according to setup
##
configure_nvim=true
configure_st=false
configure_i3=false
configure_zsh=true
configure_byobu=true
config_dir=$HOME'/.config'

##
# Script
##
dotfiles_dir=$(dirname $(realpath "$0"))
temp_dir=$(mktemp -d)

read -rsp 'Enter your sudo password: ' pw
sudo -kSp '' true <<<"${pw}" > /dev/null 2>&1
if [[ "$?" != "0" ]]; then
  echo 'Invalid password. Abort.'
  exit 1
fi
echo 'OK.'

if [[ $configure_nvim == true ]]; then
  echo "Configuring nvim ..."
  mkdir -p $config_dir && cd "$_" && rm -rf nvim
  ln -s $dotfiles_dir/nvim nvim
  nvim +PlugInstall +quitall
fi

if [[ $configure_st == true ]]; then
  echo 'Configuring st ...'
  mkdir -p $temp_dir/st
  git clone https://github.com/slavistan/st.git $temp_dir/sh && cd "$_"
  sudo -Sp '' make clean install <<<${pw}
fi

if [[ $configure_zsh == true ]]; then
  echo 'Configuring zsh ...'
  rm -rf $dotfiles_dir/zsh/oh-my-zsh
  mkdir -p $config_dir && cd "$_" && rm -rf zsh
  ln -s $dotfiles_dir/zsh zsh
  ln -fs $config_dir/zsh/zshrc ~/.zshrc
  git clone https://github.com/robbyrussell/oh-my-zsh.git $config_dir/zsh/oh-my-zsh
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $config_dir/zsh/oh-my-zsh/plugins/zsh-syntax-highlighting
  git clone --recursive git://github.com/joel-porquet/zsh-dircolors-solarized $config_dir/zsh/oh-my-zsh/plugins/zsh-dircolors-solarized
  echo 'source ~/.zshrc;setupsolarized dircolors.ansi-light' | zsh -s
fi

if [[ $configure_i3 == true ]]; then
  echo 'Configuring i3 ...'
  mkdir -p $config_dir && cd "$_" && rm -rf i3
  ln -s $dotfiles_dir/i3 i3
  ln -fs $config_dir/i3/config-i3 $config_dir/i3/config
fi

if [[ $configure_byobu == true ]]; then
  echo 'Configuring byobu ...'
  mkdir -p $config_dir && cd "$_" && rm -rf byobu
  mkdir byobu && cd "$_"
  ln -fs $dotfiles_dir/byobu/config-tmux keybindings.tmux
fi
# TODO:
## Blocks
## .profile
