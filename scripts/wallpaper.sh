#!/usr/bin/env sh

WALLPAPERS=~/dat/img/wallpaper/
DISPATCHER=~/dat/img/wall # symlinked to currently active background image

_ls() {
  if [ "$1" = "-0" ]; then
    find "$WALLPAPERS" -type f -print0
  else
    find "$WALLPAPERS" -type f
  fi
}

_reload() {
  feh --bg-scale "$DISPATCHER"
}

case "$1" in
-r|--random)
  [ -d "$WALLPAPERS" ] || exit 1
  new="$(_ls -0 | shuf -z | head -1 -z | tr -d '\0')"
  cd "$(realpath "$(dirname $DISPATCHER)")"
  ln -sf "$(realpath $new)" "$(basename $DISPATCHER)"
  _reload
  ;;
-l|--list)
  shift
  _ls "$@"
  ;;
*) _reload ;;
esac
