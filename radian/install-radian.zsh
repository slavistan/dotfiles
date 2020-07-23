__install_radian() {
  if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    printf "\
Usage:
  $0 [--force]

  Install radian.
"
    exit 0
  elif [ -z "$(command -v radian)" ] || [ "$1" = "--force" ]; then
    loglnprefix "radian" "Installing 'radian' ..."

    please pip3 install radian

    mkdir -p ~/.config/radian
    cd ~/.config/radian
    ln -sf $DOTFILES/radian/profile

    loglnprefix "radian" "... done installing 'radian'."
  else
    loglnprefix "radian" "Nothing to do."
  fi
}
