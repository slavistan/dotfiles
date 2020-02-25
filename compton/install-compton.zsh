install_compton() {
  if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    printf "\
Usage:
  $0

Symlinks './compton' to '$XDG_CONFIG_HOME/compton'.
Expects 'compton' to be installed manually."
    exit 0
  fi
  logln 'Setting up compton ...'
  rm -rf $XDG_CONFIG_HOME/compton
  mkdir -p $XDG_CONFIG_HOME
  cd $XDG_CONFIG_HOME
  ln -s $DOTFILES/compton
  logln '... done setting up compton.'
}
