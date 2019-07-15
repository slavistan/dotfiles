#!/usr/bin/env sh

if [ "$1" = "selection" ]; then
  outfile=$(mktemp --tmpdir=/tmp --suffix=.png snapshot_XXXXX)
  gnome-screenshot --file=$outfile --area
  copyq copy image/png - < $outfile
  notify-send "Saved to $outfile"
  exit 0
fi

