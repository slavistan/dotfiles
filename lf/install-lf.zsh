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
	  echo obsolete
	  return 
  elif [ "$1" = "--uninstall" ] || [ "$1" = "-x" ]; then
    loglnprefix "lf" "Uninstalling 'lf' ..."
    please rm -f /usr/local/bin/lf
    rm -rf ~/.config/lf
    loglnprefix "lf" "... done uninstalling 'lf'."
  else
    loglnprefix "lf" "Nothing to do."
  fi
}
