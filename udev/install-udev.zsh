__install_udev() {
  if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    printf "\
Usage:
  $0

Symlinks udev-rules into '/etc/udev/rules.d'.
"
    exit 0
  else
    loglnprefix "udev" "Symlinking rules ..."
    cd /etc/udev/rules.d
    please ln -fs $DOTFILES/udev/99-stan.rules
    cd /usr/local/bin
    please ln -fs $DOTFILES/udev/udev-trigger.sh
    please udevadm control --reload
  fi
}
