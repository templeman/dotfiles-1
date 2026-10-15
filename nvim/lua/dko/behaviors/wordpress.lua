-- Restores what upstream dropped in 6d20b07b (after/plugin/wordpress.vim),
-- extended for Bedrock's web/app content dir

local augroup = require("dko.utils.autocmd").augroup
local autocmd = vim.api.nvim_create_autocmd

local WP_CODE_DIRS = {
  "/wp%-content/themes/",
  "/wp%-content/plugins/",
  "/mu%-plugins/",
  "/web/app/themes/",
  "/web/app/plugins/",
}

---@param path string
---@return boolean
local function is_wp_code(path)
  return vim.iter(WP_CODE_DIRS):any(function(dir)
    return path:find(dir) ~= nil
  end)
end

autocmd("FileType", {
  desc = "WordPress PHP/Blade buffer settings and mappings",
  pattern = { "php", "blade" },
  callback = function(args)
    require("dko.mappings").bind_wordpress(args.buf)

    -- Indent case: and default: in switch(). indent/php.vim resets the b: var
    -- from g:PHP_vintage_case_default_indent on every FileType (so upstream's
    -- BufReadPre version never took effect), and its FileType autocmd is
    -- registered after this one, hence the schedule.
    if
      args.match == "php"
      and is_wp_code(vim.api.nvim_buf_get_name(args.buf))
    then
      vim.schedule(function()
        if vim.api.nvim_buf_is_valid(args.buf) then
          vim.b[args.buf].PHP_vintage_case_default_indent = 1
        end
      end)
    end
  end,
  group = augroup("dkowordpress"),
})
