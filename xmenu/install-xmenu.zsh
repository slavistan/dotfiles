__install_xmenu() {
  if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    printf "\
Usage:
  $0 [--force]

  Install xmenu.
"
    exit 0
  elif [ -z "$(command -v xmenu)" ] || [ "$1" = "--force" ]; then
    loglnprefix "xmenu" "Installing 'xmenu' ..."
    cd $(mktemp -d)
    git clone https://github.com/phillbush/xmenu.git .
    sudo make install
    loglnprefix "xmenu" "... done installing 'xmenu'."
  else
    loglnprefix "xmenu" "Nothing to do."
