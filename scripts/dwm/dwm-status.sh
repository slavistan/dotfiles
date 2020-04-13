#!/usr/bin/env sh

battery() {
  for p in /sys/class/power_supply/BAT?/capacity; do
    echo "$(cat $p)%"
  done
}

power() {
  device=$(ls /sys/class/power_supply/ | grep -v 'BAT')
  [ "$(cat /sys/class/power_supply/$device/online)" -eq 1 ] && printf ⚡|| printf 🔋
}

time() {
  date '+%d. %B %H:%M'
}

status() {
  echo "$(power) $(battery) | $(time)"
}

if [ ! "$#" -eq 0 ]; then
  $@
else
  while :; do

    xsetroot -name "$(status | tr '\n' ' ')"

    sleep 1m
  done
fi
