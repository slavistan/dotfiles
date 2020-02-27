__install_sxhkd() {
  if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    printf "\
Usage:
  $0 [--force]

Installs 'sxhkd' from source and symlinks ./sxhkd/sxhkdrc
into $XDG_CONFIG_HOME/sxhkd. Use the force-flag to overwrite
an existing installation."
    exit 0
  elif [ -z "$(command -v st)" ] || [ "$1" = "--force" ]; then
    loglnprefix "sxhkd" "Installing sxhkd from source ..."
    tmp=$(mktemp -d)
    git clone https://github.com/baskerville/sxhkd.git $tmp
    cd $tmp
    make && please make install
    loglnprefix "sxhkd" "Installing sxhkd configuration files ..."
    rm -rf $XDG_CONFIG_HOME/sxhkd
    mkdir -p $XDG_CONFIG_HOME/sxhkd
    ln -s $DOTFILES/sxhkd/sxhkdrc $XDG_CONFIG_HOME/sxhkd
    loglnprefix "sxhkd" "... done."
  else
    loglnprefix "sxhkd" "Nothing to do."
  fi
}
