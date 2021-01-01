#!/usr/bin/env sh

# ffmpeg -f x11grab -s 1920x1080 -i :0.0 -f alsa -i default -codec:v libx264 -preset ultrafast -qp 0 "$1"
ffmpeg -f x11grab -s 1920x1080 -framerate 10 -i :0.0 -codec:v libx264 -preset ultrafast -qp 0 "$1"
