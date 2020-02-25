install_i3() {
  if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    printf "\
Usage:
  $0

Installs i3 and i3-blocks from source."
    exit 0
  fi

  logln 'Setting up i3 ...'
  if [ -z "$(command -v i3)" ] || [ "$1" = "--force" ]; then
    logln 'i3 not found. Installing i3 with gaps corners from source ...'
    cd /tmp
    rm -rf i3
    git clone https://github.com/Airblader/i3
    cd i3
    git checkout gaps && git pull
    autoreconf --force --install
    rm -rf build
    mkdir build
    cd build
    ../configure --prefix=/usr --sysconfdir=/etc --disable-sanitizers
    make
    please make install
  fi
  if [ -z "$(command -v i3blocks)" ]; then
    logln 'i3blocks not found. Installing from source ...'
    cd /tmp
    rm -rf i3blocks
    git clone https://github.com/vivien/i3blocks
    cd i3blocks
    ./autogen.sh
    ./configure
    make
    make install
  fi
  rm -rf $XDG_CONFIG_HOME/i3
  ln -sT $DOTFILES/i3 $XDG_CONFIG_HOME/i3
  logln '... done setting up i3.'
}

