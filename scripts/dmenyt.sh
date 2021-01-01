#!/usr/bin/env bash

_geturl() {
	tmpdir="$1"
	videoid="$2"
	reply="$(youtube-dl -g "https://youtu.be/$videoid")"
	echo "$reply" | head -1 > "$tmpdir/.$videoid.videourl"
	echo "$reply" | tail -1 > "$tmpdir/.$videoid.audiourl"
}

cleanup() {
	rm -r "$tmpdir" 2>/dev/null
	pkill -P $geturlpid 2>/dev/null
	kill $geturlpid 2>/dev/null
	[ ! -z "$1" ] && exit "$1"
}

maxresults=15
if echo "$1" | grep -q '^_'; then
	func="$1"
	shift
	$func "$@"
	exit
elif [ "$1" = "-n" ]; then
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

# prepare audio and video stream urls in advance. save to
# .<videoid>.audiourl / .<videoid>.videourl
echo "$videoids" | xargs -n 1 -P 8 $0 _geturl "$tmpdir" 2>/dev/null &
geturlpid=$!

# TODO: Howto set the returncode for lf?
# An aborted selection should be indicated via the return code like dmenu does.
if ! videoid="$(lf-thumbnailselect.sh "$tmpdir")"; then
	cleanup 1
fi
pkill -P $geturlpid 2>/dev/null
kill $geturlpid 2>/dev/null
if [ -f "$tmpdir/.$videoid.videourl" ] && [ -f "$tmpdir/.$videoid.audiourl" ]; then
	if videourl="$(cat "$tmpdir/.$videoid.videourl" 2>/dev/null)" && \
		audiourl="$(cat "$tmpdir/.$videoid.audiourl" 2>/dev/null)"; then
		mpveval="mpv --audio-file=\"$audiourl\" \"$videourl\""
	fi
else
	mpveval="mpv \"https://youtu.be/$videoid\""
fi
rm -r "$tmpdir"
dwmswallow $WINDOWID
eval "$mpveval" >/dev/null 2>&1

# TODO: doc/usage
# TODO: posix shell
