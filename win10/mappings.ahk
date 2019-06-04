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
      #o:: _debug(_getDesktopIndex())

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
  ; Spawn Windows built-in application launcher
  ; BUG: Hotkey does not work if any window is focused. Defocus first (by focusing the task bar)
  WinActivate("ahk_class Shell_TrayWnd")
  Sleep(75)
  Send("#x")
  Sleep(15)
  Send("r")
}

; WIP
moveWindowToDesktop(targetDesktop)
{
  uid := WinExist("A")
  WinHide ahk_id %uid%
  switchDesktopByNumber(targetDesktop)
  WinShow ahk_id %uid%
}

switchDesktopByNumber(target_index)
{
  static previously_focused := [0, 0, 0, 0]
  previously_focused[_getDesktopIndex] := WinActive("A")

  info := _getDesktopInfo()
  ; Go right until we reach the desktop we want
  while(info["current_index"] < target_index) {
    Send("^#{Right}")
    info["current_index"]++
    Sleep 75
  }
  ; Go left until we reach the desktop we want
  while(info["current_index"] > target_index) {
    Send("^#{Left}")
    info["current_index"]--
    Sleep 75
  }
  if( WinExist("ahk_id " . previously_focused[target_index] ))
    WinActive("ahk_id " . previously_focused[target_index] ) 
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Level-1 functions (called by UIFs). Prefixed by a single underscore.
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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
  {
    Run(path)
    ret := WinWait(identifier,,4)
    if (ret == 0)
    {
      _debug("_spawnUnique: WinWait timed out.")
    }
  }
  return
}

; _winMoveTop - Workaround for AHK's 'WinMoveTop' which fails at times
_winMoveTop(identifier)
{
  WinSetAlwaysOnTop("On")
  WinSetAlwaysOnTop("Off")
}

_getDesktopCount()
{
  return(_getDesktopInfo()["count"])
}

; _getDesktopIndex - return index of current desktop.
;
; Returns 0 if virtual desktops are not initialized or information cannot be retrieved.
_getDesktopIndex()
{
  return(_getDesktopInfo()["current_index"])
}

; _getDesktopInfo() - Returns hash of information about vdesks.
_getDesktopInfo()
{

  local session_id
  ; Get current desktop ID ( a binary 32-char string )
  DllCall("ProcessIdToSessionId",
          "UInt", DllCall("GetCurrentProcessId", "UInt"),
          "UInt*", session_id)
  local current_desktop_id := RegRead("HKEY_CURRENT_USER\Software\Microsoft\Windows\" .
                                    "CurrentVersion\Explorer\SessionInfo\" .
                                    session_id . "\VirtualDesktops", "CurrentVirtualDesktop") 
                              
  ; Length of a desktop id string (number of hex-characters)
  local id_length := StrLen(current_desktop_id)

  ; Calculate desktop count. This regkey consists of a concat of all desktop IDs
  local desktop_id_list := RegRead("HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VirtualDesktops", "VirtualDesktopIDs")
  local desktop_count := StrLen(desktop_id_list) / id_length
  
  local current_desktop_index
  local ii := 0
  while (ii < desktop_count) {
    local start_index := (ii * id_length) + 1
    local desktop_id := SubStr(desktop_id_list, start_index, id_length)

    if (desktop_id == current_desktop_id) {
      current_desktop_index := ii + 1
      break
    }
    ii++
  }

  result := {current_id :     current_desktop_id,
          current_index :  current_desktop_index,
                id_list :        desktop_id_list,
              id_length :              id_length,
                  count :          desktop_count}
  return(result)
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
   if (_getDesktopIndex() == 0) {
     ; Initialize virtual desktops
     switchDesktopByNumber(2)
     Sleep(100)
     switchDesktopByNumber(1)
   }

  SetKeyDelay 75
  DetectHiddenWindows true
  SetTitleMatchMode "RegEx"
  if (!WinExist(xserv_string))
  {
    ; BUG: Cannot start hidden window :(
    Run(vcxsrvpath)
  }
}  
