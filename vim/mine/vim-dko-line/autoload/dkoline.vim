" autoload/dkoline.vim
scriptencoding utf-8

function! dkoline#GetTabline() abort
  "let g:dkoline#trefresh += 1
  let l:contents = '%#StatusLine#'
  let l:contents .= dkoline#Part({
        \   'heading':  '%#Pmenu# ? ',
        \   'color':    '%#Search#',
        \   'function': 'anzu#search_status',
        \ })
  let l:contents .= '%#StatusLine# %= '
  let l:contents .= dkoline#Part({
        \   'heading':  '%#Pmenu# ʟᴄᴅ ',
        \   'color':    '%#PmenuSel#',
        \   'format':   '0.' . (float2nr(&columns / 2) - 20),
        \   'raw':      '%{dko#ShortenPath(getcwd())}',
        \ })
  let l:contents .= dkoline#Part({
        \   'heading':  '%#Pmenu# ᴘʀᴏᴊ ',
        \   'color':    '%#PmenuSel#',
        \   'format':   '0.' . (float2nr(&columns / 2) - 20),
        \   'raw':      '%{dko#ShortenPath(dkoproject#GetRoot())}',
        \ })
  return l:contents
endfunction

" a:winnr from dkoline#Refresh() or 0 on set statusline
function! dkoline#GetStatusline() abort
  let l:winnr = winnr()
  if !l:winnr | return | endif

  let l:bufnr = winbufnr(l:winnr)
  let l:ww    = winwidth(l:winnr)
  let l:cwd   = has('nvim') ? getcwd(l:winnr) : getcwd()

  let l:x = {
        \   'bufnr': l:bufnr,
        \   'ww': l:ww,
        \ }

  let l:contents = ''

  " ==========================================================================
  " Left side
  " ==========================================================================

  let l:contents .= dkoline#Part({
        \   'color':  '%#TabLine#',
        \   'raw':    dkoline#Mode(l:winnr),
        \ })

  " Filebased
  let l:contents .= dkoline#Format(dkoline#Filetype(l:bufnr), '%#StatusLine#')

  let l:maxwidth = l:ww - 32
  let l:contents .= dkoline#Format(
        \   dkoline#Filename(l:bufnr, l:cwd),
        \   '%#PmenuSel#%0.' . l:maxwidth . '(',
        \   '%)'
        \ )
  let l:contents .= dkoline#Format(dkoline#Dirty(l:bufnr), '%#DiffAdded#')

  " Toggleable
  if !has('nvim')
    let l:contents .= dkoline#Format(dkoline#Paste(), '%#DiffText#')
  endif

  let l:contents .= dkoline#Format(dkoline#Readonly(l:bufnr), '%#Error#')

  " Function
  if get(g:, 'dkoline_enabled_functioninfo', 0)
    let l:contents .= dkoline#Format(
          \ dkoline#If({
          \   'winnr': l:winnr,
          \   'ww': 80,
          \ }, l:x) ? dkoline#FunctionInfo() : '',
          \ '%#PMenu# ғᴜɴᴄ %#PmenuSel#')
  endif

  " ==========================================================================
  " Right side
  " ==========================================================================

  let l:contents .= '%*%='

  " Tagging
  let l:contents .= dkoline#Format(dkoline#GutentagsStatus(), '%#TermCursor#')

  " Linting
  if dko#IsLoaded('neomake') && exists('*neomake#GetJobs')
    let l:contents .= dkoline#Format(
          \ dkoline#Neomake('E', neomake#statusline#LoclistCounts(l:bufnr)),
          \ '%#NeomakeErrorSign#')

    let l:contents .= dkoline#Format(
          \ dkoline#Neomake('W', neomake#statusline#LoclistCounts(l:bufnr)),
          \ '%#NeomakeWarningSign#')

    let l:contents .= dkoline#Format(
          \ dkoline#NeomakeRunning(l:bufnr),
          \ '%#DiffText#')
  endif

  let l:contents .= '%<'

  let l:contents .= dkoline#Format(dkoline#Ruler(), '%#TabLine#')

  return l:contents
endfunction

" ============================================================================
" Output functions
" ============================================================================

" @param {String} content
" @param {String} [before]
" @param {String} [after]
" @return {String}
function! dkoline#Format(...) abort
  let l:content = get(a:, 1, '')
  let l:before = get(a:, 2, '')
  let l:after = get(a:, 3, '')
  return empty(l:content) ? '' : l:before . l:content . l:after
endfunction

function! dkoline#If(conditions, values) abort
  if has_key(a:conditions, 'winnr')
    if winnr() != a:conditions.winnr | return 0 | endif
  endif

  if has_key(a:conditions, 'ww')
    if a:values.ww < a:conditions.ww | return 0 | endif
  endif

  return 1
endfunction

" @return {String}
function! dkoline#Mode(winnr) abort
  if a:winnr != winnr() | return '' | endif
  let l:modeflag = mode()
  if l:modeflag ==# 'i'
    return '%#PmenuSel# ' . l:modeflag . ' '
  elseif l:modeflag ==# 'R'
    return '%#DiffDelete# ' . l:modeflag . ' '
  elseif l:modeflag =~? 'v'
    return '%#Cursor# ' . l:modeflag . ' '
  elseif l:modeflag ==? "\<C-v>"
    return '%#Cursor# B '
  endif
  return ' ? '
endfunction

" @return {String}
function! dkoline#Paste() abort
  return empty(&paste)
        \ ? ''
        \ : ' ᴘ '
endfunction

" @param {String} key
" @param {Dict} counts
" @return {String}
function! dkoline#Neomake(key, counts) abort
  let l:e = get(a:counts, a:key, 0)
  return l:e ? ' ⚑' . l:e . ' ' : ''
endfunction

" @param {Int} bufnr
" @return {String}
function! dkoline#NeomakeRunning(bufnr) abort
  let l:running_jobs = filter(copy(neomake#GetJobs()),
        \ 'v:val.bufnr == ' . a:bufnr . ' && !get(v:val, "canceled", 0)')
  if empty(l:running_jobs) | return | endif

  let l:names = join(map(l:running_jobs, 'v:val.name'), ',')
  return ' ᴍᴀᴋᴇ:' . l:names . ' '
endfunction

" @param {Int} bufnr
" @return {String} comma-delimited running job names
function! dkoline#NeomakeRunningJobs(bufnr) abort
endfunction

" @param {Int} bufnr
" @return {String}
function! dkoline#Readonly(bufnr) abort
  return getbufvar(a:bufnr, '&readonly') ? ' ʀ ' : ''
endfunction

" @param {Int} bufnr
" @return {String}
function! dkoline#Filetype(bufnr) abort
  let l:ft = getbufvar(a:bufnr, '&filetype')
  return empty(l:ft)
        \ ? ''
        \ : ' ' . l:ft . ' '
endfunction

" Filename of buffer relative to the path, or just the helpfile name if it is
" a help file
"
" @param {Int} bufnr
" @param {String} path
" @return {String}
function! dkoline#Filename(bufnr, path) abort
  if dko#IsNonFile(a:bufnr)
    return ''
  endif

  let l:filename = bufname(a:bufnr)
  if empty(l:filename)
    let l:contents = '[No Name]'
  else
    let l:contents = dko#IsHelp(a:bufnr)
          \ ? '%t'
          \ : fnamemodify(substitute(l:filename, a:path, '.', ''), ':~:.')
  endif

  return ' ' . l:contents . ' '
endfunction

" @param {Int} bufnr
" @return {String}
function! dkoline#Dirty(bufnr) abort
  return getbufvar(a:bufnr, '&modified') ? ' + ' : ''
endfunction

" @return {String}
function! dkoline#Anzu() abort
  if !exists('*anzu#search_status')
    return ''
  endif

  let l:anzu = anzu#search_status()
  return empty(l:anzu)
        \ ? ''
        \ : ' %{anzu#search_status()} '
endfunction

" Use dko#ShortenPath conditionally
"
" @param {Int} bufnr
" @param {String} path
" @param {Int} max
" @return {String}
function! dkoline#ShortPath(bufnr, path, max) abort
  if dko#IsNonFile(a:bufnr) || dko#IsHelp(a:bufnr)
    return ''
  endif
  let l:path = dko#ShortenPath(a:path, a:max)
  return empty(l:path)
        \ ? ''
        \ : l:path
endfunction

" @return {String}
function! dkoline#FunctionInfo() abort
  let l:funcinfo = dkocode#GetFunctionInfo()
  return empty(l:funcinfo.name)
        \ ? ''
        \ : ' ' . l:funcinfo.name . ' '
endfunction

" @return {String}
function! dkoline#GutentagsStatus() abort
  if !exists('g:loaded_gutentags')
    return ''
  endif

  let l:tagger = substitute(gutentags#statusline(''), '\[\(.*\)\]', '\1', '')
  return empty(l:tagger)
        \ ? ''
        \ : ' ᴛᴀɢ:' . l:tagger . ' '
endfunction

" @return {String}
function! dkoline#Ruler() abort
  return ' %5.(%c%) '
endfunction

" ============================================================================
" Utility
" ============================================================================

function! dkoline#Init() abort
  " let g:dkoline#refresh = 0
  " let g:dkoline#trefresh = 0
  " let g:dkoline#srefresh = 0

  set statusline=%!dkoline#GetStatusline()
  call dkoline#RefreshTabline()
  set showtabline=2

  let l:refresh_hooks = [
        \   'BufEnter',
        \ ]
        " \   'BufWinEnter',
        " \   'SessionLoadPost',
        " \   'TabEnter',
        " \   'VimResized',
        " \   'WinEnter',
        " \   'FileType',
        " \   'FileWritePost',
        " \   'FileReadPost',
        " \   'BufEnter' for different buffer
        " \   'CursorMoved' is for updating anzu search status accurately,
        "     using Plug mapping instead.

  let l:user_refresh_hooks = [
        \   'GutentagsUpdated',
        \   'NeomakeFinished',
        \ ]
  " 'NeomakeCountsChanged',

  " if !empty(l:refresh_hooks)
  "   execute 'autocmd plugin-dkoline ' . join(l:refresh_hooks, ',') . ' *'
  "         \ . ' call dkoline#RefreshStatusline()'
  " endif
  " if !empty(l:user_refresh_hooks)
  "   execute 'autocmd plugin-dkoline User ' . join(l:user_refresh_hooks, ',')
  "         \ . ' call dkoline#RefreshStatusline()'
  " endif
endfunction

function! dkoline#RefreshTabline() abort
  set tabline=%!dkoline#GetTabline()
endfunction

" bound to <F11> - see ../plugin/mappings.vim
function! dkoline#ToggleTabline() abort
  let &showtabline = &showtabline ? 0 : 2
endfunction

function! dkoline#Part(settings) abort
  let l:text = dkoline#GetText(a:settings)
  if empty(l:text) | return '' | endif
  let l:format_start = dkoline#GetFormat(a:settings)
  let l:format_end = (!empty(l:format_start) ? '%)' : '')
  return get(a:settings, 'heading', '')
        \ . get(a:settings, 'color', '')
        \ . l:format_start . l:text . l:format_end
endfunction

function! dkoline#GetText(settings) abort
  if !empty(get(a:settings, 'raw', ''))
    return a:settings.raw
  elseif !empty(get(a:settings, 'function', ''))
        \ && exists('*' . a:settings.function)
    let l:args = get(a:settings, 'args', [])
    return call(a:settings.function, l:args)
  endif
  return ''
endfunction

function! dkoline#GetFormat(settings) abort
  return !empty(get(a:settings, 'format', ''))
        \ ? '%' . a:settings.format . '('
        \ : ''
endfunction
