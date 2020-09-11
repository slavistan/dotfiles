#!/usr/bin/env sh

WALLPAPERS=~/dat/img/wallpaper/
DISPATCHER=~/dat/img/wall

case "$1" in
  -r|--random)
    [ -d "$WALLPAPERS" ] || exit 1
    new="$(find "$WALLPAPERS" -type f -print0 | shuf -z | head -1 -z | tr -d '\0')"
    ln -sf "$(realpath $new)" "$(realpath $DISPATCHER)"
    exec $0
    ;;
  *) # reload current
    feh --bg-scale "$DISPATCHER"
    ;;
esac

