# This file is sourced by login shells and is used to set user and
# session-specific environment variables.

# Freedesktop dirs
# ================
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(user -u "$USER")}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.var}"
export DOTFILES="$HOME/prj/dotfiles" # TODO: Remove DOTFILES envvar


# Utilities
# =========
export EDITOR=nvim
export BROWSER=brave
export MANPAGER=less
export TERMINAL=st
export PAGER=cat
export SHELL=/usr/bin/zsh


# PATH
# ====
[ -d "$DOTFILES/scripts" ] && export PATH="$DOTFILES/scripts:$PATH"
[ -d "$HOME/go/bin" ] && export PATH="$HOME/go/bin:$PATH"
[ -d "$HOME/.local/bin" ] && export PATH="$HOME/.local/bin:$PATH"


# Miscellaneous
# =============
export GOPATH="$HOME/.local/share/go" # clean $HOME
export ZDOTDIR="$XDG_CONFIG_HOME/zsh" # clean $HOME
export NODE_REPL_HISTORY="$XDG_DATA_HOME/node_repl_history" # clean $HOME
export TS_NODE_HISTORY="$XDG_DATA_HOME/ts-node_repl_history" # clean $HOME
export JUPYTER_CONFIG_DIR="$XDG_CONFIG_HOME/jupyter" # clean $HOME
export __GL_SHADER_DISK_CACHE_PATH=$XDG_CACHE_HOME # nvidia
export PYTHONPYCACHEPREFIX=/tmp/pycache


# Runit User Services (Artix only)
# ================================
if uname -r | grep -q artix; then
	export USERSVDIR="$XDG_DATA_HOME/runit/service"
	if [ -d "$USERSVDIR" ] && ! pgrep -U "$USER" -x runsvdir >/dev/null; then
		# We define DISPLAY because many service won't start without it.
		# Alternatively, DISPLAY=:0 can be exported in the service's 'run' file.
		DISPLAY=:0 runsvdir -P "$USERSVDIR" &
	fi
fi

# Save user's environment to file for reference by system scripts (e.g. runit, udev)
# ==================================================================================
store_env=(
	BROWSER DOTFILES EDITOR GOPATH GTK_MODULES HOME JUPYTER_CONFIG_DIR
	LANG LC_COLLATE LC_NUMERIC LOGNAME MAIL MANPAGER PAGER PATH SHELL TERM
	TERMINAL TZ USER XAUTHORITY XDG_CACHE_HOME XDG_CONFIG_HOME
	XDG_DATA_HOME XDG_RUNTIME_DIR XDG_STATE_HOME ZDOTDIR
	__GL_SHADER_DISK_CACHE_PATH
)
env | grep -E "^(${(j:=|:)store_env})" >"$HOME/.environment" # that's a zsh-ism
