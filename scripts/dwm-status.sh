#!/usr/bin/env sh

###
### Status
###

battery() {
  for p in /sys/class/power_supply/BAT?/capacity; do
    echo "$(cat "$p")%"
  done
}

power() {
  device=$(ls /sys/class/power_supply/ | grep -v 'BAT') # AC device names differ
  [ "$(cat /sys/class/power_supply/"$device"/online)" -eq 1 ] && printf ⚡|| printf 🔋
}

systime() {
  date '+%d. %B %H:%M'
}

keymap() {
  echo "⌨ $(setxkbmap -query | grep layout | awk '{ print $2 }')"
}

status() {
  echo " $(keymap) | $(power) $(battery) | $(systime)"
}


###
### Process control. Usage: $0 -- <cmd>
###

pidofrunning() {
  pgrep -a -f dwm-status.sh | awk '{ if ($2=="sh" && $(NF-1)!="--") print $1 }'
}

killrunning() {
  for pid in $(pidofrunning); do
    kill "$pid" > /dev/null 2>&1 && echo "Killed pid $pid." || echo "Couldn't kill $pid"
  done
}

kickrunning() {
  for pid in $(pidofrunning); do
    kill -s USR1 "$pid"
  done
}

reloadrunning() {
  for pid in $(pidofrunning); do
    kill -s USR2 "$pid"
  done
}


###
### main()
###

trap 'echo *kick*' USR1
trap 'echo *reload*; [ $SLEEPPID ] && kill $SLEEPPID; exec $0' USR2
trap '[ $SLEEPPID ] && kill $SLEEPPID; exit' 0 1 2 3 9 15

SLEEPPID=

case "$1" in
  --)
    # Execute commands via $0 -- cmd. The double dashes simplify pgrep'ing
    # for running instances of this script.
    shift
    "$@"
    ;;
  *)
  while :; do
    xsetroot -name "$(status | tr '\n' ' ')"
    kill $SLEEPPID 2>/dev/null # kill last sleep &
    sleep 1m &
    SLEEPPID="$!"
    wait $SLEEPPID # noexec-wait for sleep; skipped immediately by SIGUSR1
  done
  ;;
esac
