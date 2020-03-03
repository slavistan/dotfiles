__install_dwm() {
  if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    printf "\
Usage:
  $0 [--force]

Installs lightdm, the webkit2-greeter and the Aether theme.
"
    exit 0
  elif
    loglnprefix "lightdm" "Installing ligthdm ..."
    please apt install lightdm
    please systemctl disable sddm
    please systemctl disable gdm
    please cp -f $DOTFILES/lightdm/lightdm.conf /etc/lightdm

    loglnprefix "lightdm" "Installing webkit2-greeter ..."
    please sh -c "echo 'deb http://download.opensuse.org/repositories/home:/antergos/xUbuntu_17.10/ /' > /etc/apt/sources.list.d/home:antergos.list"
    wget -nv https://download.opensuse.org/repositories/home:antergos/xUbuntu_17.10/Release.key -O Release.key
    please apt-key add - < Release.key
    please apt-get update
    please apt-get install lightdm-webkit2-greeter
    please cp -f $DOTFILES/lightdm/lightdm-webkit2-greeter.conf /etc/lightdm

    loglnprefix "lightdm" "Installing webkit2-greeter theme 'Aether' ..."
    tmp=$(ktemp -d)
    cd $tmp
    git clone git@github.com:NoiSek/Aether.git
    sudo cp --recursive Aether /usr/share/lightdm-webkit/themes/Aether

    loglnprefix "lightdm" "Apply workaround hack for 'Aether' theme (see issue #73) ..."
    cd /usr/share/lightdm-webkit/themes
    please ln -s ./Aether lightdm-webkit-theme-aether

    loglnprefix "lightdm" "... done installing lightdm."
  fi
}
