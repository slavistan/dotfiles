#!/bin/bash

set -e

TEMP_DIR=mktemp -d
rm -rf ~/Downloads/dotfiles
BASEDIR=$(dirname $(realpath "$0"))

read -rsp 'Enter your sudo password: ' pw
sudo -kSp '' true <<<"${pw}" > /dev/null 2>&1
if [[ "$?" != "0" ]]; then
  echo 'Invalid password. Abort.'
  exit 1
fi
echo 'OK.'

reqs=(git cmake nvim i3 i3blocks zsh)
command -v $reqs
if [[ "$?" != "0" ]]; then
  echo "Please install requirements: "$reqs
  exit 1
fi

if [[ ! -z $(commands -v nvim) ]]; then
  echo "Configuring nvim ..."
  mkdir -p ~/.config/nvim/plug-plugins ~/.config/nvim/autoload
  nvim +PlugInstall +quitall
else
  echo "nvim not found. Skipping configuration."
fi

echo 'Configuring st ...'
sudo -Sp '' $PKGMGR install -y fontconfig-devel <<<${pw}
mkdir -p ~/Downloads/dotfiles/st && cd "$_"
git clone https://github.com/slavistan/st.git ~/Downloads/dotfiles/st
sudo -Sp '' make clean install <<<${pw}
cd $BASEDIR

echo 'Configuring zsh ...'
ln -fs ~/.config/zsh/zshrc ~/.zshrc
rm -rf ~/.config/zsh/oh-my-zsh
git clone https://github.com/robbyrussell/oh-my-zsh.git ~/.config/zsh/oh-my-zsh
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.config/zsh/oh-my-zsh/plugins/zsh-syntax-highlighting
git clone --recursive git://github.com/joel-porquet/zsh-dircolors-solarized ~/.config/zsh/oh-my-zsh/plugins/zsh-dircolors-solarized
echo 'source ~/.zshrc;setupsolarized dircolors.ansi-light' | zsh -s

echo 'Configuring i3 ...'
# Nothing to do

rm -rf ~/Downloads/dotfiles
