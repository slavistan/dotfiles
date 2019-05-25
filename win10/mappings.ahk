#SingleInstance force
SetTitleMatchMode RegEx
DetectHiddenWindows, On

; Win+F12: Toggle VcXsrv instance
#F12::
{
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
}

; Map Capslock to Escape
Capslock::Esc

; Run file-explorer
#e::
Run, % systemroot "\explorer.exe"

<#l::AltTab
<#h::ShiftAltTab
<#<+q::WinClose A

; Win+F: Maximize if not max'ed. Restore otherwise
<#f::
{
  WinGet, state, MinMax, A
  if (state == -1 || state == 0) {
    WinMaximize A
  }
  else {
    WinRestore A
  }
}

; Win+D: Run 'run' dialogue
<#d::
{
  InputBox, string, Run, ,,200,100,
  Run %string%
}
