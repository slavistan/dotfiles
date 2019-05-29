#SingleInstance force

; Path to batchfile starting wsltty
global termpath := "C:\Users\shuell\projects\dotfiles\win10\wintty\start-ubuntu-wsltty.bat"
DetectHiddenWindows, On

; Capslock / Maps to Escape
Capslock::Esc

; Win+F12 / Toggle-view VcXsrv instance
#F12::
  SetTitleMatchMode RegEx
  DetectHiddenWindows, On
  IfWinExist, ahk_class VcXsrv
  {
    DetectHiddenWindows, Off
    ; Check if its hidden
    IfWinNotExist, ahk_class VcXsrv
    {
      WinShow, ahk_class VcXsrv
      WinMaximize, ahk_class VcXsrv
      WinActivate, ahk_class VcXsrv
      return
    }
    WinHide, ahk_class VcXsrv
  }
  return

; Win-E / Run file-explorer
<#e::
  SetTitleMatchMode RegEx
  DetectHiddenWindows, On
  WinGet, uid, ID, ahk_class CabinetWClass
  if ( uid = "" ) {
    Run, % systemroot "\explorer.exe"
    WinGet, uid_run, ID, ahk_class CabinetWClass
    WinMaximize, ahk_id %uid_run%
    WinActivate, ahk_id %uid_run%
    return
  }
  DetectHiddenWindows, Off
  IfWinNotExist, ahk_id %uid%
  {
    WinShow, ahk_id %uid%
    WinMaximize, ahk_id %uid%
    WinActivate, ahk_id %uid%
    return
  }
  WinHide, ahk_id %uid%
  return


; Win-L / Focus previous window
<#l::AltTab

; Win-R / Focus next window
<#h::ShiftAltTab

; Shift-Win-R / Close focused window
<#<+q::
  WinClose A
  return

; Win+F / Maximize if not max'ed. Restore otherwise
<#f::
  WinGet, state, MinMax, A
  if (state == -1 || state == 0) {
    WinMaximize A
  }
  else {
    WinRestore A
  }
  return

; Win+B / Toggle window borders
;  <#b::
;    WinSet, Style, ^0xC00000, A ; TODO: Does break some borderless windows (i.e. firefox)
;    return

; Win+D / Run 'run' dialogue
<#d::
  Send #x r
  return

; Win+Enter / Open terminal window
<#Enter::
  Run, cmd /C %termpath%
  return

;
; Virtual Desktops (Win-1..9) 
;
; This function examines the registry to build an accurate list of the current virtual desktops and which one we're currently on.
; Current desktop UUID appears to be in HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\SessionInfo\1\VirtualDesktops
; List of desktops appears to be in HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VirtualDesktops
;
mapDesktopsFromRegistry() {
  global CurrentDesktop, DesktopCount
  ; Get the current desktop UUID. Length should be 32 always, but there's no guarantee this couldn't change in a later Windows release so we check.
  IdLength := 32
  SessionId := getSessionId()
  if (SessionId) {
    RegRead, CurrentDesktopId, HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\SessionInfo\%SessionId%\VirtualDesktops, CurrentVirtualDesktop
    if (CurrentDesktopId) {
      IdLength := StrLen(CurrentDesktopId)
    }
  }
  ; Get a list of the UUIDs for all virtual desktops on the system
  RegRead, DesktopList, HKEY_CURRENT_USER, SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VirtualDesktops, VirtualDesktopIDs
  if (DesktopList) {
    DesktopListLength := StrLen(DesktopList)
    ; Figure out how many virtual desktops there are
    DesktopCount := DesktopListLength / IdLength
  }
  else {
    DesktopCount := 1
  }
  ; Parse the REG_DATA string that stores the array of UUID's for virtual desktops in the registry.
  i := 0
  while (CurrentDesktopId and i < DesktopCount) {
    StartPos := (i * IdLength) + 1
    DesktopIter := SubStr(DesktopList, StartPos, IdLength)
    OutputDebug, The iterator is pointing at %DesktopIter% and count is %i%.
    ; Break out if we find a match in the list. If we didn't find anything, keep the
    ; old guess and pray we're still correct :-D.
    if (DesktopIter = CurrentDesktopId) {
      CurrentDesktop := i + 1
      OutputDebug, Current desktop number is %CurrentDesktop% with an ID of %DesktopIter%.
      break
    }
    i++
  }
}
;
; This functions finds out ID of current session.
;
getSessionId()
{
  ProcessId := DllCall("GetCurrentProcessId", "UInt")
  if ErrorLevel {
    OutputDebug, Error getting current process id: %ErrorLevel%
    return
  }
  OutputDebug, Current Process Id: %ProcessId%
  DllCall("ProcessIdToSessionId", "UInt", ProcessId, "UInt*", SessionId)
  if ErrorLevel {
    OutputDebug, Error getting session id: %ErrorLevel%
    return
  }
  OutputDebug, Current Session Id: %SessionId%
  return SessionId
}
;
; This function switches to the desktop number provided.
;
switchDesktopByNumber(targetDesktop)
{
  global CurrentDesktop, DesktopCount
  ; Re-generate the list of desktops and where we fit in that. We do this because
  ; the user may have switched desktops via some other means than the script.
  mapDesktopsFromRegistry()
  ; Don't attempt to switch to an invalid desktop
  if (targetDesktop > DesktopCount || targetDesktop < 1) {
    OutputDebug, [invalid] target: %targetDesktop% current: %CurrentDesktop%
    return
  }
  ; Go right until we reach the desktop we want
  while(CurrentDesktop < targetDesktop) {
    Send ^#{Right}
    CurrentDesktop++
    OutputDebug, [right] target: %targetDesktop% current: %CurrentDesktop%
  }
  ; Go left until we reach the desktop we want
  while(CurrentDesktop > targetDesktop) {
    Send ^#{Left}
    CurrentDesktop--
    OutputDebug, [left] target: %targetDesktop% current: %CurrentDesktop%
  }
}
;
; This function creates a new virtual desktop and switches to it
;
createVirtualDesktop()
{
  global CurrentDesktop, DesktopCount
  Send, #^d
  DesktopCount++
  CurrentDesktop = %DesktopCount%
  OutputDebug, [create] desktops: %DesktopCount% current: %CurrentDesktop%
}
;
; This function deletes the current virtual desktop
;
deleteVirtualDesktop()
{
  global CurrentDesktop, DesktopCount
  Send, #^{F4}
  DesktopCount--
  CurrentDesktop--
  OutputDebug, [delete] desktops: %DesktopCount% current: %CurrentDesktop%
}
; Main
SetKeyDelay, 75
mapDesktopsFromRegistry()
OutputDebug, [loading] desktops: %DesktopCount% current: %CurrentDesktop%
; User config!
; This section binds the key combo to the switch/create/delete actions
LWin & 1::switchDesktopByNumber(1)
LWin & 2::switchDesktopByNumber(2)
LWin & 3::switchDesktopByNumber(3)
LWin & 4::switchDesktopByNumber(4)
LWin & 5::switchDesktopByNumber(5)
LWin & 6::switchDesktopByNumber(6)
LWin & 7::switchDesktopByNumber(7)
LWin & 8::switchDesktopByNumber(8)
LWin & 9::switchDesktopByNumber(9)

