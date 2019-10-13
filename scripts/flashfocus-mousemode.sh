#!/usr/bin/env sh
#
# Periodically checks whether the cursor moved and halts the flashfocus process
# to avoid irritating flashes when using the mouse. The process is resumed
# after the cursor was found not moving.

PERIOD_IN_SECONDS=0.5

loc=$(xdotool getmouselocation)
x=$(echo $loc | awk -F '[:, ]' '{ print $2 }')
y=$(echo $loc | awk -F '[:, ]' '{ print $4 }')

while true; do
  sleep $PERIOD_IN_SECONDS
  loc=$(xdotool getmouselocation)
  x_new=$(echo $loc | awk -F '[:, ]' '{ print $2 }')
  y_new=$(echo $loc | awk -F '[:, ]' '{ print $4 }')

  if [ "$x" = "$x_new" ] && [ "$y" = "$y_new" ]; then
    pkill -CONT flashfocus
  else
    pkill -STOP flashfocus
  fi
  x="$x_new"
  y="$y_new"
done

