; BUG: Script must be run as Admin manually. 'A_AsAdmin' check does not work
;      Temporary fix: hardcode filepath (PATH cannot be accessed)
#SingleInstance force


globalInit()

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; User Settings
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

global termpath        := "C:\Users\shuell\projects\dotfiles\win10\wintty\start-ubuntu-wsltty.bat" ; terminal
global xserv_id_string := "VcXsrv Server - Display"                                                ; Xserver surrogate

Capslock:: Esc
      #l:: focusRight()
      #h:: focusLeft()
    #F12:: toggleXserver
      #e:: toggleExplorer()
     #+q:: close()
      #f:: toggleMaximize()
      #d:: runDialogue()
  #Enter:: spawnTerminal()
      #1:: switchDesktopByNumber(1)
      #2:: switchDesktopByNumber(2)
      #3:: switchDesktopByNumber(3)
      #4:: switchDesktopByNumber(4)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Function Definitions
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; User interface functions (UIFs)

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

close(identifier := "A")
{
  WinClose(identifier)
  return
}

toggleXserver()
{
  _spawnUnique(xserv_id_string, "C:\Tools\VcXsrv\vcxsrv.exe")
  _toggleView(xserv_id_string, false)
  return
}

toggleExplorer()
{
  _spawnUnique("ahk_class CabinetWClass", "explorer.exe")
  static previously_focused := WinActive("A")
  if (_toggleView("ahk_class CabinetWClass") == "hide")
    WinActivate("ahk_id " . previously_focused)
  return
}

spawnTerminal()
{
  Run("cmd /C " . termpath)
  return
}

toggleMaximize(identifier := "A")
{
  if (!(WinGetStyle(identifier) & 0x1000000))
    WinMaximize(identifier)
  else 
    WinRestore(identifier)
  return
}

; runDialogue - Display dialogue to run commands and programs
runDialogue()
{
  ; BUG: For the love of god .. why does <#x & r not work???
  Run("cmd.exe")
}

moveWindowToDesktop(targetDesktop)
{
  uid := WinExist("A")
  WinHide ahk_id %uid%
  switchDesktopByNumber(targetDesktop)
  WinShow ahk_id %uid%
}

switchDesktopByNumber(targetDesktop)
{
  static previously_focused := [0, 0, 0, 0]

  previously_focused[CurrentDesktop] := WinActive("A")
  _mapDesktopsFromRegistry()
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
  if( WinExist("ahk_id " . previously_focused[targetDesktop] ))
    WinActive("ahk_id " . previously_focused[targetDesktop] ) 
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Level-1 functions (called by UIFs). Prefixed by a single underscore.
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

global CurrentDesktop, DesktopCount, DesktopSettings
; _toggleView - Hide and show a window. Shown windows are moved to the top of the window stack.
;
; returns "show" or "hide" depending on whether the toggle caused the window to be shown or hidden.
;
_toggleView(identifier,             ; window identifier. E.g. "ahk_class Firefox"
           focus := true,           ; focus the raised window
           match_mode := 2)         ; passed to SetTitleMatchMode
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
      _winMoveTop(identifier)
      if (focus)
        WinActivate(identifier)
      return("show")
    }
    else
    {
      _debug("_toggleView called for non-existing identifier: " . identifier)
      return
    }
  }
  WinHide(identifier)
  return("hide")
}

; _spawnUnique - Run process if it does not exist
;
; Match mode and detection of hidden windows can be specified
_spawnUnique(identifier,            ; window identifier. E.g. "ahk_class Firefox"
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

; _winMoveTop - Workaround for AHK's 'WinMoveTop' which fails at times
_winMoveTop(identifier)
{
  WinSetAlwaysOnTop("On")
  WinSetAlwaysOnTop("Off")
}

; _mapDesktopsFromRegistry() - Get current configuration
;
; This function examines the registry to build an accurate list of the current virtual desktops and which one we're currently on.
; Current desktop UUID appears to be in HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\SessionInfo\<current session>\VirtualDesktops
; List of desktops appears to be in HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VirtualDesktops
_mapDesktopsFromRegistry()
{
  ; Get current desktop ID ( a binary 32-char string )
  DllCall("ProcessIdToSessionId",
          "UInt", DllCall("GetCurrentProcessId", "UInt"),
          "UInt*", SessionId)
  CurrentDesktopId := RegRead("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\SessionInfo\" .
                              SessionId . "\VirtualDesktops", "CurrentVirtualDesktop") 
  if (CurrentDesktopId == "" ) ; No virtual desktops have been created sofar
  {
    MsgBox("TODO: Startup Sequence. No virtual desktops are active yet")  
  }
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

; _debug - Wrapper for debugging information
_debug(msg)
{
  ; can't output be forwarded to stdout? Use a MsgBox for now
  MsgBox("DEBUG: " . msg)
}
; globalInit()
;
; Initializes variables and starts applications
globalInit()
{
  SetKeyDelay 75
  _mapDesktopsFromRegistry()
  DetectHiddenWindows true
  SetTitleMatchMode "RegEx"
  if (!WinExist(xserv_string))
  {
    ; BUG: Cannot start hidden window :(
    Run(vcxsrvpath)
  }
}  
