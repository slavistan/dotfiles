__install_sxhkd() {
  if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    printf "\
Usage:
  $0

Symlinks ./sxhkd/sxhkdrc into $XDG_CONFIG_HOME/sxhkd."
    exit 0
  fi

  rm -rf $XDG_CONFIG_HOME/sxhkd
  mkdir -p $XDG_CONFIG_HOME/sxhkd
  ln -s $DOTFILES/sxhkd/sxhkdrc $XDG_CONFIG_HOME/sxhkd
}
