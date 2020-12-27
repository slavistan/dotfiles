#!/usr/bin/env bash

#
# lf previewer script when using thumbnail selection. Enables previews for
# image files without file extension (jpg is assumed).
#
# defines LF_TEMPDIR and LF_FIFO_UEBERZUG and initializes ueberzug previews.
# This script it not meant to be run on its own.
#

# Clear the last preview (if any)
declare -p -A cmd=([action]=remove [identifier]="preview") \
	> "$LF_FIFO_UEBERZUG"

imgpath="$1"
titlefile=".$(basename "$imgpath").title"
title="$(cat "$titlefile")"
case "$imgpath" in
*)
	lf -remote "send $id set promptfmt \"Title: \033[1m$title\033[0m\""
	lf -remote "send $id echo \"▶ \033[1mPlay \033[0;4mEnter\033[0m | ⏼  \033[1mQuit \033[0;4mq\033[0m | 📥 \033[1mDownload \033[0;4md\033[0m\""
	declare -p -A cmd=([action]=add [identifier]="preview" \
		[x]="$4" [y]="$5" [max_width]="$3" [max_height]="$2" \
		[path]="$imgpath") > "$LF_FIFO_UEBERZUG"
	;;
esac
return 127 # nonzero retcode required for lf previews to reload
