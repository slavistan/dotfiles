__install_xclip() {
  if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    printf "\
Usage:
  $0 [--force]

  Install xclip.
"
    exit 0
  elif [ -z "$(command -v xclip)" ] || [ "$1" = "--force" ]; then
    loglnprefix "xclip" "Installing 'xclip' ..."
    cd $(mktemp -d) 
    git clone "https://github.com/astrand/xclip.git" .
    autoconf && ./configure && make && please make install
    loglnprefix "xclip" "... done installing 'xclip'."
  else
    loglnprefix "xclip" "Nothing to do."
  fi
}
