#!/usr/bin/env sh

if [ -z "$1" ]; then
  xrandr -q | grep -F " connected" | awk '{ print $1 }'
  exit 0
fi

if [ "$1" = "--align" ] || [ "$1" = "-a" ]; then
  lscr=$(./$0 | dmenu -p "Left: ")
  rscr=$(./$0 | dmenu -p "Right: ")
  xrandr --output $lscr --left-of $rscr --auto
fi

