#!/usr/bin/env zsh

set -e

mons="$(xrandr -q | grep -F " connected" | awk '{ print $1 }' | sort)"
if [ "$(hostname -s)" = "Berenice" ]; then

  OFFICE="DP-1-1-8\nDP-1-2\neDP-1"

  if [ -z "$(comm -3 <(echo "$mons") <(echo "$OFFICE"))" ]; then
    notify-send "Monitors: 🖳 🖵 🖵 " &
    xrandr --output "DP-1-2" --off
    xrandr --output "DP-1-1-8" --off
    xrandr --auto
    xrandr --output "DP-1-2" --right-of "eDP-1"
    xrandr --output "DP-1-1-8" --right-of "DP-1-2"
  elif [ $(echo "$mons" | wc -l) -eq 1 ]; then
    xrandr --auto
  else
    arandr &
  fi
elif [ "$(hostname -s)" = "Mortimer" ]; then

  if echo "$mons" | grep -i hdmi; then
    xrandr --auto
    xrandr --output "HDMI-1-1" --right-of "eDP-1-1"
  elif [ $(echo "$mons" | wc -l) -eq 1 ]; then
    xrandr --auto
  else
    arandr &
  fi
else
  arandr &
fi
