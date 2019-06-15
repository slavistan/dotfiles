#!/usr/bin/env zsh

# We can't access environment variables from within the i3-config. Thus we call this script which can. $TERMINAL is my own envvar defined in '.profile'.
i3-msg -q 'exec $TERMINAL'
