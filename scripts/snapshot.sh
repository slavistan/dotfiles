#!/usr/bin/env sh

if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
  printf "\
Usage: $0 area
"
  exit
fi

if [ "$1" = "area" ]; then
  outfile=$(mktemp --tmpdir=/tmp --suffix=.png snapshot_XXXXX)
  gnome-screenshot --file=$outfile --area
  copyq copy image/png - < $outfile
  notify-send "Saved to $outfile"
  exit 0
fi
