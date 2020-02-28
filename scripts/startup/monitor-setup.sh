#!/usr/bin/env zsh

# If we're in the office align the outputs properly.

xrandr --auto
mons=$(xrandr -q | grep -F " connected" | awk '{ print $1 }' | sort)
office_mons="DP-1-1-8\nDP-1-2\neDP-1"

if [ -z $(comm -3 <(echo "$mons") <(echo "$office_mons")) ]; then
  echo "Found office setup:🖳 🖵 🖵 "
  xrandr --output "DP-1-2" --right-of "eDP-1"
  xrandr --output "DP-1-1-8" --right-of "DP-1-2"
else
  echo "Did not find preset setup. Launching arandr."
  arandr &
fi

