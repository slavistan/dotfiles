#SingleInstance force
DetectHiddenWindows, On

; Map Capslock to Escape
Capslock::Esc

; Win+F12: Toggle VcXsrv instance
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

; Run file-explorer
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

<#l::AltTab
<#h::ShiftAltTab
<#<+q::WinClose A

; Win+F: Maximize if not max'ed. Restore otherwise
<#f::
  WinGet, state, MinMax, A
  if (state == -1 || state == 0) {
    WinMaximize A
    WinSet, Style, -0xC40000, A
  }
  else {
    WinRestore A
    WinSet, Style, +0xC00000, A
  }
  return

; Win+D: Run 'run' dialogue
<#d::
  Send, #x
  Send, r
  return
