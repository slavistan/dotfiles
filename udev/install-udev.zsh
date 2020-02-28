__install_udev() {
  if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    printf "\
Usage:
  $0

Symlinks udev-rules to '/etc/udev/rules.d'
"
    exit 0
  else
    loglnprefix "udev" "Symlinking rules ..."
    cd /etc/udev/rules.d
    please ln -s $DOTFILES/udev/99-stan.rules
  fi
}
