#!/usr/bin/env sh
if [ "$1" = "" ] || [ "$2" = "" ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
  printf "\
Usage: $0 <window-id> <key>

Send a key to a window without losing your current focus. Light wrapper
around 'xdotool'.
"
  exit 1
fi

winid="$1"
key="$2"
current_wid=$(xdotool getactivewindow)
xdotool windowactivate "$winid"
xdotool key "$key"
xdotool windowactivate "$current_wid"
