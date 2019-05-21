#!/bin/bash
set -e

if [[ "$1" == "--check-dependencies" ]]; then
  command -v git nvim i3 i3blocks st
  exit 0
fi

##
# Options - Adjust according to setup
##
configure_nvim=true
configure_st=true
configure_i3=true
configure_zsh=true
config_dir='~/.config'

##
# Script
##
my_dir=$(dirname $(realpath "$0"))
temp_dir=mktemp -d

mkdir -p $config_home

read -rsp 'Enter your sudo password: ' pw
sudo -kSp '' true <<<"${pw}" > /dev/null 2>&1
if [[ "$?" != "0" ]]; then
  echo 'Invalid password. Abort.'
  exit 1
fi
echo 'OK.'

if [[ configure_nvim == true ]]; then
  echo "Configuring nvim ..."
  rm -rf $config_dir/nvim
  cp -r $my_dir/nvim $config_dir
  nvim +PlugInstall +quitall
fi

if [[ configure_st == true ]]; then
  echo 'Configuring st ...'
  mkdir -p $temp_dir/st && cd "$_"
  git clone https://github.com/slavistan/st.git ~/Downloads/dotfiles/st
  sudo -Sp '' make clean install <<<${pw}
  cd $my_dir
fi

if [[ configure_zsh == true ]]; then
  echo 'Configuring zsh ...'
  rm -rf $config_dir/zsh
  cp -r $my_dir/zsh $config_dir
  ln -fs $config_dir/zsh/zshrc ~/.zshrc
  git clone https://github.com/robbyrussell/oh-my-zsh.git $config_dir/zsh/oh-my-zsh
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $config_dir/zsh/oh-my-zsh/plugins/zsh-syntax-highlighting
  git clone --recursive git://github.com/joel-porquet/zsh-dircolors-solarized $config_dir/zsh/oh-my-zsh/plugins/zsh-dircolors-solarized
  echo 'source ~/.zshrc;setupsolarized dircolors.ansi-light' | zsh -s
fi

if [[ configure_i3 == true ]]; then
  echo 'Configuring i3 ...'
  rm -rf $config_dir/i3
  cp -r $my_dir/i3 $config_dir
  ln -fs $config_dir/i3/config-i3 $config_dir/i3/config
fi
