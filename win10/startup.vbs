'startup.vbs

' Spawn ubuntu shell (and hide cmd.exe) 
CreateObject("Wscript.Shell").Run "wintty\start-ubuntu-wsltty.bat", 0

' Run Xserver
vcxsrv_path="C:\Tools\VcXsrv\vcxsrv.exe"
CreateObject("Wscript.Shell").Run vcxsrv_path, 0

' Run AHK scripts
CreateObject("Wscript.Shell").Run "mappings.ahk", 0

