__install_st() {
  if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    printf "\
Usage:
  $0 [--install | -i]
  $0 [--uninstall | -x] (NOT IMPLEMENTED)

Installs 'st' from source.
"
    exit 0
  elif [ "$1" = "--install" ] || [ "$1" = "-i" ]; then
    loglnprefix "st" "Installing 'st' from source ..."
    tmpdir=$(mktemp -d)
    trap "rm -rf $tmpdir" 0 1 15
    cd "$tmpdir"
    git clone https://github.com/slavistan/suckless-st.git .
    make clean
    please make install
    loglnprefix "st" "Exporting TERMINAL envvar to '$HOME/.profile'."
    addln "export TERMINAL=$(command -v st)" $HOME/.profile
    loglnprefix "st" "... done installing 'st'."
  elif [ "$1" = "--uninstall" ] || [ "$1" = "-x" ]; then
    loglnprefix "st" "Uninstall not implemented ..."
  else
    loglnprefix "st" "Nothing to be done."
  fi
}
