-- ftplugin/htmlangular.lua
-- Same as html.lua

-- see :help html-indent
vim.g.html_indent_script1 = "zero"
vim.g.html_indent_style1 = "zero"
-- Don't indent first child of these tags
vim.g.html_indent_autotags = "html,head,body"

vim.bo.shiftwidth = 4
vim.bo.expandtab = true
