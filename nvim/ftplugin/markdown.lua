local bufname = vim.api.nvim_buf_get_name(0)

if vim.b.has_markdownlint == nil then
  local search_path = bufname ~= "" and vim.fs.dirname(bufname) or nil
  local search_names = {
    ".markdownlint.json",
    ".markdownlint.jsonc",
    ".markdownlint.yaml",
    ".markdownlintrc",
  }

  local has_markdownlint = false
  if search_path then
    has_markdownlint = #vim.fs.find(search_names, {
      limit = 1,
      path = search_path,
      type = "file",
      upward = true,
    }) > 0
  end

  if not has_markdownlint then
    local home_configs = {
      vim.fn.expand("~/.markdownlint.json"),
      vim.fn.expand("~/.markdownlint.jsonc"),
      vim.fn.expand("~/.markdownlint.yaml"),
      vim.fn.expand("~/.markdownlintrc"),
      vim.fn.expand("~/.config/markdownlint/config"),
    }
    for _, config_path in ipairs(home_configs) do
      if config_path ~= "" and vim.loop.fs_stat(config_path) then
        has_markdownlint = true
        break
      end
    end
  end

  vim.b.has_markdownlint = has_markdownlint
end

vim.b.formatter = vim.b.has_markdownlint == true and "markdownlint"
  or "prettier"
