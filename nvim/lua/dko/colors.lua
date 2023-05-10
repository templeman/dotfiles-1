local M = {}

M.indent_blankline = function()
  if vim.g.colors_name == "solarized8" then
    vim.cmd([[
              highlight IndentBlanklineIndent2 guibg=#003542 gui=nocombine
              highlight IndentBlanklineContextChar guifg=#005469 gui=nocombine
            ]])
  else
    vim.cmd([[
              highlight IndentBlanklineIndent2 guibg=#fafafa gui=nocombine
              highlight IndentBlanklineContextChar guifg=#eeeeee gui=nocombine
            ]])
  end
end

return M
