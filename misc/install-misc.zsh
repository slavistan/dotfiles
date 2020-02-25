__install_misc() {
  if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    printf "\
Usage:
  $0

Miscellaneous. See source file."
    exit 0
  fi
  addln "export JUPYTER_CONFIG_DIR=$XDG_CONFIG_HOME/jupyter" $HOME/.profile
}

