__install_lightdm() {
  if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    printf "\
Usage:
  $0 [--force]

Installs lightdm, the webkit2-greeter and the Aether theme.
"
    exit 0
  else
    loglnprefix "lightdm" "Installing ligthdm ..."
    please apt install -y lightdm
    please systemctl disable sddm
    please systemctl disable gdm
    please cp -f $DOTFILES/lightdm/lightdm.conf /etc/lightdm

    loglnprefix "lightdm" "Installing webkit2-greeter ..."
    tmp=$(mktemp -d)
    cd $tmp
    wget -O webkit.deb https://download.opensuse.org/repositories/home:/antergos/xUbuntu_17.10/amd64/lightdm-webkit2-greeter_2.2.5-1+15.31_amd64.deb
    please dpkg -i ./webkit.deb
    please cp -f $DOTFILES/lightdm/lightdm-webkit2-greeter.conf /etc/lightdm

    loglnprefix "lightdm" "Installing webkit2-greeter theme 'Aether' ..."
    tmp=$(mktemp -d)
    cd $tmp
    git clone git@github.com:NoiSek/Aether.git
    please cp --recursive Aether /usr/share/lightdm-webkit/themes/Aether

    loglnprefix "lightdm" "Apply workaround hack for 'Aether' theme (see issue #73) ..."
    cd /usr/share/lightdm-webkit/themes
    please ln -s ./Aether lightdm-webkit-theme-aether

    loglnprefix "lightdm" "... done installing lightdm."
  fi
}
