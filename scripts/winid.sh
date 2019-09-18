#!/usr/bin/env sh
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
  printf "\
Usage: $0

Select a window with the cursor to retrieve its window id.
"
  exit 0
fi
xwininfo -int |
  grep "xwininfo: Window id: " |
  awk '{ print $4 }'
