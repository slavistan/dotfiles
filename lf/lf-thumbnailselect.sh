#!/usr/bin/env sh

export LF_THUMBNAILSELECT="$(mktemp -t lf-thumbnailselect-XXXXXX)"
lfrun "$@"
sel="$(cat "$LF_THUMBNAILSELECT")"
rm "$LF_THUMBNAILSELECT"
if [ -z "$sel" ]; then
	exit 1
else
	echo "$sel"
fi
