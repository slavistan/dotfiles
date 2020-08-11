__install_nvim() {
  if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    printf "\
Usage:
  $0 [--force]

Installs 'nvim' from source, its plugins and sets up
config in '$XDG_CONFIG_HOME/nvim'. Use the force-flag to
install even if 'nvim' is already installed."

    exit 0
  elif [ -z "$(command -v nvim)" ] || [ "$1" = "--force" ]; then
    loglnprefix "nvim" "Installing 'nvim' from source ..."
    cd /tmp/
    rm -rf neovim
    git clone https://github.com/neovim/neovim.git
    cd neovim
    make CMAKE_BUILD_TYPE=RelWithDebInfo
    please make install
    loglnprefix "nvim" "Installing plugins and config ..."
    rm -rf $DOTFILES/nvim/plug_plugins
    mkdir $DOTFILES/nvim/plug_plugins
    rm -rf $XDG_CONFIG_HOME/nvim
    mkdir -p $XDG_CONFIG_HOME
    cd $XDG_CONFIG_HOME
    ln -s $DOTFILES/nvim
    nvim +PlugClean +PlugInstall +quitall
    addln "export EDITOR=nvim" "$HOME/.profile"
    loglnprefix "nvim" "... done installing 'nvim'."
  else
    loglnprefix "nvim" "Nothing to be done."
  fi
}
