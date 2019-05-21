" Git wrappers

function! VimtigCommit()
  silent lcd %:p:h " Change working directory to file's directory
  !git commit --verbose
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
