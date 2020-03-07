#!/usr/bin/env sh

battery() {
  for p in /sys/class/power_supply/BAT?/capacity; do
    echo "$(cat $p)%"
  done
}

power() {
  for p in /sys/class/power_supply/ADP?/online; do
    if [ $(cat $p) = "1" ]; then
      printf ⚡
    else
      printf 🔋
    fi
  done
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
