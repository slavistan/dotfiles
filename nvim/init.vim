" TODO:
" List number of matches when searching (custom command?)
" Incsearch without the adhs jumps
let g:NVIMHOME=$XDG_CONFIG_HOME . '/nvim'

"""
" Settings
"
" Some settings must preceed the loading of plugins.
"""
set termguicolors

let &backupdir=g:NVIMHOME . '/backup'
let &directory=&backupdir
let &shadafile=&backupdir . '/shada'
let g:netrw_home=&backupdir

set clipboard=unnamedplus
set foldlevelstart=0 " Files are opened with all folds closed
set noincsearch
set ignorecase
set smartcase
set linebreak
set virtualedit=block
set path+=**
set scrolloff=999 " Center cursor vertically
set number " show linenumbers
set textwidth=999
set modeline
set showbreak=↪
let mapleader=","
let maplocalleader="\\"

set nowrap " Disable wrapping by default
" Display tabs and trailing whitespaces
set list
set listchars=tab:⇤-⇥
set listchars+=trail:·
set listchars+=extends:⋯
set listchars+=precedes:⋯
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
Plug 'https://github.com/airblade/vim-gitgutter.git'
Plug 'https://github.com/mboughaba/i3config.vim.git'
Plug 'https://github.com/jalvesaq/Nvim-R.git'
Plug 'https://github.com/godlygeek/tabular.git'
Plug 'https://github.com/vim-pandoc/vim-pandoc-syntax.git'
Plug 'https://github.com/vim-pandoc/vim-pandoc.git'
Plug 'https://github.com/w0rp/ale.git'
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
autocmd FileType Rmd,rmd,r call SetRmdOptions()
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
" TODO: Check if a view-file exists prior to opening it.
"  autocmd BufWinLeave *.rmd,*.Rmd mkview
"  autocmd BufWinEnter *.rmd,*.Rmd silent loadview | foldclose!
endfunction

let g:pandoc#syntax#conceal#use = 0
let g:pandoc#modules#disabled = [ "spell" ]

autocmd FileType autohotkey call SetAhkOptions()
function SetAhkOptions()
  " Reload script automatically
  autocmd BufWritePost *.ahk silent execute ':!AutoHotkeyU64.exe ' . expand('%') . ' &'
endfunction

" Source submodules
"
exe 'source ' . g:NVIMHOME . '/config/cpp.vim'

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

"""
" gitgutter
"""
set updatetime=100 " lessen reaction time
let g:gitgutter_enabled=0 " don't run by default
let g:gitgutter_highlight_lines=1 " highlight lines by default
" toggle on/off
nnoremap <Leader>gg :GitGutterToggle<CR>
" toggle folding of unchanged lines
nnoremap <Leader>gi :GitGutterFold<CR>
" move between hunks
nnoremap <Leader>gn :GitGutterNextHunk<CR>
nnoremap <Leader>gN :GitGutterPrevHunk<CR>
" stage a hunk
nnoremap <Leader>gs :GitGutterStageHunk<CR>
" undo a hunk
nnoremap <Leader>gu :GitGutterUndoHunk<CR>
" review a hunk in split screen
nnoremap <Leader>gp :GitGutterPreviewHunk<CR>
let g:gitgutter_sign_added = '++'
let g:gitgutter_sign_modified = '≠≠'
let g:gitgutter_sign_removed = '--'
let g:gitgutter_sign_removed_first_line ='--'
let g:gitgutter_sign_modified_removed = '≠≠'

colorscheme milton " postpone loading of colorscheme so that plugins' hi groups will be known
