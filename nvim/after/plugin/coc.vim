if !exists('g:coc_enabled')
  finish
endif

" Highlight the symbol and its references when holding the cursor.
autocmd CursorHold * silent call CocActionAsync('highlight')

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

nmap <leader> cf  <Plug>(coc-format-selected)
