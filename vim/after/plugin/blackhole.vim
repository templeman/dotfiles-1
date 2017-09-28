" ============================================================================
" Manual blackhole
" ============================================================================

if !dko#IsPlugged('vim-easyclip')
  function! s:Blackhole(k) abort
    let l:register = get(a:k, 2, a:k[0])
    let l:modes = split(a:k[1])
    let l:modes = empty(l:modes) ? [''] : l:modes
    for l:mode in l:modes
      execute l:mode . 'noremap ' . a:k[0] . ' "' . l:register . a:k[0]
    endfor
  endfunction

  let s:blackholes = [
        \   [ 'c', 'n' ],
        \   [ 'C', 'n' ],
        \   [ 'dd', '', 'd' ],
        \   [ 'd', '' ],
        \   [ 'D', 'n' ],
        \   [ 's', 'n' ],
        \   [ 'S', 'n' ],
        \   [ 'x', 'n' ],
        \   [ 'X', 'n' ],
        \ ]
  for s:item in s:blackholes
     call s:Blackhole(s:item)
  endfor

  let s:register = has('clipboard') ? '"*' : '""'
  let s:mapc = dko#IsPlugged('vim-yankstack') ? '' : ''
  execute       s:mapc . 'map m ' . s:register . 'd'
  execute 'o' . s:mapc . 'map m ' . s:register . 'd'
  "execute 'vnoremap m ' . s:register . 'd'
  execute       s:mapc . 'map M ' . s:register . 'dd'
  execute 'n' . s:mapc . 'map mm ' . s:register . 'dd'
endif

" ============================================================================

