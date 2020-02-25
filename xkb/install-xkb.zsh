__install_xkb() {
  if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    printf "\
Usage:
  $0

Creates symlink of './xkb/symbols/stan' in '/usr/share/X11/xkb/symbols'."
    exit 0
  fi
  logln 'Setting up xkb...'
  cd /usr/share/X11/xkb/symbols/
  please ln -fs $DOTFILES/xkb/symbols/stan
  logln '... done settings up xkb.'
}
