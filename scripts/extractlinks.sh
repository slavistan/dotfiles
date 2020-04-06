#!/usr/bin/env sh

if [ "$1" = "-h" ] || [ "$1" = "--help" ] || [ "$1" = "-?" ]; then
  printf "\
Usage: $0 FILENAME

Scans file for hyperlinks and returns them one per line. Use '-' as filename
to read from stdin.
"
  exit 0
fi

if [ ! "$1" = "-" ] && [ ! -e "$1" ]; then
  $0 "-h"
  exit 1
fi

sed 's/.*│//g' "$1" |
  tr -d '\n' |
  grep -aEo '(((http|https)://|www\\.)[a-zA-Z0-9.]*[:]?[a-zA-Z0-9./@&%?$#=_-]*)|((magnet:\\?xt=urn:btih:)[a-zA-Z0-9]*)' |
  uniq
