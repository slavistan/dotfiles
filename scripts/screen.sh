#!/usr/bin/env sh

# Display screens left-to-right
if [ -z "$1" ]; then
  xrandr -q | grep -F " connected" | awk '{ print $1 }' | tr '\n' ' '
  echo
  exit 0
fi

if [ "$1" = "--align" ] || [ "$1" = "-a" ]; then
  choices=$(./$0)
  lscr=$(echo $choices | tr ' ' '\n' | dmenu -p "Left: ")
  rscr=$(echo $choices | tr ' ' '\n' | dmenu -p "Right: ")
  xrandr --output $lscr --left-of $rscr --auto
fi

