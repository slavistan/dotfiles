#!/usr/bin/env sh

export LF_THUMBNAILSELECT="$(mktemp -t lf-thumbnailselect-XXXXXX)"
lfrun "$@"
cat "$LF_THUMBNAILSELECT"
rm "$LF_THUMBNAILSELECT"
