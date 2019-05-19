#!/bin/bash

set -e

PKGMGR="$1"
if [[ -z "$(command -v $PKGMGR)" ]]; then
  echo 'Unknown package manager.'
  exit 1
fi

rm -rf ~/Downloads/dotfiles
BASEDIR=$(dirname $(realpath "$0"))

read -rsp 'Enter your sudo password: ' pw
sudo -kSp '' true <<<"${pw}" > /dev/null 2>&1
if [[ "$?" != "0" ]]; then
  echo 'Invalid password. Abort.'
  exit 1
fi
echo 'OK.'

echo "Installing git .. "
if [[ -z "$(command -v git)" ]]; then
  sudo -Sp '' $PKGMGR install -y git <<<${pw}
fi

echo "Install cmake .. "
if [[ -z "$(command -v cmake3)" ]]; then
  sudo -Sp '' $PKGMGR install -y cmake3 <<<${pw}
fi

echo 'Installing nvim ...'
if [[ -z "$(command -v nvim)" ]]; then
  sudo -Sp '' $PKGMGR install -y libtool <<<${pw}
  mkdir -p ~/Downloads/dotfiles/nvim && cd "$_"
  git clone https://github.com/neovim/neovim.git ~/Downloads/dotfiles/nvim
  make CMAKE_BUILD_TYPE=Release
  sudo -Sp '' make install <<<${pw}
  cd $BASEDIR
fi
mkdir -p ~/.config/nvim/plug-plugins ~/.config/nvim/autoload
nvim +PlugInstall +quitall

echo 'Installing st ...'
sudo -Sp '' $PKGMGR install -y fontconfig-devel <<<${pw}
mkdir -p ~/Downloads/dotfiles/st && cd "$_"
git clone https://github.com/slavistan/st.git ~/Downloads/dotfiles/st
sudo -Sp '' make clean install <<<${pw}
cd $BASEDIR

echo 'Installing zsh ...'
rm -f ~/.zshrc
ln -s ~/.config/zsh/zshrc ~/.zshrc
rm -rf ~/.config/zsh/oh-my-zsh
git clone https://github.com/robbyrussell/oh-my-zsh.git ~/.config/zsh/oh-my-zsh
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.config/zsh/oh-my-zsh/plugins/zsh-syntax-highlighting
git clone --recursive git://github.com/joel-porquet/zsh-dircolors-solarized ~/.config/zsh/oh-my-zsh/plugins/zsh-dircolors-solarized
echo 'source ~/.zshrc;setupsolarized dircolors.ansi-light' | zsh -s

echo 'Installing i3 ...'
rm -rf ~/Downloads/dotfiles/i3blocks
git clone https://github.com/vivien/i3blocks.git ~/.Downloads/dotfiles/i3blocks && cd "$_"
./autogen.sh
./configure
make
sudo -Sp '' make clean install <<<${pw}
rm -f ~/.i3blocks.conf
ln -s ~/.config/i3/i3blocks.conf ~/.i3blocks.conf

rm -rf ~/Downloads/dotfiles

