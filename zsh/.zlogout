# This file is sourced whenever a user logs out of an zsh session. During
# sourcing the user is still logged in his session will be listed under `who`.

if [[ "$(who | cut -d' ' -f1 | grep "^$USER\$" | wc -l)" == 1 ]]; then
	# Kill user's runsvdir process, so it won't restart any of the runsv
	# processes.
	pkill -U "$USER" -x runsvdir

	# 'sv force-shutdown ...' will terminate the service and the runsv
	# watchers.
	sv force-shutdown "$USERSVDIR"/*
fi
