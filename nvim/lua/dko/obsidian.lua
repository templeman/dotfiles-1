-- obsidian.nvim glue for ~/Documents/obsidian (and the legacy vault until
-- migration is done). Periodic note formats mirror Obsidian's Periodic Notes
-- plugin exactly (Moment.js syntax, ISO weeks), so both apps produce the same
-- filenames and links.

local M = {}

local DAY = 86400

M.vaults = {
  main = vim.fs.normalize("~/Documents/obsidian"),
  legacy = vim.fs.normalize("~/Dropbox (Personal)/Notes"),
}

---@type table<string, { folder: string, format: string, template: string }>
M.periods = {
  daily = { folder = "journal/daily", format = "YYYY-MM-DD", template = "daily.md" },
  worklog = { folder = "journal/worklog", format = "YYYY-MM-DD [Worklog]", template = "worklog.md" },
  weekly = { folder = "journal/weekly", format = "GGGG-[W]WW", template = "weekly.md" },
  monthly = { folder = "journal/monthly", format = "YYYY-MM", template = "monthly.md" },
  quarterly = { folder = "journal/quarterly", format = "YYYY-[Q]Q", template = "quarterly.md" },
  yearly = { folder = "journal/yearly", format = "YYYY", template = "yearly.md" },
}

-- =============================================================================
-- Dates
-- =============================================================================

--- Start of the period a note id names, e.g. "2026-10-01", "2026-10-01 Worklog",
--- "2026-W40" (ISO week → its Monday), "2026-10", "2026-Q4", "2026".
--- Noon avoids DST edge cases when adding days.
---@param id string
---@return integer|nil
function M.parse_id(id)
  local y, m, d = id:match("^(%d%d%d%d)%-(%d%d)%-(%d%d)")
  if y then
    return os.time({ year = y, month = m, day = d, hour = 12 })
  end
  local gy, w = id:match("^(%d%d%d%d)%-W(%d%d)$")
  if gy then
    -- ISO week 1 contains Jan 4th
    local jan4 = os.time({ year = gy, month = 1, day = 4, hour = 12 })
    local from_monday = (os.date("*t", jan4).wday + 5) % 7
    return jan4 + ((tonumber(w) - 1) * 7 - from_monday) * DAY
  end
  local qy, q = id:match("^(%d%d%d%d)%-Q([1-4])$")
  if qy then
    return os.time({ year = qy, month = (q - 1) * 3 + 1, day = 1, hour = 12 })
  end
  local my, mm = id:match("^(%d%d%d%d)%-(%d%d)$")
  if my then
    return os.time({ year = my, month = mm, day = 1, hour = 12 })
  end
  local yy = id:match("^(%d%d%d%d)$")
  if yy then
    return os.time({ year = yy, month = 1, day = 1, hour = 12 })
  end
end

--- Apply offsets like "-1d", "+1w", "+1M-1d", "+1Q", "-1y".
---@param time integer
---@param offsets string
---@return integer
function M.shift(time, offsets)
  for sign, n, unit in offsets:gmatch("([%+%-])(%d+)([dwMQy])") do
    n = tonumber(n) * (sign == "-" and -1 or 1)
    local t = os.date("*t", time) --[[@as osdate]]
    if unit == "d" then
      t.day = t.day + n
    elseif unit == "w" then
      t.day = t.day + 7 * n
    elseif unit == "M" then
      t.month = t.month + n
    elseif unit == "Q" then
      t.month = t.month + 3 * n
    elseif unit == "y" then
      t.year = t.year + n
    end
    t.isdst = nil
    time = os.time(t --[[@as osdateparam]])
  end
  return time
end

---@param time integer
---@param fmt string Moment.js format
---@return string
function M.format(time, fmt)
  return tostring(require("obsidian.date").format(time, fmt, 1))
end

--- Date the note being created is about (from its id), else now.
---@param ctx? obsidian.TemplateContext
---@return integer
local function note_time(ctx)
  local note = ctx and ctx.partial_note
  return note and note.id and M.parse_id(tostring(note.id)) or os.time()
end

-- =============================================================================
-- Template substitutions (new vault)
-- =============================================================================

local CONTEXTS = { work = true, personal = true, shared = true }

M.substitutions = {
  --- {{notedate:FORMAT}} or {{notedate:OFFSETS|FORMAT}}, relative to the note's
  --- own date, like Templater's tp.date.now(fmt, offset, tp.file.title, titleFmt).
  notedate = function(ctx, suffix)
    suffix = suffix or ""
    local offsets, fmt = suffix:match("^([%+%-][%w%+%-]*)|(.*)$")
    local time = note_time(ctx)
    if offsets then
      time = M.shift(time, offsets)
    else
      fmt = suffix
    end
    return M.format(time, fmt ~= "" and fmt or "YYYY-MM-DD")
  end,

  --- {{context:default}}: ask once per note, reuse for every occurrence.
  context = function(ctx, default)
    default = CONTEXTS[default or ""] and default or "personal"
    if ctx and ctx._dko_context then
      return ctx._dko_context
    end
    local answer = vim.trim(vim.fn.input(("Context (work/personal/shared) [%s]: "):format(default)))
    local value = CONTEXTS[answer] and answer or default
    if ctx then
      ctx._dko_context = value
    end
    return value
  end,

  --- {{todaylog}}: link to today's Worklog or Lifelog, matching {{context}}.
  todaylog = function(ctx)
    local today = M.format(os.time(), "YYYY-MM-DD")
    if ctx and ctx._dko_context == "work" then
      return ("[[%s Worklog|Worklog]]"):format(today)
    end
    return ("[[%s|Lifelog]]"):format(today)
  end,

  --- {{events:work}} / {{events:personal}}: calendar events for the note's date.
  events = function(ctx, which)
    return M.events_text(which or "personal", M.format(note_time(ctx), "YYYY-MM-DD"))
  end,
}

-- =============================================================================
-- Calendar events
-- =============================================================================

--- Markdown list of calendar events (see _meta/scripts/events-today.sh).
---@param context "work"|"personal"
---@param day string YYYY-MM-DD
---@return string
function M.events_text(context, day)
  local script = vim.fs.joinpath(M.vaults.main, "_meta/scripts/events-today.sh")
  if vim.fn.executable(script) ~= 1 then
    return ""
  end
  local ok, res = pcall(function()
    return vim.system({ script, context, day }, { text = true }):wait(5000)
  end)
  if not ok or res.code ~= 0 then
    return ""
  end
  return vim.trim(res.stdout or "")
end

local EVENTS_START = "<!-- events:start -->"
local EVENTS_END = "<!-- events:end -->"

--- Refresh the Events section of a daily note / Worklog from the calendar.
--- Replaces only the lines between the events markers, in the buffer (undoable).
--- Notes dated before today are frozen so the journal keeps what happened.
--- Obsidian twin: _meta/scripts/templater/refresh_events.js.
---@param buf? integer
function M.refresh_events(buf)
  buf = buf or 0
  local function say(msg, level)
    vim.notify(msg, level or vim.log.levels.INFO, { title = "obsidian events" })
  end
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

  local fm = {}
  if lines[1] == "---" then
    for i = 2, #lines do
      if lines[i] == "---" then
        break
      end
      local key, value = lines[i]:match("^([%w_-]+):%s*(.-)%s*$")
      if key then
        fm[key] = value
      end
    end
  end
  local day = fm.date and fm.date:match("^%d%d%d%d%-%d%d%-%d%d")
  if not day or (fm.context ~= "work" and fm.context ~= "personal") then
    return say("Needs a daily note or Worklog (date + work/personal context)", vim.log.levels.WARN)
  end
  if day < os.date("%Y-%m-%d") then
    return say("Past notes are frozen")
  end

  local first, last
  for i, line in ipairs(lines) do
    local trimmed = vim.trim(line)
    if not first and trimmed == EVENTS_START then
      first = i
    elseif first and trimmed == EVENTS_END then
      last = i
      break
    end
  end
  if not (first and last) then
    return say("No events markers in this note", vim.log.levels.WARN)
  end

  local text = M.events_text(fm.context, day)
  local new = text ~= "" and vim.split(text, "\n") or { "" }
  -- 0-indexed, end-exclusive: lines strictly between the markers
  local current = vim.api.nvim_buf_get_lines(buf, first, last - 1, false)
  if vim.deep_equal(current, new) then
    return say("Events already up to date")
  end
  vim.api.nvim_buf_set_lines(buf, first, last - 1, false, new)
  say("Events refreshed")
end

-- =============================================================================
-- Letterboxd
-- =============================================================================

--- Sync the Letterboxd diary (RSS, last 50 entries) into movie notes.
--- Runs _meta/scripts/letterboxd-sync in the background and reports its summary.
--- Obsidian twin: _meta/scripts/templater/letterboxd_sync.js.
function M.letterboxd_sync()
  local script = vim.fs.joinpath(M.vaults.main, "_meta/scripts/letterboxd-sync")
  vim.notify("Syncing…", vim.log.levels.INFO, { title = "letterboxd" })
  vim.system({ script, "rss" }, { text = true, timeout = 60000 }, function(res)
    vim.schedule(function()
      local ok = res.code == 0
      local msg = vim.trim(ok and res.stdout or (res.stderr ~= "" and res.stderr or res.stdout or ""))
      vim.notify(
        msg ~= "" and msg or "Sync failed",
        ok and vim.log.levels.INFO or vim.log.levels.ERROR,
        { title = "letterboxd" }
      )
      vim.cmd.checktime() -- reload open movie notes the sync changed
    end)
  end)
end

-- =============================================================================
-- Legacy vault substitutions
-- Kept verbatim so the old vault's nvim templates keep working until migration
-- is finished. Delete this section (and the legacy workspace) afterwards.
-- =============================================================================

local function timestampfromtitle()
  local y, m, d = vim.fn.expand("%:t:r"):match("^(%d+)-(%d+)-(%d+)$")
  if y then
    return os.time({ year = tonumber(y), month = tonumber(m), day = tonumber(d) })
  end
end

local function calendar_week_monday(ts)
  ts = ts or os.time()
  local W = tonumber(os.date("%W", ts))
  local y = tonumber(os.date("%Y", ts))
  local W_jan1 = tonumber(os.date("%W", os.time({ year = y, month = 1, day = 1 })))
  return math.min(W + ((W_jan1 == 0) and 1 or 0), 53)
end

M.legacy_substitutions = {
  tomorrowfromtitle = function()
    return os.date("%Y-%m-%d", (timestampfromtitle() or os.time()) + DAY)
  end,
  yesterdayfromtitle = function()
    return os.date("%Y-%m-%d", (timestampfromtitle() or os.time()) - DAY)
  end,
  weekfromtitle = function()
    return tostring(calendar_week_monday(timestampfromtitle() or os.time()))
  end,
  dayofweekfromtitle = function()
    return os.date("%A", timestampfromtitle() or os.time())
  end,
  datefromtitle = function()
    return os.date("%B %-d, %Y", timestampfromtitle() or os.time())
  end,
  yesterday = function()
    return os.date("%Y-%m-%d", os.time() - DAY)
  end,
  today = function()
    return os.date("%Y-%m-%d")
  end,
  tomorrow = function()
    return os.date("%Y-%m-%d", os.time() + DAY)
  end,
  day = function()
    return os.date("%-d")
  end,
  month = function()
    return os.date("%B")
  end,
  week = function()
    return os.date("%-W")
  end,
  weekday = function()
    return os.date("*t").wday
  end,
  weekdayname = function()
    return os.date("%A")
  end,
  year = function()
    return os.date("%Y")
  end,
}

-- =============================================================================
-- Periodic notes
-- =============================================================================

--- Open (creating from template if needed) the `kind` note containing `time`.
---@param kind "daily"|"worklog"|"weekly"|"monthly"|"quarterly"|"yearly"
---@param time? integer
function M.open_period(kind, time)
  local period = assert(M.periods[kind], "unknown period " .. kind)
  local root = Obsidian and Obsidian.workspace and tostring(Obsidian.workspace.root)
  if root ~= M.vaults.main then
    vim.notify("Periodic notes live in " .. M.vaults.main, vim.log.levels.WARN, { title = "obsidian" })
    return
  end

  local Note = require("obsidian.note")
  local Path = require("obsidian.path")
  local id = M.format(time or os.time(), period.format)
  local dir = vim.fs.joinpath(root, period.folder)
  local path = vim.fs.joinpath(dir, id .. ".md")

  local note
  if vim.uv.fs_stat(path) then
    note = Note.from_file(path)
  else
    note = Note.create({
      id = id,
      verbatim = true,
      dir = Path.new(dir),
      template = period.template,
      scope = kind,
    })
    note = note:write({})
  end
  note:open()
end

--- Meeting note id: today's date, then the name (unless it already starts with a date).
---@param title string|?
---@return string
function M.meeting_id(title)
  title = vim.trim(title or "")
  if title:match("^%d%d%d%d%-%d%d%-%d%d ") then
    return title
  end
  return os.date("%Y-%m-%d") .. " " .. (title ~= "" and title or "Meeting")
end

--- <leader>oi: capture a TIL. Asks for the title (the thing learned) and
--- creates notes/<title>.md from the til template (tag `til`, a `kind`).
function M.new_til()
  vim.ui.input({ prompt = "TIL: " }, function(title)
    title = title and vim.trim(title) or ""
    if title == "" then
      return
    end
    local Note = require("obsidian.note")
    local Path = require("obsidian.path")
    local path = vim.fs.joinpath(M.vaults.main, "notes", title .. ".md")
    if vim.uv.fs_stat(path) then
      return Note.from_file(path):open()
    end
    local note = Note.create({
      id = title,
      verbatim = true,
      dir = Path.new(vim.fs.joinpath(M.vaults.main, "notes")),
      template = "til.md",
    })
    note:write({}):open()
  end)
end

--- Which period a note id belongs to, e.g. "2026-W40" → "weekly".
---@param id string
---@return string|nil
function M.period_for_id(id)
  if id:match("^%d%d%d%d%-%d%d%-%d%d Worklog$") then
    return "worklog"
  elseif id:match("^%d%d%d%d%-%d%d%-%d%d$") then
    return "daily"
  elseif id:match("^%d%d%d%d%-W%d%d$") then
    return "weekly"
  elseif id:match("^%d%d%d%d%-Q[1-4]$") then
    return "quarterly"
  elseif id:match("^%d%d%d%d%-%d%d$") then
    return "monthly"
  elseif id:match("^%d%d%d%d$") then
    return "yearly"
  end
end

--- <CR> in vault notes: following a link to a periodic note that doesn't exist
--- yet creates it in its journal folder from its template (like <leader>od),
--- instead of a blank note in notes/. Everything else is obsidian.nvim's smart
--- action. Obsidian twin: Templater's regex file templates.
---@return string keys for an expr mapping
function M.smart_enter()
  local link = require("obsidian.api").cursor_link()
  local target = link and link:match("^!?%[%[([^|#%]]+)")
  local id = target and (vim.fs.basename(target):gsub("%.md$", ""))
  local kind = id and M.period_for_id(id)
  if kind and Obsidian.workspace and tostring(Obsidian.workspace.root) == M.vaults.main then
    local path = vim.fs.joinpath(M.vaults.main, M.periods[kind].folder, id .. ".md")
    if not vim.uv.fs_stat(path) then
      vim.schedule(function()
        M.open_period(kind, M.parse_id(id))
      end)
      return ""
    end
  end
  return require("obsidian.actions").smart_action()
end

-- =============================================================================
-- Task rollup
-- =============================================================================

--- Open task statuses: todo, doing, deferred, important, question.
M.TASK_PATTERN = [[^\s*[-*+] \[[ />!?]\] ]]

--- Lines of `lines` that sit inside a ``` or ~~~ code fence.
---@param lines string[]
---@return table<integer, true>
local function fenced_lines(lines)
  local fenced, inside = {}, false
  for lnum, line in ipairs(lines) do
    if line:match("^%s*```") or line:match("^%s*~~~") then
      inside = not inside
    elseif inside then
      fenced[lnum] = true
    end
  end
  return fenced
end

--- Snacks picker of every open task in the main vault, soonest due first,
--- undated last. Skips templates (_meta/), the old vault (old-structure/) and
--- example tasks in code fences. Obsidian twin: categories/Tasks.md.
function M.pick_tasks()
  local root = M.vaults.main
  local res = vim
    .system({
      "rg", "--line-number", "--no-heading", "--color=never", "--sort=path",
      "--glob=*.md", "--glob=!_meta/**", "--glob=!old-structure/**",
      "-e", M.TASK_PATTERN,
    }, { cwd = root, text = true })
    :wait()
  if res.code > 1 then
    vim.notify("rg failed: " .. (res.stderr or ""), vim.log.levels.ERROR)
    return
  end

  local tasks, fences = {}, {}
  for _, line in ipairs(vim.split(res.stdout or "", "\n", { trimempty = true })) do
    local file, lnum, text = line:match("^(.-):(%d+):(.*)$")
    if file then
      lnum = tonumber(lnum)
      if not fences[file] then
        fences[file] = fenced_lines(vim.fn.readfile(vim.fs.joinpath(root, file)))
      end
      if not fences[file][lnum] then
        table.insert(tasks, {
          text = file .. " " .. vim.trim(text),
          file = file,
          cwd = root,
          line = vim.trim(text),
          pos = { lnum, 0 },
          due = text:match("%[due:: (%d%d%d%d%-%d%d%-%d%d)%]") or "9999",
          order = #tasks,
        })
      end
    end
  end
  table.sort(tasks, function(a, b)
    if a.due ~= b.due then
      return a.due < b.due
    end
    return a.order < b.order
  end)

  Snacks.picker.pick({
    title = "Tasks",
    items = tasks,
    format = "file",
    -- keep the due-date order among equally good matches
    sort = { fields = { "score:desc", "idx" } },
  })
end

-- =============================================================================
-- obsidian.nvim workspace config
-- =============================================================================

local CHECKBOXES = {
  [" "] = { char = "󰄱", hl_group = "ObsidianTodo" },
  ["/"] = { char = "󰡖", hl_group = "ObsidianTodo" },
  ["x"] = { char = "", hl_group = "ObsidianDone" },
  ["-"] = { char = "󰰱", hl_group = "ObsidianTilde" },
  [">"] = { char = "", hl_group = "ObsidianRightArrow" },
  ["!"] = { char = "", hl_group = "ObsidianImportant" },
  ["?"] = { char = "", hl_group = "ObsidianTodo" },
}

--- obsidian.nvim `callbacks.post_setup`.
--- `ui.checkboxes` still drives how each task status is drawn, but passing it to
--- setup() or a workspace override always logs a "use checkbox.order" warning
--- (obsidian-nvim/obsidian.nvim#262), even though ordering already comes from
--- `checkbox.order`. Set the icons after setup instead: on the live opts, and on
--- the base opts that workspace switches re-merge their overrides onto.
function M.post_setup()
  Obsidian._opts.ui.checkboxes = CHECKBOXES
  Obsidian.opts.ui.checkboxes = CHECKBOXES
end

---@return obsidian.workspace.WorkspaceSpec[]
function M.workspaces()
  return {
    {
      name = "obsidian",
      path = M.vaults.main,
      overrides = {
        notes_subdir = "notes",
        new_notes_location = "notes_subdir",
        link = { style = "wiki" },
        attachments = { folder = "attachments" },
        daily_notes = {
          folder = M.periods.daily.folder,
          date_format = M.periods.daily.format,
          template = M.periods.daily.template,
          start_of_week = 1,
          workdays_only = false,
          default_tags = {},
        },
        templates = {
          folder = "_meta/templates/nvim",
          date_format = "YYYY-MM-DD",
          time_format = "HH:mm",
          substitutions = M.substitutions,
          customizations = {
            -- "<date> <name>", so recurring meetings stay unique; the
            -- note's title (its H1) stays the bare name.
            meeting = { notes_subdir = "notes", note_id_func = M.meeting_id },
            project = { notes_subdir = "notes" },
            note = { notes_subdir = "notes" },
            person = { notes_subdir = "references" },
            book = { notes_subdir = "references" },
            til = { notes_subdir = "notes" },
            recipe = { notes_subdir = "references" },
            movie = { notes_subdir = "references" },
          },
        },
        checkbox = { order = { " ", "/", "x", "-", ">", "!", "?" } },
        -- ui.checkboxes (icons) is applied in M.post_setup(), see there
      },
    },
    {
      name = "Notes",
      path = M.vaults.legacy,
      overrides = {
        daily_notes = { folder = "journal/daily", template = "nvim/journal.md" },
        templates = {
          folder = "Templates",
          substitutions = M.legacy_substitutions,
          customizations = {
            person = { notes_subdir = "people" },
            meeting = { notes_subdir = "meetings" },
          },
        },
      },
    },
  }
end

--- Event patterns that lazy-load obsidian.nvim, for every vault.
---@return string[]
function M.lazy_events()
  local events = {}
  for _, vault in pairs(M.vaults) do
    local pattern = vim.fn.fnameescape(vault) .. "/**.md"
    table.insert(events, "BufReadPre " .. pattern)
    table.insert(events, "BufNewFile " .. pattern)
  end
  return events
end

-- =============================================================================
-- Keymaps
-- =============================================================================

-- stylua: ignore
M.keys = {
  { "<Leader>od", "<Cmd>Obsidian today<CR>", desc = "obsidian: open daily note (Lifelog)" },
  { "<Leader>ow", function() M.open_period("worklog") end, desc = "obsidian: open Worklog" },
  { "<Leader>oW", function() M.open_period("weekly") end, desc = "obsidian: open weekly note" },
  { "<Leader>om", function() M.open_period("monthly") end, desc = "obsidian: open monthly note" },
  { "<Leader>oq", function() M.open_period("quarterly") end, desc = "obsidian: open quarterly note" },
  { "<Leader>oy", function() M.open_period("yearly") end, desc = "obsidian: open yearly note" },
  { "<Leader>oe", function() M.refresh_events() end, desc = "obsidian: refresh calendar events" },
  { "<Leader>oL", function() M.letterboxd_sync() end, desc = "obsidian: sync Letterboxd diary" },
  { "<Leader>ok", function() M.pick_tasks() end, desc = "obsidian: open tasks across the vault" },
  { "<Leader>oi", function() M.new_til() end, desc = "obsidian: new TIL (today I learned)" },
  { "<Leader>on", ":Obsidian new ", desc = "obsidian: new note" },
  { "<Leader>oo", ":Obsidian open ", desc = "obsidian: open in app" },
  { "<Leader>nv", "<Cmd>Obsidian search<CR>", desc = "obsidian: search" },
  { "<Leader>os", "<Cmd>Obsidian quick_switch<CR>", desc = "obsidian: quick switch" },
  { "<Leader>ot", "<Cmd>Obsidian template<CR>", desc = "obsidian: insert template" },
  { "<Leader>oT", "<Cmd>Obsidian new_from_template<CR>", desc = "obsidian: new note from template" },
  -- daily notes from the past 20 days
  { "<Leader>oD", "<Cmd>Obsidian dailies -20 0<CR>", desc = "obsidian: daily notes" },
}

--- Buffer-local maps for notes in any vault.
function M.attach_buffer_maps()
  vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
    group = vim.api.nvim_create_augroup("dko_obsidian", { clear = true }),
    pattern = vim.tbl_map(function(vault)
      return vault .. "/**.md"
    end, vim.tbl_values(M.vaults)),
    callback = function(ev)
      vim.keymap.set({ "n", "x" }, "<Leader>ch", "<Cmd>Obsidian toggle_checkbox<CR>", {
        buffer = ev.buf,
        desc = "Toggle checkbox",
      })
    end,
  })
  -- obsidian.nvim maps <CR> to its smart action on note enter, then fires this
  -- event, so this override wins.
  vim.api.nvim_create_autocmd("User", {
    group = vim.api.nvim_create_augroup("dko_obsidian_enter", { clear = true }),
    pattern = "ObsidianNoteEnter",
    callback = function()
      vim.keymap.set("n", "<CR>", M.smart_enter, {
        expr = true,
        buffer = vim.api.nvim_get_current_buf(),
        desc = "Obsidian smart action (periodic notes land in journal/)",
      })
    end,
  })
end

return M
