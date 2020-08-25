
au BufEnter *.c,*.cpp,*.json call CocInit()

fun! CocInit()
  " Highlight the symbol and its references when holding the cursor. Lags hard.
  " autocmd CursorHold * silent call CocActionAsync('highlight')

  " Rename symbol.
  nmap <F2> <Plug>(coc-rename)

  nnoremap <silent> K :call CocAction('doHover')<cr>

  " gd - go to definition of word under cursor
  nmap <silent> gd <Plug>(coc-definition)
  nmap <silent> gy <Plug>(coc-type-definition)

  " gi - go to implementation
  nmap <silent> gi <Plug>(coc-implementation)

  " gr - find references
  nmap <silent> gr <Plug>(coc-references)

  " format selected range
  vmap <silent> gf  <Plug>(coc-format-selected)
endfun

" Notes on COC
"
"  + highlight on CursorHold lags when moving the cursor within the same identifier.
"  + How can I disable suggestions popping up? I cannot read my code.
"  + Cannot rename C macros ..
