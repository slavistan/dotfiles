#!/bin/bash

BASEDIR=$(dirname $(realpath "$0"))

mkdir -p ~/.config

read -rsp 'Enter your sudo password: ' pw
sudo -kSp '' true <<<"${pw}" > /dev/null 2>&1
if [[ "$?" != "0" ]]; then
  echo 'Invalid password. Abort.'
  exit 1
fi
echo 'OK.'

echo "Installing git .. "
if [[ -z "$(command -v git)" ]]; then
  sudo -Sp '' yum install git <<<${pw}
fi

echo "Install cmake .. "
if [[ -z "$(command -v cmake)" ]]; then
  sudo -Sp '' yum install cmake <<<${pw}
fi

echo 'Installing nvim ...'
if [[ -z "$(command -v nvim)" ]]; then
  rm -rf ~/Downloads/dotfiles/nvim
  mkdir -p ~/Downloads/dotfiles/nvim && cd "$_"
  git clone https://github.com/nvim/nvim.git ~/Downloads/dotfiles/nvim
  make CMAKE_BUILD_TYPE=Release
  sudo -Sp '' make install <<<${pw}
  cd $BASEDIR
  rm -rf ~/Downloads/dotfiles/nvim
fi
mkdir -p ~/.config/nvim/plug-plugins ~/.config/nvim/autoload
nvim +PlugInstall +quitall

echo 'Installing st ...'
rm -rf ~/Downloads/dotfiles/st
mkdir -p ~/Downloads/dotfiles/st && cd "$_"
git clone git@github.com:slavistan/st.git ~/Downloads/dotfiles/st
sudo -Sp '' make clean install <<<${pw}
cd $BASEDIR
rm -rf ~/Downloads/dotfiles/st

echo 'Installing zsh ...'
rm -f ~/.zshrc
ln -s ~/.config/zsh/zshrc ~/.zshrc

echo 'Installing i3 ...'
sudo -Sp '' dnf coprenable gregw/i3desktop<<<${pw}
sudo -Sp '' dnf install i3blocks<<<${pw}
rm -f ~/.i3blocks.conf
ln -s ~/.config/i3/i3blocks.conf ~/.i3blocks.conf

