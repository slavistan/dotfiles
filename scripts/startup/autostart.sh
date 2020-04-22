# This script is executed during startup of dwm

## Source environment variables

source ~/.profile

## Start sxhkd or, if running, reload config

[ "$(pgrep sxhkd)" ] && sxhkd & || kill -SIGUSR1 "$(pgrep sxhkd)"

## Start copyq daemon

[ "$(pgrep copyq)" ] && copyq &

## Start dropbox daemon

dropbox start &

## Start compton (required for transparency)

[ $(pgrep compton) ] && compton &

## Run dwm status bar script

$DOTFILES/scripts/dwm/dwm-status.sh &

## Set background image

[ -f "~/dat/img/wall" ] \
 && feh --bg-scale "~/dat/img/wall" \
 || feh --bg-scale $DOTFILES/files/img/ubuntu-teal.jpg

# Load custom keyboard layout

setxkbmap -layout stan

# Run monitor setup

if [ -f "$DOTFILES/scripts/startup/monitor-setup.sh" ]; then
  $DOTFILES/scripts/startup/monitor-setup.sh
fi

# Execution machine-specific startup script

if [ -f "$DOTFILES/scripts/startup/machine-specific.sh" ]; then
  $DOTFILES/scripts/startup/machine-specific.sh
fi

# Display log

libreoffice ~/Dropbox/log.ods &
