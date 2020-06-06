#!/usr/bin/env zsh

__install_prerequisites() {
  if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    printf "\
Usage:
  $0

Installs many basic packages."
    exit 0
  fi
  loglnprefix "prereq" "Setting up prerequisites ..."
  please apt install -y git cmake curl libtool libtool-bin autogen fontconfig \
  i3lock libfreetype6-dev libx11-dev libxft-dev libxcb1-dev libxcb-keysyms1-dev \
  libpango1.0-dev libxcb-util0-dev libxcb-icccm4-dev libyajl-dev \
  libstartup-notification0-dev libxcb-randr0-dev libev-dev libxcb-cursor-dev \
  libxcb-xinerama0-dev libxcb-xkb-dev libxkbcommon-dev libxkbcommon-x11-dev \
  autoconf xutils-dev libtool automake libxcb-xrm0 libxcb-shape0-dev \
  fonts-powerline fonts-inconsolata fonts-symbola python3-pip \
  libxinerama-dev copyq libnotify-dev libnotify-bin \
  notification-daemon notify-osd yad xdotool imagemagick feh compton \
  htop hub libxcb-render0-dev libffi-dev python-dev python-cffi python-pip \
  redshift vifm sshfs curlftpfs fuse fuse-zip fusefat fuseiso libncurses-dev \
  weechat youtube-dl entr fonts-hack-ttf pandoc exa xclip expect-dev

  loglnprefix "prereq" "Installing fonts ..."
  tmp=$(mktemp -d)
  cd $tmp
  wget -O Hack.zip "https://github.com/source-foundry/Hack/releases/download/v3.003/Hack-v3.003-ttf.zip"
  unzip Hack.zip
  cd ./ttf
  please mkdir -p /usr/share/fonts/truetype/hack-nerdfonts
  please cp -f ./*.ttf /usr/share/fonts/truetype/hack-nerdfonts
  fc-cache -rfv

  loglnprefix "prereq" "Installing xcwd from source ..."
  tmp=$(mktemp -d)
  git clone https://github.com/schischi/xcwd.git $tmp
  cd $tmp
  please make install

  loglnprefix "prereq" "... done setting up prerequisites."
}

__install_environment() {
  if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    printf "\
Usage:
  $0

Writes environment variables to $HOME/.profile to be loaded
during startup. Configures XDG_.. paths and locale."
    exit 0
  fi
  loglnprefix "env" "I will set the following exports in '~/.profile':"
  loglnprefix "env" "  XDG_DATA_HOME=\"$XDG_DATA_HOME\""
  loglnprefix "env" "  XDG_CONFIG_HOME=\"$XDG_CONFIG_HOME\""
  loglnprefix "env" "  XDG_CACHE_HOME=\"$XDG_CACHE_HOME\""
  loglnprefix "env" "  DOTFILES=\"$DOTFILES\""
  read -qs "reply?> Continue? [Y/n]: "
  if [ ! "$reply" = "y" ]; then
    printf "Exiting. Nothing done.\n"
    exit 0
  else
    printf "Continuing installation.\n"
  fi
  loglnprefix "env" "Setting up environment ..."
  addln "export XDG_CONFIG_HOME=$XDG_CONFIG_HOME" "$HOME/.profile"
  addln "export XDG_CACHE_HOME=$XDG_CACHE_HOME" "$HOME/.profile"
  addln "export XDG_DATA_HOME=$XDG_DATA_HOME" "$HOME/.profile"
  addln "export BROWSER=$(command -v firefox)" "$HOME/.profile"
  addln 'export LANG=en_US.utf8' "$HOME/.profile"
  addln 'export MANPAGER=less' "$HOME/.profile"
  addln 'export PAGER=cat' "$HOME/.profile"
  addln 'export TZ="Europe/Berlin"' "$HOME/.profile"
  addln 'export LC_NUMERIC="C"' "$HOME/.profile" # make printf floats use '.' instead of ','
  addln "export DOTFILES=$DOTFILES" "$HOME/.profile"
  addln '[ -d "$DOTFILES/scripts" ] && export PATH="$DOTFILES/scripts:$PATH"' "$HOME/.profile"

  # Add WSL-specific environment
  if [ ! -z $(command -v wslpath) ]; then
    addln 'export DISPLAY=localhost:0.0' "$HOME/.profile"
  fi

  loglnprefix "env" "... done setting up environment."
}

__install_dmenu() {
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

__install_light() {
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


## Preset functions

# log with info tag

logln() {
  printf "\033[32m[INFO]\033[0m $@\n"
}


# log with err tag

errln() {
  printf "\033[31m[ERR ]\033[0m $@\n"
}


# log with arbitrary tag

loglnprefix() {
  printf "\033[32m[$1]\033[0m "
  shift
  printf "$@\n"
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


# query for sudo pw and store in SUDOPW

get_sudo_pw() {
  # Store sudo password for later usage.
  read -s "SUDOPW?> Enter your sudo password: "
  sudo -kSp '' true <<<"${SUDOPW}" > /dev/null 2>&1
  if [[ "$?" != "0" ]]; then
    echo 'Invalid password. Abort.'
    exit 1
  fi
  echo 'OK.'
}


# sudo using pw from $SUDOPW

please() {
  # Prompts user for sudo pw only if needed.
  prompt=$(sudo -nv > /dev/null 2>&1)
  reply="$?"
  if [ ! "$reply" -eq 0 ]; then
    get_sudo_pw
  fi
  sudo -Sp '' "$@" <<<${SUDOPW}
}


# change into directory and silently create it if necessary

mkcd() {
  mkdir -p "$1" && cd "$1"
}


# list all modules which may be installed

list_available_modules() {
  # Search all installer files for functions whose names match the
  # expression '__installer_.*'. Return the name without the prefix.
  mods=""
  for file in $(printf "$INSTALLER_FILES\n$THISFILE"); do
    mods=$(printf "$(sed -n -e 's/^\s*__install_\([^(]*\)().*$/\1/gp' $file)\n$mods")
  done
  printf "$mods\n" | sort
}


# list all installer files

list_installer_files() {
  # Lists files whose names match './*/install-.*sh'. These files will be
  # searched for aptly named shell functions ("modules").
  installer_files=""

  for subdir in $(find "./" -maxdepth 1 -regextype sed -regex './[^.]*' -type d); do
    for file in $(find $subdir -maxdepth 1 -regextype sed -type f -regex "$subdir"'/install-.*sh'); do
      installer_files="$file\n$installer_files"
    done
  done
  printf "$installer_files"
}


# create module template

make_template() {
  set -e
  if ! echo "$1" | grep -E '^[a-zA-Z0-9_-]+$' > /dev/null || [ -d "$1" ]; then
    echo "Module exists or the name sucks. Abort."
    exit 1
  fi

  cp -r template "$1"
  sed -i 's/template/'"$1"'/g' "$1"/install-template.zsh
  mv "$1"/install-template.zsh "$1"/install-"$1".zsh
}

##########################
######### Start ##########
##########################

THISFILE="${0:A}"
THISDIR="${0:A:h}"
cd $THISDIR
INSTALLER_FILES=$(list_installer_files)
SUDOPW=""

export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export DOTFILES="$THISDIR"

for file in $(echo $INSTALLER_FILES); do
  source $file
done
source $(echo $INSTALLER_FILES)
git submodule init
git submodule update

if [ -z "$1" ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
  printf "\
Usage:
  (1) $0 --list-modules | -l
  (2) $0 -m <module> <args>
  (3) $0 --template | -t <name>
  (4) $0 -- <args> ...
  (5) $0 --help | -h

List available modules (1) or run a module (2). (3) Setup template for new
module. Use double dashes (4) to run script commands directly for debugging or
print this help (5).
"
  exit 0
elif [ "$1" = "-l" ] || [ "$1" = "--list-modules" ]; then
  for mod in $(list_available_modules)
  do
    help=$(__install_$mod -h | sed 's@__install_@'"$THISFILE"' -m @g' | sed -ne 's/^/  /gp')
    printf "Module \033[32;1m$mod\033[0m\n$help\n\n"
  done
elif [ "$1" = "-m" ]; then
  mod="$2"
  shift 2
  __install_$mod "$@"
elif [ "$1" = "-t" ] || [ "$1" = "--template" ]; then
  make_template "$2"
elif [ "$1" = "--" ]; then
  shift
  "$@"
fi

# TODOS:
# notify-send styling / anderen daemon
# dropbox: https://linoxide.com/linux-how-to/install-dropbox-ubuntu/
# rmln (Pendant zu addln) für --uninstalls
