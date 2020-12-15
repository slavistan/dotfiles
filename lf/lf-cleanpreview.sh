#!/usr/bin/env bash

#
# Clears ueberzug preview. Called by lf(p) when moving between directories by
# configuring the 'cleaner' setting.
#
# Executing lf instance must be called by lfrun, which defines LF_TEMPDIR and
# LF_FIFO_UEBERZUG and initializes ueberzug previews. This script it not meant
# to be run on its own.
#

readonly ID_PREVIEW="preview"
declare -p -A cmd=([action]=remove [identifier]="$ID_PREVIEW") \
	> "$LF_FIFO_UEBERZUG"

# TODO: Integrate this into 'lf-preview.sh'. The less files the better.
