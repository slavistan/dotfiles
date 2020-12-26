#!/usr/bin/env sh

if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
	cat <<-EOF
	Run to start recording. Run again to stop recording.
	EOF
	exit
fi

# 1st line: ffmpeg pid, 2nd line: outfile
pidfile="/tmp/screencast.sh-pidfile-$(id -u)"

if pid="$(head -1 "$pidfile" 2>/dev/null)"; then
	kill -INT $pid
	echo "Stopped recording. Output: '$(tail -1 "$pidfile")'."
	if [ ! -t 1 ]; then
		notify-send -t 3000 "Stopped recording."
	fi
	rm "$pidfile"
else
	set -e
	reply="$(dmenu -l 10 -p "Record what?" <<-EOF
	fullscreen
	EOF
	)" || exit 1
	case "$reply" in
	fullscreen)
		rootinfo="$(xwininfo -root)"
		h="$(echo "$rootinfo" | grep Height: | awk -F ': ' '{ print $2 }')"
		w="$(echo "$rootinfo" | grep Width: | awk -F ': ' '{ print $2 }')"
		x=0; y=0
		;;
	esac
	reply="$(dmenu -l 10 -p "Capture audio?" <<-EOF
	Yes
	No
	EOF
	)" || exit 1
	if [ "$reply" = "Yes" ]; then
		audio="-f pulse -ac 1 -i default"
	fi
	outdir="$(mktemp -d -t screencast.sh-$(id -u)-$(date -Is)-XXX)"
	outfile="$outdir/screencast.mp4"
	stdout="$outdir/stdout.log"
	stderr="$outdir/stderr.log"

	cmdstr="ffmpeg -video_size ${w}x${h} -framerate 10 -f x11grab -i :0.0+$x,$y $audio $outfile >$stdout 2>$stderr &"
	eval "$cmdstr"

	echo "$!\n$outfile" >"$pidfile"
	echo "Recording to '$outfile'."
	if [ ! -t 1 ]; then
		notify-send -t 3000 "Started recording."
	fi
fi
