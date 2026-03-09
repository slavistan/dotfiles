#!/usr/bin/env bash

active_note() {
	current_wid="$(xdotool getactivewindow)"
	#current_wid=27262979  # debugging

	# E.g. WM_CLASS(STRING) = "obsidian", "obsidian"
	wm_class="$(xprop -id "$current_wid" WM_CLASS | sed -E 's/^.*"(.*)", ".*"$/\1/')"

	# E.g. WM_NAME(UTF8_STRING) = "Anki Werkstatt Notizen - wiki - Obsidian 1.12.4"
	wm_name="$(xprop -id "$current_wid" WM_NAME | sed -E 's/^[^"]+"(.*)"$/\1/')"

	if [[ "$wm_class" != "obsidian" ]]; then
		return 1
	fi

	filename_noext="$(sed -E 's/^(.*) - [^-]+ - [^-]+$/\1/' <<<"$wm_name")"
	filepath_rel="$(obsidian file file="$filename_noext" | head -1 | cut -d$'\t' -f2-)"
	if  ! grep -q '\.md$' <<<"$filepath_rel"; then
		# Skip non-markdown files (images, documents, database, ...)
		return 1
	fi

	vault_path_abs="$(obsidian vault info=path)"
	filepath_abs="$vault_path_abs/$filepath_rel"
	echo "$filepath_abs"
}

spawn_claude_tui() {
	instruction="$1"

	vault_root="$(obsidian vault info=path)"
	"$TERMINAL" -g 100x30 -c floating -e \
		zsh -ic 'cd -- "$1" && exec claude "$2"' zsh "$vault_root" "$instruction" &
	sleep 0.2
	wid="$(xdotool search --class "floating" | tail -n1)"
	xdotool windowsize "$wid" 900 600
}

if ! filepath="$(active_note)"; then
	exit
fi

instruction="Du bist ein hilfreicher, hochgebildeter Agent in meinem Obsidian Vault, der mir hilft mein Second Brain Netzwerk gedeihen zu lassen. Ich möchte mit dir über eine Notiz sprechen, die ich ein einem zweiten Fenster bearbeite und prüfe. Schreibe nichts und warte auf meine Fragen. Hier ist die Datei: $filepath"
spawn_claude_tui "$instruction"
