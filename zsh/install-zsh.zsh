__install_zsh() {
  if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    printf "\
Usage:
  $0 [-p]

Symlinks './zsh' into '$XDG_CONFIG_HOME/zsh' and sets up
envvars. Expects 'zsh' to be already installed."
    exit 0
  elif [ "$1" = "-p" ]; then
    loglnprefix "zsh" "Delete plugin directory"
    rm -rf $THISDIR/zsh/plugins
    loglnprefix "zsh" "Install plugins"

    mkcd "$THISDIR/zsh/plugins/zsh-syntax-highlighting"
    git clone "https://github.com/zsh-users/zsh-syntax-highlighting.git" .
  else
    loglnprefix "zsh" "Setting up zsh ..."
    if [ -z "$(command -v zsh)" ]; then
      errln 'zsh not found. Install zsh and rerun this script.'
      exit 1
    fi

    addln "export SHELL=/usr/bin/zsh" $HOME/.profile
    addln "export ZDOTDIR=$XDG_CONFIG_HOME/zsh" $HOME/.profile
    mkdir -p $XDG_CONFIG_HOME
    rm -rf $XDG_CONFIG_HOME/zsh
    cd $XDG_CONFIG_HOME
    ln -fs $DOTFILES/zsh

    mkdir -p $THISDIR/zsh/completions
    wget -O $THISDIR/zsh/completions/cf "https://raw.githubusercontent.com/cloudfoundry/cli/master/ci/installers/completion/cf"

    loglnprefix "zsh" "... done installing 'zsh'"
  fi
}
