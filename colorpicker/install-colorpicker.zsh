__install_colorpicker() {
  if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    printf "\
Usage:
  $0 [--force]

Installs 'colorpicker' from source.
"
    exit 0
  elif [ -z "$(command -v colorpicker)" ] || [ "$1" = "--force" ]; then
    loglnprefix "colorpicker" "Installing colorpicker from source ..."
    please apt install -y gtk-2.0
    tmp=$(mktemp -d)
    git clone https://github.com/Jack12816/colorpicker.git $tmp
    cd $tmp
    make
    cp ./colorpicker ~/bin
    loglnprefix "colorpicker" "... done."
  else
    loglnprefix "colorpicker" "Nothing to do."
  fi
}
