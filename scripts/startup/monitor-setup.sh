#!/usr/bin/env zsh

set -e

mons="$(xrandr -q | grep -F " connected" | awk '{ print $1 }' | sort)"
if [ "$(hostname -s)" = "Berenice" ]; then

  OFFICE="DP-1-1-8\nDP-1-2\neDP-1"
  SOLO="eDP-1"

  if [ -z $(comm -3 <(echo "$mons") <(echo "$OFFICE")) ]; then
    notify-send "Monitors: 🖳 🖵 🖵 " &
    xrandr --output "DP-1-2" --off
    xrandr --output "DP-1-1-8" --off
    xrandr --auto
    xrandr --output "DP-1-2" --right-of "eDP-1"
    xrandr --output "DP-1-1-8" --right-of "DP-1-2"
  elif [ -z $(comm -3 <(echo "$mons") <(echo "$SOLO")) ]; then
    notify-send "Monitors: 🖳" &
    xrandr --auto
  else
    notify-send "Did not find preset setup. Launching arandr."
    arandr &
  fi
elif [ "$(hostname -s)" = "Mortimer" ]; then
  notify-send "Todo;"
  arandr &
fi
