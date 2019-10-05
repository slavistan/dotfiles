#!/usr/bin/env sh
# x-run-and-report
# Run a command and report its stdout to X

# Get input from dmenu (requires the -t patch)
cmd=$(echo "-" | dmenu -t -p "RNR:" -h 40 -fn "Hack:size=17")
result="$($cmd)"
code="$?"

# Store command, return code and output
output=$(printf "\
\$ $cmd: $code
$result")

# Display via libnotify
notify-send "$output"

# Send to copyq
copyq copy "$output"

# TODO:
# - Throw a warning if command is interactive (eg. sudo .. )
# - Command history
