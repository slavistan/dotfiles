#!/usr/bin/env sh

if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
  printf "\
Usage: $0 <SIGNAL>

Sends signal <SIGNAL> to currently focused X window."
  exit 0
fi

pid=$(xdotool getwindowpid $(xdotool getwindowfocus))
kill -s "$1" "$pid"
