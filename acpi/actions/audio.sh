#!/bin/sh

if [ $1 = "unplug" ]; then
  notify-send "Audio jack unplugged"
  exit 0
fi

if [ $1 = "plug" ]; then
  notify-send "Audio jack plugged in"
fi
