#!/bin/zsh

# Disable errors from empty globs
setopt +o nomatch

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
configure_zsh=true
configure_nvim=true
onfigure_st=false
configure_i3=false
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

if [[ $configure_zsh == true ]]; then
  echo 'Configuring zsh ...'
  cd $dotfiles_dir/zsh
  rm -rf oh-my-zsh # remove oh-my-zsh files
  git clone https://github.com/robbyrussell/oh-my-zsh.git
  cd oh-my-zsh # clone oh-my-zsh and submodules ..
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ./plugins/zsh-syntax-highlighting # ..
  git clone https://github.com/romkatv/powerlevel10k.git ./themes/powerlevel10k # ..
  mkdir -p $config_dir && cd "$_" # enter config dir
  ln -fs $dotfiles_dir/zsh # create symlink
  cd $HOME
  rm .zshrc
  ln -fs $dotfiles_dir/zsh/zshrc ~/.zshrc

  touch $dotfiles_dir/zsh/envvars.zsh
fi

if [[ $configure_nvim == true ]]; then
  echo "Configuring nvim ..."
  rm -rf $dotfiles_dir/nvim/plug_plugins/*/
  rm -f $config_dir/nvim
  mkdir -p $config_dir && cd "$_" && ln -s $dotfiles_dir/nvim .
  nvim +PlugClean +PlugInstall +quitall
fi

if [[ $configure_st == true ]]; then
  echo 'Configuring st ...'
  mkdir -p $temp_dir/st
  git clone https://github.com/slavistan/st.git $temp_dir/sh && cd "$_"
  sudo -Sp '' make clean install <<<${pw}
fi

if [[ $configure_i3 == true ]]; then
  echo 'Configuring i3 ...'
  mkdir -p $config_dir && cd "$_" && rm -rf i3
  ln -s $dotfiles_dir/i3 i3
  ln -fs $config_dir/i3/config-i3 $config_dir/i3/config
fi

if [[ $configure_tmux == true ]]; then
  echo 'Configuring tmux ...'
  rm -f $config_dir/tmux && ln -s $dotfiles_dir/tmux $config_dir/tmux
# TODO: Make envvars unique
  echo "alias tmux='tmux -f $config_dir/tmux/config'" >> $dotfiles_dir/zsh/envvars.zsh
fi

if [[ $configure_git == true ]]; then
  echo 'Configuring git ...'
  mkdir -p $config_dir && cd "$_" && rm -rf git
  ln -s $dotfiles_dir/git git
  ln -fs $config_dir/git/config ~/.gitconfig
fi

source ~/.zshrc

# TODO:
## Blocks
## .profile
