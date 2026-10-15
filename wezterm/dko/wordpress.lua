local wezterm = require("wezterm") ---@type Wezterm

--- WordPress helpers
---
--- - PHP error/stack trace paths become clickable and open in this tab's nvim
---   (the bin/e tab-scoped socket), or a new split if nvim isn't running.
---   Trellis VM paths (/srv/www/<site>/current/...) are mapped back to the
---   local <project>/site/ dir, found by walking up from the pane's cwd.
---   Add explicit prefixes in local-wezterm.lua (config_builder rejects
---   unknown config keys, so these live on the module):
---     require("dko/wordpress").path_maps["/srv/www/x.com/current"] = "/Users/me/x.com/site"
--- - CTRL-SHIFT-L tails the WordPress debug.log for the pane's cwd in a split

local M = {}

---@type table<string, string> remote path prefix -> local path prefix
M.path_maps = {}

local SCHEME = "phpfile"

---@param path string
---@return boolean
local function exists(path)
  local f = io.open(path, "r")
  if f then
    f:close()
    return true
  end
  return false
end

---@param path string
---@return boolean
local function is_dir(path)
  return exists(path .. "/.")
end

---@param pane table
---@return string|nil
local function pane_cwd(pane)
  local url = pane:get_current_working_dir()
  return url and url.file_path or nil
end

---Yield cwd and each of its parents
---@param dir string
local function ancestors(dir)
  return coroutine.wrap(function()
    dir = dir:gsub("/+$", "")
    while dir ~= "" do
      coroutine.yield(dir)
      dir = dir:match("^(.*)/[^/]*$") or ""
    end
  end)
end

---Trellis project root (has trellis/ and site/) above dir
---@param dir string
---@return string|nil
local function trellis_project(dir)
  for d in ancestors(dir) do
    if is_dir(d .. "/trellis") and is_dir(d .. "/site") then
      return d
    end
  end
  return nil
end

---@param path string as printed by PHP, possibly a VM path
---@param cwd string|nil
---@return string
local function to_local(path, cwd)
  if exists(path) then
    return path
  end

  for remote, localpath in pairs(M.path_maps) do
    if path:sub(1, #remote) == remote then
      return localpath .. path:sub(#remote + 1)
    end
  end

  local rest = path:match("^/srv/www/[^/]+/current(/.*)$")
  local project = cwd and trellis_project(cwd)
  if rest and project then
    return project .. "/site" .. rest
  end

  return path
end

---@param window table
---@param pane table
---@param path string
---@param line string
local function open_in_nvim(window, pane, path, line)
  local tab = pane:tab()
  local state = os.getenv("XDG_STATE_HOME")
    or (wezterm.home_dir .. "/.local/state")
  local sock = ("%s/nvim/nvim-tab-%s.sock"):format(state, tab:tab_id())

  if exists(sock) then
    local target = path:gsub(" ", "\\ ")
    local keys = ("<C-\\><C-N><Cmd>edit +%s %s<CR>"):format(line, target)
    wezterm.background_child_process({
      os.getenv("SHELL") or "/bin/zsh",
      "-lc",
      'nvim --server "$1" --remote-send "$2"',
      "_",
      sock,
      keys,
    })
    for _, p in ipairs(tab:panes()) do
      local proc = p:get_foreground_process_name() or ""
      if proc:match("nvim$") then
        p:activate()
        break
      end
    end
    return
  end

  window:perform_action(
    wezterm.action.SplitPane({
      direction = "Right",
      command = {
        args = {
          os.getenv("SHELL") or "/bin/zsh",
          "-lc",
          'exec nvim "+$1" "$2"',
          "_",
          line,
          path,
        },
      },
    }),
    pane
  )
end

---Debug log for the WordPress install containing dir
---@param dir string
---@return string|nil
M.find_debug_log = function(dir)
  for d in ancestors(dir) do
    if is_dir(d .. "/web/app") then -- Bedrock
      return d .. "/web/app/debug.log"
    end
    if is_dir(d .. "/wp-content") then
      return d .. "/wp-content/debug.log"
    end
    if is_dir(d .. "/trellis") and is_dir(d .. "/site/web/app") then
      return d .. "/site/web/app/debug.log"
    end
  end
  return nil
end

---@param window table
---@param pane table
M.tail_debug_log = function(window, pane)
  local cwd = pane_cwd(pane)
  local log = cwd and M.find_debug_log(cwd)
  if not log then
    window:toast_notification(
      "wezterm",
      "No WordPress install found above " .. (cwd or "?"),
      nil,
      4000
    )
    return
  end
  window:perform_action(
    wezterm.action.SplitPane({
      direction = "Down",
      size = { Percent = 30 },
      command = { args = { "tail", "-n", "100", "-F", log } },
    }),
    pane
  )
end

M.setup = function(config)
  config.hyperlink_rules = config.hyperlink_rules
    or wezterm.default_hyperlink_rules()
  -- "in /x/y.php on line 12", "/x/y.php:12", "#0 /x/y.php(12): fn()"
  table.insert(config.hyperlink_rules, {
    regex = [[(/[^\s:()'"]+\.php)(?: on line |:|\()(\d+)]],
    format = SCHEME .. "://$1?line=$2",
  })

  wezterm.on("open-uri", function(window, pane, uri)
    local path, line = uri:match("^" .. SCHEME .. "://(.-)%?line=(%d+)$")
    if not path then
      return -- default handler
    end
    open_in_nvim(window, pane, to_local(path, pane_cwd(pane)), line)
    return false
  end)

  -- Replaces the disabled ShowDebugOverlay default from dko/mappings.lua.
  -- Both forms, since shifted letters report differently across builds.
  local keys = {}
  for _, k in ipairs(config.keys or {}) do
    if not (k.key == "L" and (k.mods == "CTRL" or k.mods == "SHIFT|CTRL")) then
      table.insert(keys, k)
    end
  end
  config.keys = keys
  for _, mods in ipairs({ "CTRL", "SHIFT|CTRL" }) do
    table.insert(config.keys, {
      key = "L",
      mods = mods,
      action = wezterm.action_callback(M.tail_debug_log),
    })
  end
end

return M
