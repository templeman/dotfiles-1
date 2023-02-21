" after/ftplugin/scss.vim

call dko#TwoSpace()
setlocal iskeyword+=-

" Automatically insert the current comment leader after hitting <Enter>
" in Insert mode respectively after hitting 'o' or 'O' in Normal mode
setlocal formatoptions+=ro
