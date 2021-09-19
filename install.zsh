#!/usr/bin/env zsh


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
  addln "export XDG_CONFIG_HOME=$XDG_CONFIG_HOME" "$HOME/.profile" # TODO: Use literal $HOME
  addln "export XDG_CACHE_HOME=$XDG_CACHE_HOME" "$HOME/.profile"
  addln "export XDG_DATA_HOME=$XDG_DATA_HOME" "$HOME/.profile"
  addln "export BROWSER=$(command -v firefox)" "$HOME/.profile"
  addln 'export LANG=en_US.utf8' "$HOME/.profile"
  addln 'export MANPAGER=less' "$HOME/.profile"
  addln 'export PAGER=cat' "$HOME/.profile"
  addln 'export TZ="Europe/Berlin"' "$HOME/.profile" # TC and LC_NUMERIC should be set in /etc/locale.conf
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
  printf "\033[31m[ERR ]\033[0m $@\n" >&2
}

err() {
  printf "\033[31m[ERR ]\033[0m $@" >&2
}

die() {
  err "$@"
  exit 1
}


# log with arbitrary tag

loglnprefix() {
  printf "\033[32m[$1]\033[0m "
  shift
  printf "$@\n"
}


# Add a line to a file iff the line is not part of the file.
# TODO(feat): Rename to addlnq (add line unique)

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

module_exists() {
  list_available_modules | grep -Fq "$1"
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
MYNAME="${0:A:t}"
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

case "$1" in
-h|--help)
  if [ -z "$2" ]; then
    cat <<-EOF
			Usage:
			  (1) $0 -l                  - list available modules
			  (2) $0 -h [MODULE]         - show help
			  (3) $0 -m MODULE [ARGS]... - run a module
			  (4) $0 -t NAME             - create new module from template
			  (5) $0 @ COMMAND           - run script-internal commands (debugging)
			EOF
  else
   module_exists "$2" || die "Module does not exist.\n"
   __install_$2 -h | sed 's@__install_@'"$MYNAME"' -m @g'
  fi
  ;;
-l)
  for mod in $(list_available_modules)
  do
    help=$(__install_$mod -h | sed 's@__install_@'"$MYNAME"' -m @g' | sed -ne 's/^/  /gp')
    printf "Module \033[32;1m$mod\033[0m\n$help\n\n"
  done
  ;;
-m)
  mod="$2"
  shift 2
  __install_$mod "$@"
  ;;
-t)
  make_template "$2"
  ;;
@)
  shift
  "$@"
  ;;
esac

# TODO(feat): dropbox ersetzen
# TODO(feat): rmln (Pendant zu addln) für --uninstalls implementieren
# TODO(feat): mktempcd
# TODO(feat): Templates erweitern
#             (1) download, build from source, make install
# TODO(feat): logln sollte innerhalb jedes moduls automatisch Namespräfix generieren
#   ohne loglnprefix
#    - log ...
#    - err ...
#    - die ...
# TODO(feat): Implement -s, -i, -u semantics (see autorandr module)
# TODO: Create .profile
# TODO: Assert that all envvars are set
# Split installation of binary from configuration
