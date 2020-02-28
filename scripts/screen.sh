#!/usr/bin/env sh

if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
  printf "\
Usage:
  (1) $0

Returns connected monitors as newline-sep'd list.
"
exit 0
fi

# Display screens left-to-right
if [ -z "$1" ]; then
  xrandr -q | grep -F " connected" | awk '{ print $1 }'
fi
