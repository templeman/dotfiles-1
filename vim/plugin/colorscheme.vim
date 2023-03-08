" plugin/colorscheme.vim

if g:truecolor
  let &termguicolors = 1

  if dkoplug#Exists('templeman/vim-solarized8')
    function! s:Solarized() abort
      silent! colorscheme solarized8_high
    endfunction

    let s:cpo_save = &cpoptions
    set cpoptions&vim

    nnoremap <silent><special> <Leader>zt
          \ :<C-U>call <SID>Solarized()<CR>:set bg=dark<CR>

    let &cpoptions = s:cpo_save
    unlet s:cpo_save

  endif
endif

augroup dkocolorscheme
  autocmd! VimEnter * nested silent! execute 'colorscheme solarized8'
augroup END
