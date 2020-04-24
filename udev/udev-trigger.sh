#!/usr/bin/env sh

echo "[$(/usr/bin/date --iso-8601=seconds)]" "$@" >> /tmp/udev.log
