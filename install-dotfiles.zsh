#!/bin/zsh

# TODO: use bash to run this script and install zsh along the way
# TODO: Move install_abc() function into their respective submodule's directory.
set -e # abort on error

setopt +o nomatch # disable errors from empty globs

THISFILE="$0"

# Clone submodules (which I always forget)
# git submodule init
# git submodule update

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
    printf "Exiting. Nothing done.\n"
    exit 0
  else
    printf "Continuing installation.\n"
  fi

  get_sudo_pw

  # install_prerequisites
  # install_environment
  # install_xkb
  install_zsh
  # install_nvim
  # install_st
  # install_dmenu
  # install_light
  # install_compton
  # install_flashfocus
  # install_i3 --force
  # install_nvidia
}

install_prerequisites() {
  if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    printf "\
Usage:
  $0

Installs many basic packages using apt."
    exit 0
  fi
  loglnprefix "prereq" "Setting up prerequisites ..."
  please apt install -y git cmake libtool libtool-bin autogen fontconfig \
  libfreetype6-dev libx11-dev libxft-dev libxcb1-dev libxcb-keysyms1-dev \
  libpango1.0-dev libxcb-util0-dev libxcb-icccm4-dev libyajl-dev \
  libstartup-notification0-dev libxcb-randr0-dev libev-dev libxcb-cursor-dev \
  libxcb-xinerama0-dev libxcb-xkb-dev libxkbcommon-dev libxkbcommon-x11-dev \
  autoconf xutils-dev libtool automake libxcb-xrm0 libxcb-shape0-dev \
  fonts-powerline fonts-inconsolata fonts-symbola \
  fonts-font-awesome libxinerama-dev copyq libnotify-dev libnotify-bin \
  notification-daemon notify-osd yad xdotool imagemagick feh compton \
  htop hub libxcb-render0-dev libffi-dev python-dev python-cffi python-pip \
  redshift vifm sshfs curlftpfs fuse fuse-zip fusefat fuseiso libncurses-dev \
  weechat youtube-dl entr fonts-hack-ttf pandoc exa
  loglnprefix "prereq" "... done setting up prerequisites."
}

install_environment() {
  if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    printf "\
Usage:
  $0

Writes environment variables to $HOME/.profile to be loaded
during startup."
    exit 0
  fi
  # TODO: Use $HOME instead of full paths. This make this setup reusable on
  #       other machines
  loglnprefix "env" "Setting up environment ..."
  addln "export XDG_CONFIG_HOME=$XDG_CONFIG_HOME" "$HOME/.profile"
  addln "export XDG_CACHE_HOME=$XDG_CACHE_HOME" "$HOME/.profile"
  addln "export XDG_DATA_HOME=$XDG_DATA_HOME" "$HOME/.profile"
  addln 'export LANG=en_US.utf8' "$HOME/.profile"
  addln 'export TZ="Europe/Berlin"' "$HOME/.profile"
  addln "export DOTFILES=$DOTFILES" "$HOME/.profile"

  # Add WSL-specific environment
  if [ ! -z $(command -v wslpath) ]; then
    addln 'export DISPLAY=localhost:0.0' "$HOME/.profile"
  fi

  loglnprefix "env" "... done setting up environment."
}

install_xkb() {
  if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    printf "\
Usage:
  $0

Creates symlink of './xkb/symbols/stan' in '/usr/share/X11/xkb/symbols'."
    exit 0
  fi
  logln 'Setting up xkb...'
  cd /usr/share/X11/xkb/symbols/
  please ln -fs $DOTFILES/xkb/symbols/stan
  logln '... done settings up xkb.'
}

install_zsh() {
  if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    printf "\
Usage:
  $0

Symlinks './zsh' into '$XDG_CONFIG_HOME/zsh' and sets up
envvars. Expects 'zsh' to be installed."
    exit 0
  fi
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
  loglnprefix "zsh" "... done installing 'zsh'"
}

install_nvim() {
  if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    printf "\
Usage:
  $0 [--force]

Installs 'nvim' from source, install plugins and sets up
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
    rm -rf $DOTFILES/nvim/plug_plugins/*/
    rm -rf $XDG_CONFIG_HOME/nvim
    mkdir -p $XDG_CONFIG_HOME
    cd $XDG_CONFIG_HOME
    ln -s $DOTFILES/nvim
    nvim +PlugClean +PlugInstall +quitall
    addln "export EDITOR=nvim" "$HOME/.profile"
    loglnprefix "nvim" "... done installing 'st'."
  else
    loglnprefix "nvim" "Nothing to be done."
  fi
}

install_st() {
  if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    printf "\
Usage:
  $0 [--force]

Installs 'st', suckless' simple terminal from source. Use
the force-flag to reinstall even if 'st' is already
installed."
    exit 0
  elif [ -z "$(command -v st)" ] || [ "$1" = "--force" ]; then
    loglnprefix "st" "Installing 'st' from source ..."
    cd /tmp
    rm -rf st
    git clone https://github.com/slavistan/st.git
    cd st
    make clean
    please make install
    loglnprefix "st" "Exporting TERMINAL envvar to '$HOME/.profile'."
    addln "export TERMINAL=$(command -v st)" $HOME/.profile
    loglnprefix "st" "... done installing 'st'."
  else
    loglnprefix "st" "Nothing to be done."
  fi
}

install_dmenu() {
  if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    printf "\
Usage:
  $0 [--force]

Installs customized 'dmenu' from source. Use force-flag to
reinstall even if 'dmenu' is already installed."
    exit 0
  elif [ -z "$(command -v dmenu)" ] || [ "$1" = "--force" ]; then
    loglnprefix "dmenu" "Installing 'dmenu' from source."
    cd /tmp
    rm -rf dmenu
    git clone https://github.com/slavistan/dmenu.git
    cd dmenu
    make clean
    please make install
    loglnprefix "dmenu" "... done installing 'dmenu'."
  else
    loglnprefix "dmenu" "Nothing to be done."
  fi
}

install_light() {
  if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    printf "\
Usage:
  $0 [--force]

Installs 'light', a backlight control and alternative to
'xbacklight' which doesn't work on Ubuntu. Use force-flag
to reinstall even if 'light' is already installed."
    exit 0
  elif [ -z "$(command -v light)" ] || [ "$1" = "--force" ]; then
    loglnprefix "light" "Installing 'light' from source ..."
    cd /tmp
    rm -rf light
    git clone https://github.com/haikarainen/light.git
    cd light
    ./autogen.sh
    ./configure && make
    please make install
    loglnprefix "light" "... done installing 'light'."
  else
    loglnprefix "light" "Nothing to be done."
  fi
}

install_compton() {
  if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    printf "\
Usage:
  $0

Symlinks './compton' to '$XDG_CONFIG_HOME/compton'."
    exit 0
  fi
  logln 'Setting up compton ...'
  rm -rf $XDG_CONFIG_HOME/compton
  mkdir -p $XDG_CONFIG_HOME
  cd $XDG_CONFIG_HOME
  ln -s $DOTFILES/compton
  logln '... done setting up compton.'
}

install_sxhkd() {
  if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    printf "\
Usage:
  $0

Symlinks ./sxhkd/sxhkdrc into $XDG_CONFIG_HOME/sxhkd."
    exit 0
  fi
}

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

# Setup nvidia graphics card related settings
install_nvidia() {
  if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    printf "\
Usage:
  $0

Setup nvidia graphics card related settings."
    exit 0
  fi

  logln "Setting up nvidia settings ..."
  addln "export __GL_SHADER_DISK_CACHE_PATH=$XDG_CACHE_HOME" $HOME/.profile
  logln "... done setting up nvidia settings."
}

# TODO: Configure systemd to ignore the corresponding events
install_acpi() {
  if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    printf "\
Usage:
  $0

TODO"
    exit 0
  fi

  please rm -rf /etc/acpi/events /etc/acpi/actions
  please cp -r $DOTFILES/acpi/events /etc/acpi
  please cp -r $DOTFILES/acpi/actions /etc/acpi
}

###########
## Misc
###########
# Makes jupyter use XDG paths
install_misc() {
  if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    printf "\
Usage:
  $0

Miscellaneous. See source code."
    exit 0
  fi
  addln "export JUPYTER_CONFIG_DIR=$XDG_CONFIG_HOME/jupyter" $HOME/.profile
}

logln() {
  printf "\033[32m[INFO]\033[0m $@\n"
}

loglnprefix() {
  pre="$1"
  shift
  printf "\033[32m[$pre]\033[0m $@\n"
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

get_sudo_pw() {
  # Store sudo password for later usage.
  read -s "pw?> Enter your sudo password: "
  sudo -kSp '' true <<<"${pw}" > /dev/null 2>&1
  if [[ "$?" != "0" ]]; then
    echo 'Invalid password. Abort.'
    exit 1
  fi
  echo 'OK.'
}

please() {
  sudo -Sp '' "$@" <<<${pw}
}

getmodules() {
  sed -n -e 's/^\s*install_\([^(]*\)().*$/\1/gp' "$THISFILE"
}

# TODOS:
# acpi
# notify-send styling
# dropbox
#

# 1. Keine Argumente -> Interaktiv
# 2. --module zsh --help
if [ -z "$1" ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
  printf "\
Usage:
  (1) $0 --list-modules
  (1) $0 -l
  (2) $0 -m <module> <args>

List available modules (1) or run a module (2).
"
  exit 0
elif [ "$1" = "-l" ] || [ "$1" = "--list-modules" ]; then
  for mod in $(getmodules)
  do
    help=$(install_$mod -h | sed 's@install_@'"$THISFILE"' -m @g' | sed -ne 's/^/  /gp')
    printf "$mod\n$help\n\n"
  done
elif [ "$1" = "-m" ]; then
  get_sudo_pw
  mod="$2"
  shift 2
  install_$mod "$@"
fi
