#!/usr/bin/env bash

maxresults=5
if [ "$1" = "-n" ]; then
	maxresults="$2"
	shift 2
fi

export YT_API_KEY="$(cat ~/.youtube.apikey)"
query="$@"
if [ -z "$query" ]; then
	query="$(echo "" | dmenu -p "Search YT Video:")" || exit 1
fi
query="$(echo "$query" | sed 's/ /+/g')"

reply="$(curl -s "https://www.googleapis.com/youtube/v3/search?part=snippet&q=$query&type=video&maxResults=$maxresults&key=$YT_API_KEY")"

tmpdir="$(mktemp -d -t dmenyt-thumbnails-XXXXXX)"

# dl thumbnails
thumbnailurls="$(echo "$reply" | jq -r '.items[].snippet.thumbnails.high.url')"
videoids="$(echo "$reply" | jq -r '.items[].id.videoId')"
titles="$(echo "$reply" | jq -r '.items[].snippet.title')"
cd "$tmpdir"
paste -d '\n' <(echo "$videoids") <(echo "$thumbnailurls") |
	xargs -n 2 -P 8 curl -s -o
cd - >/dev/null

# save titles to .<videoid>.title
paste -d ' ' <(echo "$videoids") <(echo "$titles") | while read line; do
	videoid="$(echo "$line" | cut -d' ' -f1)"
	title="$(echo "$line" | cut -d' ' -f2-)"
	echo "$title" > "$tmpdir/.$videoid.title"
done

# TODO: Howto set the returncode for lf?
# An aborted selection should be indicated via the return code like dmenu does.
videoid="$(lf-thumbnailselect.sh "$tmpdir")"

rm -r "$tmpdir"
if [ ! -z "$videoid" ]; then
	dwmswallow $WINDOWID
	mpv "https://youtu.be/$videoid" >/dev/null 2>&1
else
	exit 1
fi

# TODO: doc/usage
