let g:NVIMHOME=$DOTFILES . '/nvim'

"""
" Settings
"
" Some settings must preceed the loading of plugins.
"""
set termguicolors
colorscheme milton

let &backupdir=g:NVIMHOME . '/backup'
let &directory=&backupdir
let &shadafile=&backupdir . '/shada'
let g:netrw_home=&backupdir

set clipboard=unnamed
set foldlevelstart=0 " Files are opened with all folds closed
set noincsearch
set smartcase
set linebreak
set virtualedit=block
set path+=**
set updatetime=100
set scrolloff=999 " Center cursor vertically
set number
set signcolumn=yes
set textwidth=999
set modeline
set showbreak=↪
let mapleader=","
let maplocalleader="\\"

set list listchars=tab:‣\ ,trail:· " Display tabs and trailing whitespaces
set tabstop=2 softtabstop=2 shiftwidth=2 expandtab
set autoindent " Keep indentation level for wrapped lines
set breakindent " Wrapped lines preserve indentation

"""
" PRE- Settings: Filtype specifics & Plugin settings
"""
let g:R_assign=0 " Disable automatic substitution of _

"""
" Plugins
"""
execute 'call plug#begin(''' . g:NVIMHOME . '/plug-plugins'')'
Plug 'https://github.com/flazz/vim-colorschemes.git'
Plug 'https://github.com/airblade/vim-gitgutter.git'
Plug 'https://github.com/mboughaba/i3config.vim.git'
Plug 'https://github.com/jalvesaq/Nvim-R.git'
Plug 'https://github.com/jeffkreeftmeijer/vim-dim.git'
Plug 'https://github.com/godlygeek/tabular.git'
Plug 'https://github.com/thaerkh/vim-indentguides.git'
Plug 'https://github.com/vim-pandoc/vim-pandoc-syntax.git'
Plug 'https://github.com/vim-pandoc/vim-pandoc.git'
call plug#end()

"""
" Key mappings
"""
nnoremap ; :
vnoremap ; :
nnoremap <Leader>yy ^yg_
nnoremap <Leader>dd ^dg_

" Use regular movement keys to navigate normally across wrapped lines
noremap <buffer> <silent> k gk
noremap <buffer> <silent> j gj
noremap <buffer> <silent> 0 g0
noremap <buffer> <silent> $ g$
onoremap <silent> j gj
onoremap <silent> k gk

" Tab behaviour
nnoremap <Tab> >>
nnoremap <S-Tab> <<
vnoremap <Tab> >gv
vnoremap <S-Tab> <gv
inoremap <S-Tab> <Backspace>

"""
" POST- Settings: Filtype specifics & Plugin settings
"""
autocmd FileType Rmd,rmd call SetRmdOptions()
function SetRmdOptions()
  set textwidth=120
  set conceallevel=0 " Nvim-R conceals a lot
  " Send code R 
  nnoremap <Space>l :call SendLineToR("stay")<CR>
  " Send selection. <Esc> before 'call' removes '<,'> which causes the selection to be sent multiple times
  vnoremap <Space>s <Esc>:call SendSelectionToR("echo", "stay")<CR><Esc>
  nnoremap <Space>c :call b:SendChunkToR("echo", "stay")<CR>
  vnoremap <F1> "1y:execute 'Rhelp ' . getreg('1')<CR>

  " Manual folding
  set foldmethod=manual
  set sessionoptions=folds
  set viewoptions=folds
  set viewdir=.vim
  autocmd BufWinLeave *.rmd,*.Rmd mkview
  autocmd BufWinEnter *.rmd,*.Rmd silent loadview
endfunction

let g:indentguides_spacechar = '┊'
let g:indentguides_tabchar = '┊'

let g:pandoc#syntax#conceal#use = 0
let g:pandoc#modules#disabled = [ "spell" ]

autocmd FileType autohotkey call SetAhkOptions()
function SetAhkOptions()
  " Reload script automatically
  autocmd BufWritePost *.ahk silent execute ':!AutoHotkeyU64.exe ' . expand('%') . ' &'
endfunction
"""
" Utility
"""
" Show highlight groups under cursor
function! SynStack()
  if !exists("*synstack")
    return
  endif
  echo map(synstack(line('.'), col('.')), 'synIDattr(v:val, "name")')
endfunc
