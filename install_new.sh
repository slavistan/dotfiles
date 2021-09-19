# Basis installation
# 
# Szenario: Neuinstallation fertig, manuell git installieren.
# Nach Basisinstallation soll sich System wie "daheim" anfühlen.
#
# 1. Manuell git und zsh installieren
#
# .profile, .zprofile, chsh
#

- liste mit aurs und packages

# zsh installation

- zsh installieren
- chsh
- .zprofile symlink,
- .profile symlink, (vielleicht vorher)
- plugin: zsh-syntax-highlighting
- plugins: lf-shellcd
- symlink ~/.config/zsh

# lf setup
- install lf (github)/aur
- TODO: Single setup ohne verteilte Dateien

# Desktop environment setup
# =========================

# X11
# ---
- install xorg + libs, xinit
- symlink ~/.xinitrc
- setxkbmap + layout

# Basisfunktionalität
# -------------------
- autorandr + config
- xrandr, arandr
- sxhkd + layout
- copyq + config
- dmenu + dmenu_run
- install dwm + fonts
- Dejavu, Nerdfonts complete
- fonts (dwm, st)
- dunst


# Programs
# --------
- install st
- sxiv
