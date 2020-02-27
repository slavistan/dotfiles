__install_dwm() {
  if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    printf "\
Usage:
  $0 [--force]

Installs 'dwm' from source and symlinks './dwm' into
'$XDG_CONFIG_HOME/dwm'. Use force-flag to install 'dwm'
even if already installed. A 'dwm.desktop' file is
copied into '/usr/share/xsessions' registering dwm with
your login-manager."
    exit 0
  elif [ -z "$(command -v dwm)" ] || [ "$1" = "--force" ]; then
    loglnprefix "dwm" "Installing 'dwm' from source ..."
    cd /tmp
    rm -rf suckless
    git clone https://github.com/slavistan/suckless.git
    cd suckless/dwm
    make clean
    please make install

    loglnprefix "dwm" "Symlinking './dwm/*' to '~/.config/dwm/' ..."
    rm -rf "$XDG_CONFIG_HOME/dwm"
    mkdir -p "$XDG_CONFIG_HOME/dwm"
    ln -s "$DOTFILES/dwm/autostart.sh" "$XDG_CONFIG_HOME/dwm"
    ln -s "$DOTFILES/dwm/autostart-blocking.sh" "$XDG_CONFIG_HOME/dwm"

    loglnprefix "dwm" "Copying 'dwm/dwm.desktop' to '/usr/share/xsessions' ..."
    please cp -f $DOTFILES/dwm/dwm.desktop /usr/share/xsessions

    loglnprefix "dwm" "... done installing 'dwm'."
  else
    loglnprefix "dwm" "Nothing to do."
  fi
}
