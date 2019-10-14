#!/usr/bin/env sh
#
# Periodically checks whether the cursor moved and kills the flashfocus process
# to avoid irritating flashes when using the mouse. The process is restarted
# after the cursor was found not moving.
#
# Note that we cannot use STOP and CONT signals, as flashfocus triggers always
# flashes the active window when its process is continued.
#
# This script starts flashfocus itself, make sure its not running already.

PERIOD_IN_SECONDS=1.0

# Start flashfocus and store its pid
flashfocus &
pid=$(echo $!)

# Acquire mouse x and y
loc=$(xdotool getmouselocation)
x=$(echo $loc | awk -F '[:, ]' '{ print $2 }')
y=$(echo $loc | awk -F '[:, ]' '{ print $4 }')

while true; do
  sleep $PERIOD_IN_SECONDS

  # Acquire new mouse x and y
  loc=$(xdotool getmouselocation)
  x_new=$(echo $loc | awk -F '[:, ]' '{ print $2 }')
  y_new=$(echo $loc | awk -F '[:, ]' '{ print $4 }')

  # If the cursor did not move start flashfocus if its not running. If the
  # cursor did move kill the process if its alive.
  if [ "$x" = "$x_new" ] && [ "$y" = "$y_new" ]; then
    if [ -z "$(ps -p $pid | tail -n +2)" ]; then
      flashfocus &
      pid=$(echo $!)
    fi
  else
    if [ ! -z "$(ps -p $pid | tail -n +2)" ]; then
      kill $pid
    fi
  fi

  x="$x_new"
  y="$y_new"
done

