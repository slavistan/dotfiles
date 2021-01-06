#!/usr/bin/env sh

_getpid() {
	if ! head -1 "$pidfile" 2>/dev/null; then
		return 1
	fi
}

_getrecdir() {
	if ! tail -1 "$pidfile" 2>/dev/null; then
		return 1
	fi
}

start() {
	if status | grep -q '^live'; then
		echo "Already recording. Abort." >&2
		exit 1
	fi

	reply="$(dmenu -l 10 -p "Record what?" <<-EOF
	Fullscreen
	Window (Select)
	EOF
	)" || exit 1
	case "$reply" in
	Fullscreen)
		rootinfo="$(xwininfo -root)"
		h="$(echo "$rootinfo" | grep Height: | awk -F ': ' '{ print $2 }')"
		w="$(echo "$rootinfo" | grep Width: | awk -F ': ' '{ print $2 }')"
		x=0; y=0
		;;
	Window*)
		wininfo="$(xdotool selectwindow getwindowgeometry --shell)"
		x="$(echo "$wininfo" | grep '^X=' | cut -d= -f2)"
		y="$(echo "$wininfo" | grep '^Y=' | cut -d= -f2)"
		# HACK: x,y locate top left corner including border; w,h refer to inner window
		x=$((x + 1))
		y=$((y + 1))
		w="$(echo "$wininfo" | grep '^WIDTH=' | cut -d= -f2)"
		h="$(echo "$wininfo" | grep '^HEIGHT=' | cut -d= -f2)"
	esac

	if ! fps="$(echo "" | dmenu -p "Frames Per Second:")" || \
		! echo "$fps" | grep -q '^[1-9][0-9]*$'; then
		exit 1
	fi

	# TODO: Implement audio
	# reply="$(dmenu -l 10 -p "Capture audio?" <<-EOF
	# Yes
	# No
	# EOF
	# )" || exit 1
	# if [ "$reply" = "Yes" ]; then
	# 	audio="-f pulse -ac 1 -i default"
	# fi

	recdir="$(mktemp -d -t screencast.sh-$(id -u)-$(date -Is)-XXX)"
	outfile="$recdir/screencast.mp4"
	stdout="$recdir/stdout.log"
	stderr="$recdir/stderr.log"
	cmdstr="ffmpeg -video_size ${w}x${h} -framerate $fps -f x11grab -i :0.0+$x,$y $audio $outfile >$stdout 2>$stderr &"
	eval "$cmdstr"

	echo "$!\n$recdir" >"$pidfile"
	echo "Recording to '$recdir'."
}

status() {
	if pid=$(_getpid); then
		echo "live: Recording to '$(_getrecdir)' (pid: $pid)."
	else
		echo "offline: Not recording."
	fi
}

stop() {
	if status | grep -q '^offline'; then
		echo "Not recording. Abort." >&2
		exit 1
	fi
	kill -INT "$(_getpid)"
	echo "Stopped recording. Output: '$(_getrecdir)'."
	rm "$pidfile"
}

usage() {
	cat <<-EOF
	Usage:
	EOF
}

# 1st line: ffmpeg pid, 2nd line: recdir
pidfile="/tmp/screencast.sh-pidfile-$(id -u)"

case "$1" in
status) status ;;
start) start ;;
stop) stop ;;
-h|--help|*) usage ;;
esac
