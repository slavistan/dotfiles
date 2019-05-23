let g:NVIMHOME=$HOME . '/.config/nvim'

"""
" Plugins
"""
execute 'call plug#begin(''' . g:NVIMHOME . '/plug-plugins'')'
Plug 'https://github.com/flazz/vim-colorschemes.git'
Plug 'https://github.com/airblade/vim-gitgutter.git'
Plug 'https://github.com/mboughaba/i3config.vim.git'
call plug#end()

"""
" Settings
"""
colorscheme milton

let &backupdir=g:NVIMHOME . '/backup'
let &directory=&backupdir
let &shadafile=&backupdir . '/shada'

set clipboard=unnamed
set ignorecase
set smartcase
set linebreak
set virtualedit=block
set path+=**
set updatetime=100
set scrolloff=999 " Center cursor vertically
set number
set signcolumn=yes
set textwidth=120
let mapleader=","

set list listchars=tab:‣\ ,trail:␣ " Display tabs and trailing whitespaces
set tabstop=2 softtabstop=2 shiftwidth=2 expandtab
set autoindent " Keep indentation level for wrapped lines
set breakindent " Wrapped lines preserve indentation

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

