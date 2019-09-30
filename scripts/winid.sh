#!/usr/bin/env sh
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
  printf "\
Usage: $0

Select a window with the cursor to retrieve its window id.
"
  exit 0
fi

winid=$(xwininfo -int          |
  grep "xwininfo: Window id: " |
  awk '{ print $4 }')
printf "$winid\n"
printf "$winid\n" | xclip -selection clipboard
notify-send "Added to clipboard"
