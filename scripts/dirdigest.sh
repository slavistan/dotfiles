#!/usr/bin/env sh

exa --icons --group-directories-first -G -T -L2 |
  sed -E 's/|/📁/g' 

# TODO(fix): Continue implementation
