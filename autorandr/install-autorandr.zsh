__install_autorandr() {
  if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    printf "\
Usage:
  $0 [--force]

  Install autorandr.
"
    exit 0
  elif [ -z "$(command -v autorandr)" ] || [ "$1" = "--force" ]; then
    loglnprefix "autorandr" "Installing 'autorandr' ..."

    mkcd $(mktemp -d)
    git clone "https://github.com/phillipberndt/autorandr.git" .

    please mkdir -p /usr/local/share/man/man1/
    please cp autorandr.1 /usr/local/share/man/man1/
    please mkdir -p /usr/local/bin/
    please cp autorandr.py /usr/local/bin/autorandr

    loglnprefix "autorandr" "... done installing 'autorandr'."
  else
    loglnprefix "autorandr" "Nothing to do."
  fi
}
