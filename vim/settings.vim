let vimsettings = '~/.vim/settings'
let uname = system("uname -s")

for fpath in split(globpath(vimsettings, '*.vim'), '\n')

  if (fpath == expand(vimsettings) . "/dotdotdot-keymap-mac.vim") && uname[:4] ==? "linux"
    continue " skip mac mappings for linux
  endif

  if (fpath == expand(vimsettings) . "/dotdotdot-keymap-linux.vim") && uname[:4] !=? "linux"
    continue " skip linux mappings for mac
  endif

  exe 'source' fpath
endfor

" Turn spellcheck on for markdown files.
" autocmd BufNewFile,BufRead *.md set spell

" Make sure the lightline status bar always shows up
" set laststatus=2

" Turn off syntax highlighting on very long lines (performance boost)
" set synmaxcol=256
