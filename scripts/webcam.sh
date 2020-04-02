#!/usr/bin/env sh

view() {
  cmd="mpv av://v4l2:/dev/video2"
  case "$1" in
  on)
    $0 loopback on && sleep 0.5
    $cmd &
    ;;
  off)
    $0 loopback off && sleep 0.2
    pkill -9 -f "$cmd" # -9 required; dunno why
    ;;
  status)
    pgrep -f "$cmd" > /dev/null && echo on || echo off
    ;;
  toggle)
    [ "$($0 view status)" = "on" ] && $0 view off || $0 view on
    ;;
  esac
}

loopback() {
  cmd="ffmpeg -i /dev/video0 -codec copy -f v4l2 /dev/video2"
  if [ "$1" = "on" ]; then
    if fuser /dev/video0 > /dev/null 2>&1; then
      echo "/dev/video0 is in use. Nothing done."
      exit 1
    else
      $cmd > /dev/null 2>&1 & 
      echo "Started loopback: /dev/video0 -> /dev/video2"
    fi
  elif [ "$1" = "off" ]; then
    if pkill -f "$cmd"; then
      echo "Closed loopback: /dev/video0 -> /dev/video2"
    else
      echo "Nothing to do. Nothing done."
      exit 1
    fi
  elif [ "$1" = "status" ]; then
    pgrep -f "$cmd" > /dev/null && echo on || echo off
  elif [ "$1" = "toggle" ]; then
    [ "$($0 loopback status)" = "on" ] && $0 loopback off || $0 loopback on
  fi
}

$@
