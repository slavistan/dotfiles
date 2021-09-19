#!/usr/bin/env zsh

# log with arbitrary tag

loglnprefix() {
  printf "\033[32m[$1]\033[0m "
  shift
  printf "$@\n"
}

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

# sudo wrapper
please() {
  # Prompts user for sudo pw only if needed.
  prompt=$(sudo -nv > /dev/null 2>&1)
  reply="$?"
  if [ ! "$reply" -eq 0 ]; then
    get_sudo_pw
  fi
  sudo -Sp '' "$@" <<<${SUDOPW}
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

# TODO: Create .profile
# TODO: Assert that all envvars are set
# Split installation of binary from configuration
