#!/bin/zsh

# TODO: use bash to run this script and install zsh along the way
set -e # abort on error

setopt +o nomatch # disable errors from empty globs

# Clone submodules (which I always forget)
git submodule init
git submodule update

main() {
  [ -z "$XDG_DATA_HOME" ] && XDG_DATA_HOME="$HOME/.local/share"
  [ -z "$XDG_CONFIG_HOME" ] && XDG_CONFIG_HOME="$HOME/.config"
  [ -z "$XDG_CACHE_HOME" ] && XDG_CACHE_HOME="$HOME/.cache"
  DOTFILES=$(realpath $(dirname $0))

  temp=$(mktemp -d)
  logln "I will work with the following variables:"
  logln "  XDG_DATA_HOME=\"$XDG_DATA_HOME\""
  logln "  XDG_CONFIG_HOME=\"$XDG_CONFIG_HOME\""
  logln "  XDG_CACHE_HOME=\"$XDG_CACHE_HOME\""
  logln "  DOTFILES=\"$DOTFILES\""
  read -qs "reply?> Continue? [Y/n]: "
  if [ ! "$reply" = "y" ]; then
    logln "Exiting. Nothing done."
    exit 0
  else
    logln "Continuing installation."
  fi
  
  # Store sudo password for later usage.
  read -s "pw?> Enter your sudo password: "
  sudo -kSp '' true <<<"${pw}" > /dev/null 2>&1
  if [[ "$?" != "0" ]]; then
    echo 'Invalid password. Abort.'
    exit 1
  fi
  echo 'OK.'

  setup_prerequisites
  setup_environment
  setup_xkb
  setup_zsh
  setup_nvim
  setup_st
  setup_i3
}

setup_prerequisites() {
  logln 'Setting up prerequisites...'
  please apt install -y git cmake libtool libtool-bin autogen fontconfig \
  libfreetype6-dev libx11-dev libxft-dev libxcb1-dev libxcb-keysyms1-dev \
  libpango1.0-dev libxcb-util0-dev libxcb-icccm4-dev libyajl-dev \
  libstartup-notification0-dev libxcb-randr0-dev libev-dev libxcb-cursor-dev \
  libxcb-xinerama0-dev libxcb-xkb-dev libxkbcommon-dev libxkbcommon-x11-dev \
  autoconf xutils-dev libtool automake libxcb-xrm0 libxcb-shape0-dev \
  fonts-powerline dmenu fonts-inconsolata fonts-hack fonts-symbola
  logln '... done setting up prerequisites.'
}

setup_environment() {
  logln 'Setting up environment...'
  addln "export XDG_CONFIG_HOME=$XDG_CONFIG_HOME" "$HOME/.profile"
  addln 'export LANG=en_US.utf8' "$HOME/.profile"
  addln 'export TZ="Europe/Berlin"' "$HOME/.profile"
  addln "export DOTFILES=$DOTFILES" "$HOME/.profile"

  # Add WSL-specific environment
  if [ ! -z $(command -v wslpath) ]; then
    addln 'export DISPLAY=localhost:0.0' "$HOME/.profile"
  fi

  logln '... done setting up environment.'
}

setup_xkb() {
  logln 'Setting up xkb...'
  cd /usr/share/X11/xkb/symbols/
  please ln -fs $DOTFILES/xkb/symbols/stan
  addln 'setxkbmap -layout stan' $HOME/.profile
  logln '... done settings up xkb.'
}

setup_zsh() {
  logln 'Setting up zsh...'
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
  logln '... done setting up zsh.'
}

setup_nvim() {
  logln 'Setting up nvim ...'
  if [ -z "$(command -v nvim)" ]; then
    logln 'nvim not found. Installing from source...'
    cd /tmp/
    rm -rf neovim
    git clone https://github.com/neovim/neovim.git
    cd neovim
    make CMAKE_BUILD_TYPE=RelWithDebInfo
    sudo make install
  fi

  rm -rf $DOTFILES/nvim/plug_plugins/*/
  rm -rf $XDG_CONFIG_HOME/nvim
  mkdir -p $XDG_CONFIG_HOME
  cd $XDG_CONFIG_HOME
  ln -s $DOTFILES/nvim
  nvim +PlugClean +PlugInstall +quitall
  addln "export EDITOR=nvim" "$HOME/.profile"
  logln '... done setting up nvim.'
}

setup_st() {
  logln 'Setting up st ...'
  if [ -z "$(command -v st)" ]; then
    logln 'st not found. Installing from source...'
    mkdir -p $temp/st
    git clone https://github.com/slavistan/st.git $temp/st
    cd $temp/st
    please make clean install
  fi
  addln "export TERMINAL=$(command -v st)" $HOME/.profile
  logln '... done setting up st.'
}

setup_i3() {
  logln 'Setting up i3 ...'
  if [ -z "$(command -v i3)" ]; then
    logln 'i3 not found. Installing i3-gaps from source ...'
    cd /tmp
    rm -rf i3
    git clone https://www.github.com/Airblader/i3
    cd i3
    git checkout gaps && git pull
    autoreconf --force --install
    rm -rf build
    mkdir build
    cd build
    ../configure --prefix=/usr --sysconfdir=/etc --disable-sanitizers
    make
    sudo make install
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


# TODO: Configure systemd to ignore the corresponding events
setup_acpi() {
  please rm -rf /etc/acpi/events /etc/acpi/actions
  please cp -r $DOTFILES/acpi/events /etc/acpi
  please cp -r $DOTFILES/acpi/actions /etc/acpi
}

###########
## Misc
###########
# Makes jupyter use XDG paths
setup_misc() {
  addln "export JUPYTER_CONFIG_DIR=$XDG_CONFIG_HOME/jupyter" $HOME/.profile
  # TODO: Hack font + Powerline symbold
}

logln() {
  printf "\033[32m[INFO]\033[0m $@\n"
}

errln() {
  printf "\033[31m[ERR ]\033[0m $@\n"
}

# Add a line to a file iff the line is not part of the file.
addln() {
  if [ ! "$#" -eq 2 ]; then
    printf "addln requires 2 arguments.\n"
    exit 1
  fi
  if [ -z "$(grep $1 $2)" ]; then
    logln "Adding '$1' to file '$2'."
    printf "$1\n" >> "$2"
  fi
}

# sudo wrapper
please() {
  sudo -Sp '' "$@" <<<${pw}
}

main
