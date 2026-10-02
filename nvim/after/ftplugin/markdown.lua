-- Use in conjunction with ZenMode.nvim to wrap line length for readability.
-- See also https://github.com/folke/zen-mode.nvim/issues/64 for the option to
-- toggle soft wrapping in conjunction with ZenMode.nvim.
-- vim.opt_local.textwidth = 0
-- vim.opt_local.wrapmargin = 0
vim.opt_local.wrap = true
-- vim.opt_local.number = true
vim.opt_local.linebreak = true

-- Align the table under the cursor, like `gaip|` from mini.align. linebreak is
-- off while it runs: with it on, strdisplaywidth() counts wrap padding for rows
-- wider than the window, so mini.align under-pads them.
vim.keymap.set("n", "<Leader>ta", function()
  local function is_row(lnum)
    return vim.fn.getline(lnum):match("^%s*|") ~= nil
  end
  local first, last = vim.fn.line("."), vim.fn.line(".")
  if not is_row(first) then
    vim.notify("Not in a table", vim.log.levels.WARN)
    return
  end
  while first > 1 and is_row(first - 1) do
    first = first - 1
  end
  while last < vim.fn.line("$") and is_row(last + 1) do
    last = last + 1
  end

  local align = require("mini.align")
  local rows = vim.api.nvim_buf_get_lines(0, first - 1, last, false)
  local linebreak = vim.wo.linebreak
  vim.wo.linebreak = false
  local ok, aligned = pcall(
    align.align_strings,
    rows,
    { split_pattern = "|", merge_delimiter = " " },
    { pre_justify = { align.gen_step.trim() } }
  )
  vim.wo.linebreak = linebreak
  if not ok then
    error(aligned)
  end
  vim.api.nvim_buf_set_lines(0, first - 1, last, false, aligned)
end, { buffer = true, desc = "Align markdown table under cursor" })
