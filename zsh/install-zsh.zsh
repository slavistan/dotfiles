install_zsh() {
  if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    printf "\
Usage:
  $0

Symlinks './zsh' into '$XDG_CONFIG_HOME/zsh' and sets up
envvars. Expects 'zsh' to be already installed."
    exit 0
  fi

  loglnprefix "zsh" "Setting up zsh ..."
  if [ -z "$(command -v zsh)" ]; then
    errln 'zsh not found. Install zsh and rerun this script.'
    exit 1
  fi

  addln "export SHELL=/usr/bin/zsh" $HOME/.profile
  addln "export ZDOTDIR=$XDG_CONFIG_HOME/zsh" $HOME/.profile
  mkdir -p $XDG_CONFIG_HOME
  rm -rf $XDG_CONFIG_HOME/zsh
  cd $XDG_CONFIG_HOME
  ln -fs $DOTFILES/zsh
  loglnprefix "zsh" "... done installing 'zsh'"
}
