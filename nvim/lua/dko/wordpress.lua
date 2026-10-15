-- WordPress helpers: docs lookup and wp-cli runner
--
-- Overrides (set in a local config or exrc):
--   vim.g.wp_cli_cmd       string[] full command prefix, e.g. { "wp", "@staging" }
--   vim.g.wp_trellis_site  site key in trellis wordpress_sites.yml, defaults to
--                          the key whose local_path is this site/ dir

local M = {}

local REFERENCE = "https://developer.wordpress.org/reference"

local HOOK_FNS = {
  "add_action",
  "add_filter",
  "apply_filters",
  "apply_filters_ref_array",
  "do_action",
  "do_action_ref_array",
  "has_action",
  "has_filter",
  "remove_action",
  "remove_filter",
}

-- ===========================================================================
-- Docs
-- ===========================================================================

---Hook name if the cursor is on the first arg of a hook function call
---@return string|nil
local function hook_under_cursor()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2] + 1
  for _, fn in ipairs(HOOK_FNS) do
    local init = 1
    while true do
      local s, e, hook = line:find(fn .. "%s*%(%s*['\"]([^'\"]+)['\"]", init)
      if not s then
        break
      end
      if col >= s and col <= e then
        return hook
      end
      init = e + 1
    end
  end
  return nil
end

---@return string|nil url
M.docs_url = function()
  local hook = hook_under_cursor()
  if hook then
    -- dynamic hooks like save_post_{$post->post_type} have mangled slugs
    if hook:find("[{$]") then
      return ("https://developer.wordpress.org/?s=%s"):format(
        vim.uri_encode(hook)
      )
    end
    return ("%s/hooks/%s/"):format(REFERENCE, hook:lower())
  end

  local word = vim.fn.expand("<cword>")
  if word == "" then
    return nil
  end
  if word:match("^%u") then
    return ("%s/classes/%s/"):format(REFERENCE, word:lower())
  end
  return ("%s/functions/%s/"):format(REFERENCE, word)
end

M.open_docs = function()
  local url = M.docs_url()
  if not url then
    vim.notify("Nothing to look up", vim.log.levels.WARN, { title = "WP" })
    return
  end
  vim.ui.open(url)
end

-- ===========================================================================
-- wp-cli
-- ===========================================================================

---Bedrock (wp-cli.yml) or classic (wp-config.php) root
---@param bufnr? integer
---@return string|nil
M.site_root = function(bufnr)
  bufnr = bufnr or 0
  ---@type integer|string
  local source = vim.api.nvim_buf_get_name(bufnr) ~= "" and bufnr
    or vim.uv.cwd()
  return vim.fs.root(source, {
    "wp-cli.yml",
    { "wp-config.php", "wp-config-sample.php" },
  })
end

---Site key from trellis/group_vars/development/wordpress_sites.yml whose
---local_path points at site_root, else the first key. Naive line-based parse;
---Trellis generates this file with a consistent 2-space layout.
---@param trellis_dir string
---@param site_root string
---@return string|nil
M.trellis_site_key = function(trellis_dir, site_root)
  local file = vim.fs.joinpath(
    trellis_dir,
    "group_vars",
    "development",
    "wordpress_sites.yml"
  )
  if vim.fn.filereadable(file) == 0 then
    return nil
  end

  local real_root = vim.uv.fs_realpath(site_root)
  local first, current
  for _, line in ipairs(vim.fn.readfile(file)) do
    local key = line:match("^  ([%w%.%-_]+):%s*$")
    if key then
      current = key
      first = first or key
    end
    local local_path = line:match("^%s+local_path:%s*['\"]?([^'\"#%s]+)")
    if current and local_path then
      local resolved =
        vim.uv.fs_realpath(vim.fs.joinpath(trellis_dir, local_path))
      if resolved and resolved == real_root then
        return current
      end
    end
  end
  return first
end

---Trellis project info if site_root is a Trellis site/ dir
---@param site_root string
---@return { dir: string, site: string }|nil
M.trellis = function(site_root)
  local project = vim.fs.dirname(site_root)
  local trellis_dir = vim.fs.joinpath(project, "trellis")
  if vim.fn.isdirectory(trellis_dir) == 0 then
    return nil
  end
  return {
    dir = trellis_dir,
    site = vim.g.wp_trellis_site
      or M.trellis_site_key(trellis_dir, site_root)
      or vim.fs.basename(project),
  }
end

---@param args string[]
---@return string[] cmd, string cwd
M.build_cmd = function(args)
  local root = M.site_root() or vim.uv.cwd() --[[@as string]]

  if vim.g.wp_cli_cmd then
    return vim.list_extend(vim.deepcopy(vim.g.wp_cli_cmd), args), root
  end

  local trellis = M.trellis(root)
  if trellis then
    local workdir = ("/srv/www/%s/current"):format(trellis.site)
    local cmd = { "trellis", "vm", "shell", "--workdir", workdir, "--", "wp" }
    return vim.list_extend(cmd, args), trellis.dir
  end

  local local_wp = vim.fs.joinpath(root, "vendor", "bin", "wp")
  local wp = vim.fn.executable(local_wp) == 1 and local_wp or "wp"
  return vim.list_extend({ wp }, args), root
end

local INTERACTIVE = { shell = true, db = { cli = true, query = true } }

---@param args string[]
local function is_interactive(args)
  local entry = INTERACTIVE[args[1]]
  if entry == true then
    return true
  end
  return type(entry) == "table" and entry[args[2]] == true and #args == 2
end

---@param args string[]
M.run = function(args)
  local cmd, cwd = M.build_cmd(args)

  if is_interactive(args) then
    vim.cmd("botright split")
    vim.cmd.lcd(vim.fn.fnameescape(cwd))
    vim.cmd.terminal(table.concat(vim.tbl_map(vim.fn.shellescape, cmd), " "))
    return
  end

  vim.notify(table.concat(cmd, " "), vim.log.levels.INFO, { title = "WP" })
  vim.system(cmd, { cwd = cwd, text = true }, function(res)
    vim.schedule(function()
      local out = (res.stdout or "") .. (res.stderr or "")
      local lines = vim.split(vim.trim(out), "\n")
      vim.cmd("botright new")
      local buf = vim.api.nvim_get_current_buf()
      vim.bo[buf].buftype = "nofile"
      vim.bo[buf].bufhidden = "wipe"
      vim.bo[buf].swapfile = false
      vim.api.nvim_buf_set_name(
        buf,
        ("wp://%s#%d"):format(table.concat(args, " "), buf)
      )
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
      vim.bo[buf].modifiable = false
      vim.bo[buf].filetype = "text"
      if res.code ~= 0 then
        vim.notify(
          ("wp exited %d"):format(res.code),
          vim.log.levels.ERROR,
          { title = "WP" }
        )
      end
    end)
  end)
end

M.SUBCOMMANDS = {
  "cache",
  "cap",
  "cli",
  "comment",
  "config",
  "core",
  "cron",
  "db",
  "embed",
  "eval",
  "eval-file",
  "export",
  "help",
  "i18n",
  "import",
  "language",
  "maintenance-mode",
  "media",
  "menu",
  "network",
  "option",
  "package",
  "plugin",
  "post",
  "post-type",
  "rewrite",
  "role",
  "scaffold",
  "search-replace",
  "server",
  "shell",
  "sidebar",
  "site",
  "super-admin",
  "taxonomy",
  "term",
  "theme",
  "transient",
  "user",
  "widget",
}

---@param arglead string
---@param cmdline string
---@return string[]
M.complete = function(arglead, cmdline)
  -- only complete the first arg
  if #vim.split(vim.trim(cmdline), "%s+") > (arglead == "" and 1 or 2) then
    return {}
  end
  return vim.tbl_filter(function(sub)
    return vim.startswith(sub, arglead)
  end, M.SUBCOMMANDS)
end

return M
