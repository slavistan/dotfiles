#!/usr/bin/env sh

if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
  printf "\
Usage: $0 area
"
  exit
fi

if [ "$1" = "area" ]; then
  outfile=$(mktemp --tmpdir=/tmp --suffix=.png snapshot_XXXXX)
  import -display :0 $outfile
  if [ ! $(ls -l $outfile | awk '{ print $5 }') = "0" ]; then
    copyq copy image/png - < $outfile
    notify-send -i $outfile "Saved to $outfile"
  else
    notify-send "Abort."
  fi
  exit 0
fi
