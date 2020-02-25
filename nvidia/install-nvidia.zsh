__install_nvidia() {
  if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    printf "\
Usage:
  $0

Exports envvar to make nvidia driver use XDG_CACHE_HOME."
    exit 0
  fi

  loglnprefix "nvidia" "Setting up nvidia settings ..."
  addln "export __GL_SHADER_DISK_CACHE_PATH=$XDG_CACHE_HOME" $HOME/.profile
  loglnprefix "nvidia" "... done."
}
