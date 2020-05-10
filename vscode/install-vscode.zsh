__install_vscode() {
  if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    printf "\
Usage:
  $0 [--force]
  $0 [--config-only]

  Install Visual Studio Code.
"
    exit 0
  elif [ -z "$(command -v vscode)" ] || [ "$1" = "--force" ]; then

    loglnprefix "vscode" "Installing 'vscode' ..."
    mkcd ~/bin/
    rm -rf $(ls | grep -i vscode)
    wget -O - "https://go.microsoft.com/fwlink/?LinkID=620884" | tar -xzf -
    ln -fs $(ls | grep -i vscode)/code vscode

    loglnprefix "vscode" "Installing user configuration files ..."
    mkcd ~/.config/Code/User/
    ln -fs $DOTFILES/vscode/keybindings.json
    ln -fs $DOTFILES/vscode/settings.json

    loglnprefix "vscode" "... done installing 'vscode'."
  elif [ "$1" = "--config-only" ]; then

    loglnprefix "vscode" "Installing user configuration files ..."
    mkcd ~/.config/Code/User/
    ln -fs $DOTFILES/vscode/keybindings.json
    ln -fs $DOTFILES/vscode/settings.json

  else
    loglnprefix "vscode" "Nothing to do."
  fi
}
