augroup dkovimenhancedresolver
  autocmd!
  autocmd FileType javascript
        \ nmap <buffer> gf <Plug>(enhanced-resolver-go-cursor)
  autocmd FileType *
        \ nmap <buffer> gr <Plug>(enhanced-resolver-echo-cursor)
  autocmd FileType *
        \ nmap <buffer> gR <Plug>(enhanced-resolver-echo-resolve)
augroup END