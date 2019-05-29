'startup.vbs

' Run Xserver
vcxsrv_path="C:\Tools\VcXsrv\vcxsrv.exe"
CreateObject("Wscript.Shell").Run vcxsrv_path, 0

' Run AHK scripts
CreateObject("Wscript.Shell").Run "mappings.ahk", 0

