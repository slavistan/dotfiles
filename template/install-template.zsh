__install_template() {
  if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    printf "\
Usage:
  $0 [--force]

  Install template.
"
    exit 0
  elif [ -z "$(command -v template)" ] || [ "$1" = "--force" ]; then
    loglnprefix "template" "Installing 'template' ..."

    # ..

    loglnprefix "template" "... done installing 'template'."
  else
    loglnprefix "template" "Nothing to do."
  fi
}
