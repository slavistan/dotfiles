# This file is sourced by login shells and is used to set user and
# session-specific environment variables.

# Freedesktop dirs
# ================
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(user -u "$USER")}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.var}"


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
[ -d "$PATH:$HOME/.local/texlive/2021/bin/x86_64-linux/" ] && export PATH="$PATH:$HOME/.local/texlive/2021/bin/x86_64-linux/"


# Miscellaneous
# =============
export ZDOTDIR="$XDG_CONFIG_HOME/zsh/"
export DOTFILES=/home/stan/prj/dotfiles # TODO: Remove DOTFILES envvar
export __GL_SHADER_DISK_CACHE_PATH=$XDG_CACHE_HOME # nvidia


# Runit User Services
# ===================
export USERSVDIR="$XDG_RUNTIME_DIR/runit/service"
if [ -d "$USERSVDIR" ] && ! pgrep -U "$(id -u "$USER")" runsvdir >/dev/null; then
	runsvdir "$USERSVDIR" &!
fi
