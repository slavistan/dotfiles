#!/usr/bin/env sh

# This script controls the appearance and visibility of the floating
# st terminal window which I use for file management with lf.

findme() {
  # retrieve pid of running instance of this script. Assumes it was invoked
  # without parameters and via '/usr/bin/env sh'.
  pgrep -a -f "$0" | cat
  echo matching ...
  pgrep -a -f "$0" | grep -o '^[0-9]\+ sh \S*fileman.sh$' | cut -d ' ' -f 1
}

case "$1" in
  findme)
    findme
    ;;
  start)
  st -n st-float -t st-filemgmt
    ;;
  toggle)
  ;;
  kill)
  ;;
  *)
    echo "mah pid os $$" > /dev/pts/0
  while :; do date '+%H:%M:%S' > /dev/pts/0 && sleep 1; done
  ;;
esac


# make invisible
# xdotool windowunmap
# make visible
# xdotool windowmap

