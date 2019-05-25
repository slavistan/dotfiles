'startup.vbs

' Spawn ubuntu shell (and hide cmd.exe) 
CreateObject("Wscript.Shell").Run "wintty\start-ubuntu-wsltty.bat", 0, True

' Run AHK scripts
CreateObject("Wscript.Shell").Run "mappings.ahk", 0, True


