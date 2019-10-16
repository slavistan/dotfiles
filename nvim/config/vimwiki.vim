" Configuration pertaining to vimwikis

" Stuff that's executed prior to loading the plugin.

function! VimwikiPreLoad()
  let g:vimwiki_key_mappings = { 'links': 0, }
endfunction

autocmd FileType vimwiki call SetVimwikiOptions()
function! SetVimwikiOptions()

  " Remap what was mapped to tab and restore all the other keymappings which we
  " deleted above to their defaults.

  nmap m <Plug>VimwikiNextLink
  nmap M <Plug>VimwikiPrevLink
  nmap <Leader>w<Leader>i <Plug>VimwikiDiaryGenerateLinks
  nmap <CR> <Plug>VimwikiFollowLink
  nmap <Backspace> <Plug>VimwikiGoBackLink
  nmap <Leader>wd <Plug>VimwikiDeleteLink
  nmap <Leader>wr <Plug>VimwikiRenameLink
  nmap <Leader>dn <Plug>VimwikiDiaryNextDay
  nmap <Leader>dN <Plug>VimwikiDiaryPrevDay
  nmap + <Plug>VimwikiNormalizeLink
  vmap + <Plug>VimwikiNormalizeLinkVisual

endfunction
