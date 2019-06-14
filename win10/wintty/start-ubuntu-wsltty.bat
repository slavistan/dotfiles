@echo off
rem Start mintty terminal for WSL package Ubuntu

set wsltty_bin=C:\Tools\wsltty\bin\mintty.exe
set config_dir="C:\Users\shuell\projects\dotfiles\win10\wintty"

start %wsltty_bin% --WSL="Ubuntu" --configdir=%config_dir% /bin/bash -c 'source /root/.profile;cd ~;zsh'

