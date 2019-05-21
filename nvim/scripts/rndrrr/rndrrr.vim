"
" This script executes some type of 'build' command based on the given filetype.
"
function! rndrrr#RmdRender()
  execute '!R -q -e ''rmarkdown::render("' . expand('%:p') . '")'''
endfunction

function! rndrrr#RmdRenderAndShow()
  let l:outfile = tempname()
  execute 'silent !R -q -e ''rmarkdown::render("' . expand('%:p') . '", output_file="' . outfile . '")'''
  execute ':!' . $BROWSER . ' ' . outfile
endfunction

function! rndrrr#AsyRender()
  execute 'silent !asy ' . expand('%:p')
  redraw!
endfunction

function! rndrrr#AsyRenderAndShow()
  execute 'silent !asy ' . expand('%:p')
  execute 'silent !evince ' . expand('%:r') . '.eps > /dev/null 2>&1 &'
endfunction

augroup rndrrr
  autocmd FileType rmd nmap <F5> :call rndrrr#RmdRender()<CR>
  autocmd FileType rmd nmap <F6> :call rndrrr#RmdRenderAndShow()<CR>

  autocmd FileType asy nmap <F5> :call rndrrr#AsyRender()<CR>
  autocmd FileType asy nmap <F6> :call rndrrr#AsyRenderAndShow()<CR>
augroup END
