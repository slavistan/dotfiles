__install_sxiv() {
  if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    printf "\
Usage:
  $0 [--force]

  Install sxiv, the simple X image viewer.
"
    exit 0
  elif [ -z "$(command -v sxiv)" ] || [ "$1" = "--force" ]; then
    loglnprefix "sxiv" "Installing 'sxiv' ..."
    tmpdir=$(mktemp -d -t sxiv_XXXXXX)
    loglnprefix "sxiv" "tmpdir=$tmpdir"
    cd "$tmpdir"
    git clone https://github.com/muennich/sxiv.git .
    please make install
    rm -rf "$mpdir"
    loglnprefix "sxiv" "... done installing 'sxiv'."
  else
    loglnprefix "sxiv" "Nothing to do."
  fi
}
