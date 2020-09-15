__install_autorandr() {
  case "$1" in
  -h|--help)
    cat <<-EOF
			Usage:
			  $0 [-s | --status]
			  $0 [-i | --install]
			  $0 [-u | --uninstall]
			EOF
    ;;
  ""|-s|--status)
    command -v autorandr &&
      autorandr --version ||
      loglnprefix "autorandr" "Not installed."
      ;;
  -i|--install)
    loglnprefix "autorandr" "Installing 'autorandr' ..."

    mkcd $(mktemp -d)
    git clone "https://github.com/phillipberndt/autorandr.git" .

    please mkdir -p /usr/local/share/man/man1/
    please cp autorandr.1 /usr/local/share/man/man1/
    please mkdir -p /usr/local/bin/
    please cp autorandr.py /usr/local/bin/autorandr

    # Refresh wallpaper after changing xrandr settings
    mkcd $XDG_CONFIG_HOME/autorandr/
    ln -s $DOTFILES/scripts/wallpaper.sh postswitch

    loglnprefix "autorandr" "... done installing 'autorandr'."
    ;;
  -u|--uninstall);;

  esac
}
