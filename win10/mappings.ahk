; BUG: Script must be run as Admin manually. 'A_AsAdmin' check does not work
;      Temporary fix: hardcode filepath (PATH cannot be accessed)
#SingleInstance force

; Path to batchfile starting wsltty
global termpath := "C:\Users\shuell\projects\dotfiles\win10\wintty\start-ubuntu-wsltty.bat"
global xserv_id_string := "VcXsrv Server - Display"

startupSequence()

; Keybinds 
Capslock::Esc ;
<#l::focusRight()
<#h::focusLeft()
<#F12:: ; Win+F12 / Toggle-view VcXsrv instance
  spawnUnique(xserv_id_string, "C:\Tools\VcXsrv\vcxsrv.exe")
  toggleView(xserv_id_string, false)
  return
<#e:: ; Win-E / Run file-explore
  spawnUnique("ahk_class CabinetWClass", "explorer.exe")
  toggleView("ahk_class CabinetWClass")
  return
<#<+q:: ; Shift-Win-Q / Close focused window
  WinClose("A")
  return
; Win+F / Maximize if not max'ed. Restore otherwise
<#f::
  if (!(WinGetStyle("A") & 0x1000000))
    WinMaximize("A")
  else 
    WinRestore("A")
  return
<#d::Run("cmd.exe") ; Win+D / Run 'run' dialogue
<#Enter:: ; Win+Enter / Open terminal window
  Run("cmd /C " . termpath)
  return
<#1::switchDesktopByNumber(1)
<#2::switchDesktopByNumber(2)
<#3::switchDesktopByNumber(3)
<#4::switchDesktopByNumber(4)

;;;
;
; Functions
;;;

; toggleView - Hide and show window
toggleView(identifier,
           focus := true,   ; focus the raised window
           match_mode := 2) ; passed to SetTitleMatchMode
{ 
  SetTitleMatchMode match_mode
  ; Toggle visible
  DetectHiddenWindows false
  if ( !WinExist(identifier) )
  {
    DetectHiddenWindows true
    if ( WinExist(identifier) )
    {
      ; Window is hidden
      WinShow(identifier)
      WinMaximize(identifier)
      if (focus)
        WinActivate(identifier)
      return
    }
  }
  WinHide(identifier)
  return
}

; spawnUnique - Run process if it does not exist
; Match mode and detection of hidden windows can be specified
spawnUnique(identifier,            ; window identifier. E.g. "ahk_class Firefox"
            path,                  ; executable. E.g. "Firefox.exe"
            match_mode := 2,       ; forwarded to SetTitleMatchMode
            detect_hidden := true) ; forwarded to DetectHiddenWindow
{
  DetectHiddenWindows detect_hidden
  SetTitleMatchMode match_mode
  if( !WinExist(identifier) )
    Run(path)
  return
}

; focusRight - focus window to the right
focusRight()
{
    Send("!{Tab}")
}

; focusLeft - focus window to the left
focusLeft()
{
  Send("+!{Tab}")
}

;
; Virtual Desktops (Win-1..9) 
;
; This function examines the registry to build an accurate list of the current virtual desktops and which one we're currently on.
; Current desktop UUID appears to be in HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\SessionInfo\1\VirtualDesktops
; List of desktops appears to be in HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VirtualDesktops
;
global CurrentDesktop, DesktopCount, DesktopSettings
mapDesktopsFromRegistry() {

  ; Get current desktop ID ( a binary 32-char string )
  DllCall("ProcessIdToSessionId",
          "UInt", DllCall("GetCurrentProcessId", "UInt"),
          "UInt*", SessionId)
  CurrentDesktopId := RegRead("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\SessionInfo\" .
                              SessionId . "\VirtualDesktops", "CurrentVirtualDesktop") 
  IdLength := StrLen(CurrentDesktopId)

  ; Calculate desktop count. This regkey consists of a concat of all desktop IDs
  DesktopIdList := RegRead("HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VirtualDesktops", "VirtualDesktopIDs")
  DesktopCount := StrLen(DesktopIdList) / IdLength

  ; Check which desktop we're currently on by matching all Id substrings
  i := 0
  while (CurrentDesktopId and i < DesktopCount) {
    StartPos := (i * IdLength) + 1
    DesktopId := SubStr(DesktopIdList, StartPos, IdLength)

    if (DesktopId = CurrentDesktopId) {
      CurrentDesktop := i + 1
      return
    }
    i++
  }
}
;
; This function switches to the desktop number provided.
;
switchDesktopByNumber(targetDesktop)
{
  mapDesktopsFromRegistry()
  ; Store currently active window to be focused when returning the desktop
   
  ; Go right until we reach the desktop we want
  while(CurrentDesktop < targetDesktop) {
    Send("^#{Right}")
    CurrentDesktop++
    Sleep 75
  }
  ; Go left until we reach the desktop we want
  while(CurrentDesktop > targetDesktop) {
    Send("^#{Left}")
    CurrentDesktop--
    Sleep 75
  }
}

;
; This function creates a new virtual desktop and switches to it
;
createVirtualDesktop()
{
  Send("#^d")
  DesktopCount++
  CurrentDesktop := DesktopCount
}
;
; This function deletes the current virtual desktop
;
deleteVirtualDesktop()
{
  Send("#^{F4}")
  DesktopCount--
  CurrentDesktop--
}

moveWindowToDesktop(targetDesktop)
{
  uid := WinExist("A")
  WinHide ahk_id %uid%
  switchDesktopByNumber(targetDesktop)
  WinShow ahk_id %uid%
}

; <#+1::moveWindowToDesktop(1)
; <#+2::moveWindowToDesktop(2)
; <#+3::moveWindowToDesktop(3)
; <#+4::moveWindowToDesktop(4)
startupSequence()
{
  SetKeyDelay 75
  mapDesktopsFromRegistry()

  DetectHiddenWindows true
  SetTitleMatchMode "RegEx"

  if (!WinExist(xserv_string))
  {
    ; BUG: Cannot start hidden window :(
    Run(vcxsrvpath)
  }
}  
