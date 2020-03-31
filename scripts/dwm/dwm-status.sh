#!/usr/bin/env sh

battery() {
  for p in /sys/class/power_supply/BAT?/capacity; do
    echo "$(cat $p)%"
  done
}

power() {
   [ $(cat /sys/class/power_supply/AC/online) -eq 1 ] && printf ⚡|| printf 🔋
}

time() {
  date '+%d. %B %H:%M'
}

status() {
  echo "$(power) $(battery) | $(time)"
}

while :; do

  xsetroot -name "$(status | tr '\n' ' ')"

  sleep 1m
done
