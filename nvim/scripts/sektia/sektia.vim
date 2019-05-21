" Plugin basepath
let s:path=expand('<sfile>:p:h')

"" Restore hooks
function! sektia#ClearHooks()
  augroup sektia
    au!
  augroup END
endfunction

"" Insert chapter heading
function! sektia#EnterHeadingMode()

  call sektia#ClearHooks()

  call search(s:chapter_heading)
  call setline(line('.'), substitute(getline('.'), s:chapter_heading, '', ''))
  call setline(line('.'), substitute(getline('.'), ' \*/$', repeat('~', strlen(s:chapter_heading)) . ' \*/', ''))
  startinsert " <-- BUG: This startinsert does not execute. Why?

endfunction

"" Insert chapter numbering
function! sektia#EnterIndexMode()

  "" Counteract spurios TextChangeI hook :(
  call setline(line('.'), substitute(getline('.'), '\~ \*/$', '~~ \*/', ''))
  augroup sektia
    "" l-move cursor to adjust for extra characters
    autocmd TextChangedI * call setline(line('.'), substitute(getline('.'), '\~ \*/$', ' \*/', ''))
    autocmd InsertLeave * call sektia#EnterHeadingMode()
  augroup END
  startinsert

endfunction


let s:chapter_heading="Chapter Heading"
function! SektiaInsertCppHeader()

  " Insert fence
  call append(line('.'), repeat(' ', col('.')-1) . '/* ' . repeat('~', &textwidth-col('.')-5) . ' */')
  " Insert middle line
  call append(line('.'), repeat(' ', col('.')-1) . '/* ~ () ~ ' . s:chapter_heading . ' ' . repeat('~', &textwidth-col('.')-13-strlen(s:chapter_heading)) . ' */')
  " Insert fence
  call append(line('.'), repeat(' ', col('.')-1) . '/* ' . repeat('~', &textwidth-col('.')-5) . ' */')
  " start inserting
  call search(')')

  call sektia#EnterIndexMode()

endfunction

