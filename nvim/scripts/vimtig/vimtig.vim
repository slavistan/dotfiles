" Git wrappers

function! VimtigCommit()
  silent lcd %:p:h " Change working directory to file's directory
  " TODO: How to edit the commit message in a regular buffer?
  "       This currently opens a terminal buffer, within which another instance
  "       of nvim is run.
  augroup TerminalStuff
    au!
    autocmd TermOpen * setlocal nonumber norelativenumber
  augroup END
  edit term://git commit --verbose
  silent lcd - " Get back to original working directory
endfunction

function! VimtigPush()
  silent lcd %:p:h
  !git push
  silent lcd -
endfunction

function! VimtigStageFullBuffer()
  silent lcd %:p:h
  !git add %:p
  silent lcd -
endfunction
