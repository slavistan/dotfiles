__install_lf() {
  if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    printf "\
Usage:
  $0 [--install | -i]
  $0 [--uninstall | -x]

  Install lf.
"
    exit 0
  elif [ "$1" = "--install" ] || [ "$1" = "-i" ]; then
    loglnprefix "lf" "Building 'lf' from source ..."
    tmpdir=$(mktemp -d)
    trap "rm -rf $tmpdir" 0 1 15
    cd "$tmpdir"
    GOPATH=$(realpath .) go get -u github.com/gokcehan/lf
    please cp bin/lf /usr/local/bin
    cd -p ~/.config/lf
    ln -sf $DOTFILES/lf/lfrc
    loglnprefix "lf" "... done installing 'lf'."
  elif [ "$1" = "--uninstall" ] || [ "$1" = "-x" ]; then
    loglnprefix "lf" "Uninstalling 'lf' ..."
    please rm -f /usr/local/bin/lf
    rm -r ~/.config/lf
    loglnprefix "lf" "... done uninstalling 'lf'."
  else
    loglnprefix "lf" "Nothing to do."
  fi
}
