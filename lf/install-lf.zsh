__install_lf() {
  if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    printf "\
Usage:
  $0 [--force]

  Install lf.
"
    exit 0
  elif [ -z "$(command -v lf)" ] || [ "$1" = "--force" ]; then
    loglnprefix "lf" "Installing 'lf' ..."

    # ..

    loglnprefix "lf" "... done installing 'lf'."
  else
    loglnprefix "lf" "Nothing to do."
  fi
}
