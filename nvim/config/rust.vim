" Configuration pertaining to the rust language

autocmd FileType rust call SetRustOptions()
function! SetRustOptions()

" Couldn't get ALE to work with rls, hence we use 'LanguageClient'. Note that
" RLS's refactoring features are absolutely abysmal. Any errors from attempts
" of renaming symbols probably stem from RLS and not the ls-client.
if !exists('g:LanguageClient_serverCommands')
  let g:LanguageClient_serverCommands={}
endif

let g:LanguageClient_serverCommands.rust = [
      \ 'rustup', 'run', 'nightly', 'rls']

let g:LanguageClient_autoStart = 1 " Automatically start language servers.

" Maps K to hover, gd to goto definition, F2 to rename
nnoremap <silent> <F1> :call LanguageClient_textDocument_hover()<CR>
nnoremap <silent> <F12> :call LanguageClient_textDocument_definition()<CR>
nnoremap <silent> <F2> :call LanguageClient_textDocument_rename()<CR>
nnoremap <silent> <F11> :call LanguageClient_textDocument_references()<CR>

""" ALE configuration

" Now list the linters and tools we want to use and configure them afterwards.
if !exists('g:ale_linters')
  let g:ale_linters={}
endif
let g:ale_linters.rust = [
      \ 'cargo']

""" Misc configuration
set textwidth=100
set formatoptions=r
set comments=srO:/*,mb:\ *,ex:\ */,://
endfunction
