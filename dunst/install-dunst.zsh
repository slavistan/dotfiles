__install_dunst() {
  if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    printf "\
Usage:
  $0 [--force]

  Install dunst.
"
    exit 0
  elif [ -z "$(command -v dunst)" ] || [ "$1" = "--force" ]; then
    set -e
    loglnprefix "dunst" "Installing 'dunst' ..."

    tmpdir=$(mktemp -d)
    cd "$tmpdir"
    git clone "https://github.com/dunst-project/dunst.git" .
    please make install

    mkdir -p ~/.config/dunst
    cd ~/.config/dunst
    ln -sf $DOTFILES/dunst/dunstrc
    loglnprefix "dunst" "... done installing 'dunst'."
  else
    loglnprefix "dunst" "Nothing to do."
  fi
}
