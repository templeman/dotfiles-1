" plugin/plug-vim-qf.vim

if !dkoplug#Exists('vim-qf') | finish | endif

" Neomake handles
let g:qf_auto_open_quickfix = 0
let g:qf_auto_open_loclist = 0
let g:qf_auto_resize = 0 " flawed, does not expand

let s:cpo_save = &cpoptions
set cpoptions&vim

nmap [l <Plug>qf_loc_previous
nmap ]l <Plug>qf_loc_next
nmap [q <Plug>qf_qf_previous
nmap ]q <Plug>qf_qf_next

let &cpoptions = s:cpo_save
unlet s:cpo_save