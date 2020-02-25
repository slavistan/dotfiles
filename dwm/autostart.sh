# This script is executed during startup of dwm

source ~/.profile

## Start sxhkd or, if running, reload config

if [ -z "$(pgrep sxhkd)" ]; then
  sxhkd &
else
  kill -SIGUSR1 "$(pgrep sxhkd)"
fi

## Set background image

feh --bg-scale ~/pic/backgrounds/forest.jpg

# Load custom keyboard layout

setxkbmap -layout stan
