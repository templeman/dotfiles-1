" plugin/clipboard.vim

let s:cpo_save = &cpoptions
set cpoptions&vim

augroup dkoclipboard
  autocmd!
augroup END

" ============================================================================
" EasyClip
" ============================================================================

if dko#IsLoaded('vim-easyclip')
  " explicitly do NOT remap s/S to paste register
  let g:EasyClipUseSubstituteDefaults = 0

  " Don't override pastetoggle
  let g:EasyClipUseGlobalPasteToggle = 0
endif

" ============================================================================
" vim-yankstack
" ============================================================================

if dko#IsPlugged('vim-yankstack')
  let g:yankstack_yank_keys = ['m', 'y', 'Y']
  autocmd dkoclipboard User vim-yankstack call yankstack#setup()

  function! s:MapYankstack() abort
    nmap <C-p> <Plug>yankstack_substitute_older_paste
    " xmap <M-p> <Plug>yankstack_substitute_older_paste
    " imap <M-p> <Plug>yankstack_substitute_older_paste
    nmap <C-n> <Plug>yankstack_substitute_newer_paste
    " xmap <M-P> <Plug>yankstack_substitute_newer_paste
    " imap <M-P> <Plug>yankstack_substitute_newer_paste
  endfunction
  autocmd dkoclipboard User vim-yankstack call s:MapYankstack()

  call plug#load('vim-yankstack')
endif

let &cpoptions = s:cpo_save
unlet s:cpo_save
