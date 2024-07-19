local dkosettings = require("dko.settings")
local uis = vim.api.nvim_list_uis()
local has_ui = #uis > 0

local function timestampfromtitle()
  local date_str = vim.fn.expand("%:t:r")

  -- Parse the date string into year, month, and day
  local year, month, day = date_str:match("(%d+)-(%d+)-(%d+)")
  local date_table = { year = year, month = month, day = day }

  -- Convert the date table to a timestamp
  local timestamp = os.time(date_table)

  return timestamp
end

return {
  {
    "echasnovski/mini.bracketed",
    version = false,
    config = function()
      require("mini.bracketed").setup({
        buffer = { suffix = "", options = {} }, -- using cybu
        comment = { suffix = "c", options = {} },
        conflict = { suffix = "x", options = {} },
        -- don't want diagnostic float focus, have in mappings.lua
        diagnostic = { suffix = "", options = {} },
        file = { suffix = "f", options = {} },
        indent = { suffix = "", options = {} }, -- confusing
        jump = { suffix = "", options = {} }, -- redundant
        location = { suffix = "l", options = {} },
        oldfile = { suffix = "o", options = {} },
        quickfix = { suffix = "q", options = {} },
        treesitter = { suffix = "t", options = {} },
        undo = { suffix = "", options = {} },
        window = { suffix = "", options = {} }, -- broken going to unlisted
        yank = { suffix = "", options = {} }, -- confusing
      })
    end,
  },

  {
    "echasnovski/mini.align",
    version = false,
    config = function()
      require("mini.align").setup()
    end,
  },

  -- =========================================================================
  -- ui: components
  -- =========================================================================

  {
    "nvim-tree/nvim-web-devicons",
    lazy = true,
    cond = has_ui,
    config = true,
  },

  -- Replace vim.ui.select and vim.ui.input, which are used by things like
  -- vim.lsp.buf.code_action and rename
  -- Alternatively could use https://github.com/nvim-telescope/telescope-ui-select.nvim
  -- https://github.com/stevearc/dressing.nvim
  {
    "stevearc/dressing.nvim",
    cond = has_ui,
    event = "VeryLazy",
  },

  {
    "rachartier/tiny-inline-diagnostic.nvim",
    event = "VeryLazy",
    config = function()
      require("tiny-inline-diagnostic").setup({
        blend = {
          factor = 0.3,
        },
        options = {
          break_line = {
            enabled = true,
            after = 80,
          },
          multiple_diag_under_cursor = true,
        },
      })
      dkosettings.set("diagnostics.goto_float", false)
    end,
  },

  -- =========================================================================
  -- ui: buffer and window manipulation
  -- =========================================================================

  -- pretty format quickfix and loclist
  {
    "yorickpeterse/nvim-pqf",
    event = { "BufReadPost", "BufNewFile" },
    cond = has_ui,
    config = function()
      require("pqf").setup()
    end,
  },

  -- remove buffers without messing up window layout
  -- https://github.com/echasnovski/mini.bufremove
  {
    "echasnovski/mini.bufremove",
    version = false, -- dev version
    config = function()
      require("mini.bufremove").setup()
    end,
  },

  {
    "ghillb/cybu.nvim",
    cond = has_ui,
    dependencies = {
      "nvim-tree/nvim-web-devicons",
      "nvim-lua/plenary.nvim",
    },
    keys = vim.tbl_values(require("dko.mappings").cybu),
    config = function()
      require("cybu").setup({
        display_time = 500,
        position = {
          anchor = "centerright",
          max_win_height = 8,
          max_win_width = 0.5,
        },
        style = {
          border = dkosettings.get("border"),
          hide_buffer_id = true,
          highlights = {
            background = "dkoBgAlt",
            current_buffer = "dkoQuote",
            adjacent_buffers = "dkoType",
          },
        },
        exclude = { -- filetypes
          "qf",
          "help",
        },
      })
      require("dko.mappings").bind_cybu()
    end,
  },

  -- zoom in/out of a window
  -- this plugin accounts for command window and doesn't use sessions
  -- overrides <C-w>o (originally does an :only)
  {
    "troydm/zoomwintab.vim",
    cond = has_ui,
    keys = require("dko.mappings").zoomwintab,
    cmd = {
      "ZoomWinTabIn",
      "ZoomWinTabOut",
      "ZoomWinTabToggle",
    },
  },

  -- resize window to selection, or split new window with selection size
  {
    "wellle/visual-split.vim",
    cond = has_ui,
    cmd = {
      "VSResize",
      "VSSplit",
      "VSSplitAbove",
      "VSSplitBelow",
    },
  },

  -- https://github.com/yorickpeterse/nvim-window
  {
    "yorickpeterse/nvim-window",
    cond = has_ui,
    config = function()
      require("nvim-window").setup({})
      require("dko.mappings").bind_nvim_window()
    end,
  },

  -- remember/restore last cursor position in files
  {
    "ethanholz/nvim-lastplace",
    cond = has_ui,
    config = true,
  },

  -- =========================================================================
  -- ui: terminal
  -- =========================================================================

  {
    "akinsho/toggleterm.nvim",
    keys = require("dko.mappings").toggleterm_all_keys,
    cmd = "ToggleTerm",
    cond = has_ui,
    config = function()
      require("toggleterm").setup({
        float_opts = {
          border = dkosettings.get("border"),
        },
        -- built-in mappings only work on LAST USED terminal, so it confuses
        -- the buffer terminal with the floating terminal
        open_mapping = nil,
      })
      require("dko.mappings").bind_toggleterm()
    end,
  },

  -- =========================================================================
  -- ui: diffing
  -- =========================================================================

  -- show diff when editing a COMMIT_EDITMSG
  {
    "rhysd/committia.vim",
    lazy = false, -- just in case
    init = function()
      vim.g.committia_open_only_vim_starting = 0
      vim.g.committia_use_singlecolumn = "always"
    end,
  },

  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPost", "BufNewFile" },
    cond = has_ui,
    config = function()
      require("gitsigns").setup({
        on_attach = require("dko.mappings").bind_gitsigns,
        preview_config = {
          border = dkosettings.get("border"),
        },
      })
    end,
  },

  -- diff partial selections
  { "rickhowe/spotdiff.vim" },

  -- =========================================================================
  -- Reading
  -- =========================================================================

  -- jump to :line:column in filename:3:20
  --
  -- has indexing errors
  -- https://github.com/lewis6991/fileline.nvim/
  --{ "lewis6991/fileline.nvim" },
  --
  -- https://github.com/wsdjeg/vim-fetch
  {
    "wsdjeg/vim-fetch",
    cond = has_ui,
  },

  -- ]u [u mappings to jump to urls
  -- <A-u> to open link picker
  -- https://github.com/axieax/urlview.nvim
  {
    "axieax/urlview.nvim",
    keys = vim.tbl_values(require("dko.mappings").urlview),
    cmd = "UrlView",
    cond = has_ui,
    config = function()
      require("dko.mappings").bind_urlview()
    end,
  },

  -- highlight undo/redo text change
  -- https://github.com/tzachar/highlight-undo.nvim
  {
    "tzachar/highlight-undo.nvim",
    cond = has_ui,
    keys = { "u", "<c-r>" },
    config = function()
      require("highlight-undo").setup({})
    end,
  },

  -- package diff
  -- https://github.com/vuki656/package-info.nvim
  {
    "davidosomething/package-info.nvim",
    cond = has_ui,
    dev = true,
    dependencies = { "MunifTanjim/nui.nvim" },
    event = { "BufReadPost package.json" },
    config = function()
      require("package-info").setup({
        hide_up_to_date = true,
      })
      require("dko.mappings").bind_packageinfo()
    end,
  },

  -- =========================================================================
  -- Syntax
  -- =========================================================================

  -- {
  --   "lukas-reineke/headlines.nvim",
  --   cond = has_ui,
  --   dependencies = "nvim-treesitter/nvim-treesitter",
  --   opts = {
  --     markdown = {
  --       bullets = {},
  --     },
  --   }, -- or `opts = {}`
  -- },

  -- Works better than https://github.com/IndianBoy42/tree-sitter-just
  {
    "NoahTheDuke/vim-just",
    event = { "BufReadPre", "BufNewFile" },
    ft = { "\\cjustfile", "*.just", ".justfile" },
  },

  -- https://github.com/brenoprata10/nvim-highlight-colors
  -- see output comparison here https://www.reddit.com/r/neovim/comments/1b5gw12/nvimhighlightcolors_now_supports_virtual_text/kt8gog6/?share_id=aUVLJ5zC3yMKjFuHqumGE
  {
    "brenoprata10/nvim-highlight-colors",
    cond = has_ui,
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      require("nvim-highlight-colors").setup({
        ---@usage 'background'|'foreground'|'virtual'
        render = "background",
        -- virtual_symbol_position = 'eow',
        -- virtual_symbol_prefix = ' ',
        -- virtual_symbol_suffix = '',
        ---Highlight tailwind colors, e.g. 'bg-blue-500'
        enable_tailwind = true,
      })
    end,
  },

  -- {
  --   "NvChad/nvim-colorizer.lua",
  --   cond = has_ui,
  --   event = { "BufReadPost", "BufNewFile" },
  --   config = function()
  --     require("colorizer").setup({
  --       buftypes = {
  --         "*",
  --         unpack(vim.tbl_map(function(v)
  --           return "!" .. v
  --         end, require("dko.utils.buffer").SPECIAL_BUFTYPES)),
  --       },
  --       filetypes = vim.tbl_extend("keep", {
  --         "css",
  --         "html",
  --         "scss",
  --       }, require("dko.utils.jsts").fts),
  --       user_default_options = {
  --         css = true,
  --         tailwind = true,
  --       },
  --     })
  --   end,
  -- },

  -- =========================================================================
  -- Writing
  -- =========================================================================

  -- because https://github.com/neovim/neovim/issues/1496
  -- once https://github.com/neovim/neovim/pull/10842 is merged, there will
  -- probably be a better implementation for this
  {
    "lambdalisue/suda.vim",
    cond = has_ui,
    cmd = "SudaWrite",
  },

  {
    "gbprod/yanky.nvim",
    cond = has_ui,
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      require("yanky").setup({
        highlight = { timer = 300 },
      })
      require("dko.mappings").bind_yanky()
    end,
  },

  -- highlight matching html/xml tag
  -- % textobject
  {
    "andymass/vim-matchup",
    cond = has_ui,
    -- author recommends against lazy loading
    lazy = false,
    init = function()
      vim.g.matchup_matchparen_deferred = 1
      vim.g.matchup_matchparen_status_offscreen = 0
      -- see behaviors.lua for treesitter integration
    end,
  },

  -- <A-hjkl> to move lines in any mode
  {
    "echasnovski/mini.move",
    config = function()
      require("mini.move").setup()
    end,
  },

  -- https://github.com/JoosepAlviste/nvim-ts-context-commentstring
  {
    "JoosepAlviste/nvim-ts-context-commentstring",
    -- No longer needs nvim-treesitter after https://github.com/JoosepAlviste/nvim-ts-context-commentstring/pull/80
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      require("ts_context_commentstring").setup({
        -- Disable for Comment.nvim https://github.com/JoosepAlviste/nvim-ts-context-commentstring/wiki/Integrations#commentnvim
        enable_autocmd = false,
      })
    end,
  },

  -- gcc / <Leader>gbc to comment with treesitter integration
  -- 0.10 has built-in treesitter comments, see :h commenting
  -- BUT it does not properly do jsx/tsx which is provided by
  -- ts_context_commentstring
  -- https://github.com/numToStr/Comment.nvim
  {
    "numToStr/Comment.nvim",
    cond = has_ui,
    dependencies = {
      "JoosepAlviste/nvim-ts-context-commentstring",
    },
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      local ok, tscc_integration =
        pcall(require, "ts_context_commentstring.integrations.comment_nvim")
      if not ok then
        vim.notify(
          "Comment.nvim could not find nvim-ts-context-commentstring",
          vim.log.levels.ERROR
        )
        return
      end
      require("Comment").setup(
        require("dko.mappings").with_commentnvim_mappings({
          -- add treesitter support, want tsx/jsx in particular
          pre_hook = tscc_integration.create_pre_hook(),
        })
      )
    end,
  },

  {
    "Wansmer/treesj",
    cond = has_ui,
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
    },
    event = { "BufReadPost", "BufNewFile" },
    keys = require("dko.mappings").trees,
    config = function()
      require("treesj").setup({
        use_default_keymaps = false,
        max_join_length = 255,
      })
      require("dko.mappings").bind_treesj()
    end,
  },

  -- vim-sandwich provides a textobj!
  -- sa/sr/sd operators and ib/ab textobjs
  -- https://github.com/echasnovski/mini.surround -- no textobj
  -- https://github.com/kylechui/nvim-surround -- no textobj
  {
    "machakann/vim-sandwich",
    cond = has_ui,
  },

  {
    "kana/vim-textobj-user",
    cond = has_ui,
    dependencies = {
      "gilligan/textobj-lastpaste",
      "mattn/vim-textobj-url",
    },
    config = function()
      require("dko.mappings").bind_textobj()
    end,
  },

  {
    "chrisgrieser/nvim-various-textobjs",
    cond = has_ui,
    config = function()
      require("various-textobjs").setup({ useDefaultKeymaps = false })
      require("dko.mappings").bind_nvim_various_textobjs()
    end,
  },

  -- {
  --   "folke/flash.nvim",
  --   event = "VeryLazy",
  --   ---@type Flash.Config
  --   opts = {},
  --   -- stylua: ignore
  --   keys = {
  --     { "s", mode = { "n", "x", "o" }, function() require("flash").jump(
  --       {
  --         search = {
  --           mode = function(str)
  --             return "\\<" .. str
  --           end,
  --         },
  --       }
  --     ) end, desc = "Flash" },
  --     { "S", mode = { "n", "o", "x" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
  --     { "r", mode = "o", function() require("flash").remote() end, desc = "Remote Flash" },
  --     { "R", mode = { "o", "x" }, function() require("flash").treesitter_search() end, desc = "Treesitter Search" },
  --     { "<c-s>", mode = { "c" }, function() require("flash").toggle() end, desc = "Toggle Flash Search" },
  --   },
  -- },

  --- Interactive scratchpad for REPL-based live evaluation of code (like Numi)
  {
    "metakirby5/codi.vim",
    init = function()
      --- let g:codi#log= '/tmp/codi.log'
      vim.g["codi#log"] = "/Users/sam/codi-6.log"
    end,
  },

  --- Integrates https://github.com/PHP-CS-Fixer/PHP-CS-Fixer in nvim
  {
    "stephpy/vim-php-cs-fixer",
    init = function()
      vim.g.php_cs_fixer_php_path = "/opt/homebrew/bin/php" --- Path to PHP
      vim.g.php_cs_fixer_dry_run = 0 --- Call command with dry-run option
    end,
  },

  --- GitHub Copilot
  {
    "github/copilot.vim",
    init = function()
      vim.g.copilot_filetypes = {
        markdown = false,
      }
    end,
  },

  -- =========================================================================
  -- Notes with FZF
  -- =========================================================================

  -- nnoremap <silent> <leader>nv :NV<CR>
  -- vim.g.nv_search_paths = "~/Dropbox (Personal)/Notes"
  -- {
  --   "Alok/notational-fzf-vim",
  --   -- opts = { nv_search_paths = "~/Dropbox (Personal)/Notes" },
  --   init = function()
  --     vim.g.nv_search_paths = { "~/Dropbox (Personal)/Notes" }
  --     -- require("notational-fzf-vim").setup({
  --     --   nv_search_paths = "~/Dropbox (Personal)/Notes"
  --     -- })
  --     -- vim.keymap.set("n", "<Leader>nv", "<Cmd>NV<CR>", {
  --     vim.keymap.set("n", "<Leader>nv", "<Cmd>NV<CR>", {
  --       desc = "Trigger NV",
  --     })
  --   end,
  -- },

  -- =========================================================================
  -- Obsidian
  -- =========================================================================

  {
    "epwalsh/obsidian.nvim",
    version = "*",
    lazy = true,
    event = {
      "BufReadPre " .. vim.fn.expand("~") .. "/Dropbox (Personal)/Notes/**.md",
      "BufNewFile " .. vim.fn.expand("~") .. "/Dropbox (Personal)/Notes/**.md",
    },
    -- stylua: ignore
    keys = {
      -- { '<localleader>ob', '<Cmd>ObsidianBacklinks<CR>', desc = 'obsidian: buffer backlinks', },
      { '<Leader>od', '<Cmd>ObsidianToday<CR>', desc = 'obsidian: open daily note', },
      -- { '<localleader>on', ':ObsidianNew ', desc = 'obsidian: new note' },
      -- { '<localleader>oy', '<Cmd>ObsidianYesterday<CR>', desc = 'obsidian: previous daily note', },
      { '<Leader>oo', ':ObsidianOpen ', desc = 'obsidian: open in app' },
      { '<Leader>nv', '<Cmd>ObsidianSearch<CR>', desc = 'obsidian: search', },
      { '<Leader>os', '<Cmd>ObsidianQuickSwitch<CR>', desc = 'obsidian: quick switch', },
      { '<Leader>ot', '<Cmd>ObsidianTemplate<CR>', desc = 'obsidian: insert template', },
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "hrsh7th/nvim-cmp",
      "nvim-telescope/telescope.nvim",
    },
    config = function()
      require("obsidian").setup({
        workspaces = {
          { name = "Notes", path = "~/Dropbox (Personal)/Notes" },
        },
        disable_frontmatter = true,
        -- Optional, set to true to force ':ObsidianOpen' to bring the app to the foreground.
        open_app_foreground = true,
        -- Optional, for templates (see below).
        templates = {
          subdir = "Templates",
          -- date_format = "%Y-%m-%d",
          -- time_format = "%H:%M",
          -- A map for custom variables, the key should be the variable and the value a function
          substitutions = {
            tomorrowfromtitle = function()
              return os.date("%Y-%m-%d", timestampfromtitle() + 60 * 60 * 24)
            end,
            yesterdayfromtitle = function()
              return os.date("%Y-%m-%d", timestampfromtitle() - 60 * 60 * 24)
            end,
            weekfromtitle = function()
              local date_str = vim.fn.expand("%:t:r")
              -- Parse the date string into year, month, and day
              local year, month, day = date_str:match("(%d+)-(%d+)-(%d+)")

              -- Convert to numbers
              year, month, day = tonumber(year), tonumber(month), tonumber(day)

              local date_table = { year = year, month = month, day = day }
              local timestamp = os.time(date_table)

              -- Get the day of the week (0 for Sunday, 1 for Monday, ..., 6 for Saturday)
              local day_of_week = os.date(
                "*t",
                os.time({ year = year, month = month, day = day })
              ).wday

              -- Calculate the week number
              local jan_1_weekday =
                os.date("*t", os.time({ year = year, month = 1, day = 1 })).wday

              -- local week_number = math.ceil((day + jan_1_weekday - 1) / 7)
              local week_number = math.ceil(
                (tonumber(os.date("%j", timestamp)) + jan_1_weekday - 1) / 7
              )

              -- If the week number is 53, adjust it to 1
              if week_number == 53 then
                week_number = 1
              end

              return week_number
            end,
            dayofweekfromtitle = function()
              -- Get the day of the week (Sunday is 1, Monday is 2, ..., Saturday is 7)
              local day_of_week = tonumber(os.date("%w", timestampfromtitle()))

              -- Define an array of day names
              local days = {
                "Sunday",
                "Monday",
                "Tuesday",
                "Wednesday",
                "Thursday",
                "Friday",
                "Saturday",
              }

              -- Get the full name of the day of the week
              return days[day_of_week + 1]
            end,
            datefromtitle = function()
              -- Convert the timestamp to a date string with the desired format
              return os.date("%B %-d, %Y", timestampfromtitle())
            end,
            yesterday = function()
              return os.date("%Y-%m-%d", os.time() - 60 * 60 * 24)
            end,
            today = function()
              return os.date("%Y-%m-%d")
            end,
            tomorrow = function()
              return os.date("%Y-%m-%d", os.time() + 60 * 60 * 24)
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
              local daysoftheweek = {
                "Sunday",
                "Monday",
                "Tuesday",
                "Wednesday",
                "Thursday",
                "Friday",
                "Saturday",
              }
              return daysoftheweek[os.date("*t").wday]
            end,
            year = function()
              return os.date("%Y")
            end,
          },
        },
        daily_notes = {
          -- Optional, if you keep daily notes in a separate directory.
          folder = "journal/daily",
          -- Optional, if you want to change the date format for the ID of daily notes.
          -- date_format = "%Y-%m-%d",
          -- Optional, if you want to change the date format of the default alias of daily notes.
          -- alias_format = "%B %-d, %Y",
          -- Optional, if you want to automatically insert a template from your template directory like 'daily.md'
          template = "nvim/journal.md",
        },
        completion = { nvim_cmp = true },
        -- Optional, key mappings.
        mappings = {
          -- Overrides the 'gf' mapping to work on markdown/wiki links within your vault.
          ["gf"] = {
            action = function()
              return require("obsidian").util.gf_passthrough()
            end,
            opts = { noremap = false, expr = true, buffer = true },
          },
          -- Toggle check-boxes.
          ["<leader>ch"] = {
            action = function()
              return require("obsidian").util.toggle_checkbox()
            end,
            opts = { buffer = true },
          },
        },
        -- Where to put new notes. Valid options are
        --  * "current_dir" - put new notes in same directory as the current buffer.
        --  * "notes_subdir" - put new notes in the default notes subdirectory.
        new_notes_location = "notes_subdir",
        -- Optional, customize how names/IDs for new notes are created.
        note_id_func = function(title)
          -- Create note IDs in a Zettelkasten format with a timestamp and a suffix.
          -- In this case a note with the title 'My new note' will be given an ID that looks
          -- like '1657296016-my-new-note', and therefore the file name '1657296016-my-new-note.md'
          -- local suffix = ""
          -- if title ~= nil then
          --   -- If title is given, transform it into valid file name.
          --   suffix = title:gsub(" ", "-"):gsub("[^A-Za-z0-9-]", ""):lower()
          -- else
          --   -- If title is nil, just add 4 random uppercase letters to the suffix.
          --   for _ = 1, 4 do
          --     suffix = suffix .. string.char(math.random(65, 90))
          --   end
          -- end
          -- return tostring(os.time()) .. "-" .. suffix
          return title
        end,
      })
    end,
  },

  -- =========================================================================
  -- Zen Mode
  -- =========================================================================

  {
    "folke/zen-mode.nvim",
        -- stylua: ignore
    keys = {
      { '<Leader>zz', '<Cmd>ZenMode<CR>', desc = 'ZenMode: toggle', },
    },
    opts = {
      -- your configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
    },
  },

  -- =========================================================================
  -- Noice
  -- =========================================================================

  -- {
  --   "folke/noice.nvim",
  --   config = function()
  --     require("noice").setup({
  --       -- add any options here
  --       routes = {
  --         -- {
  --         --   filter = {
  --         --     event = "msg_show",
  --         --     any = {
  --         --       { find = "%d+L, %d+B" },
  --         --       { find = "; after #%d+" },
  --         --       { find = "; before #%d+" },
  --         --       { find = "%d fewer lines" },
  --         --       { find = "%d more lines" },
  --         --     },
  --         --   },
  --         --   opts = { skip = true },
  --         -- },
  --       },
  --       throttle = 1000 / 30, -- how frequently does Noice need to check for ui updates? This has no effect when in blocking mode.
  --       -- lsp = {
  --       --   -- override markdown rendering so that **cmp** and other plugins use **Treesitter**
  --       --   hover = {
  --       --     enabled = true,
  --       --   },
  --       --   signature = {
  --       --     enabled = true,
  --       --   },
  --       --   override = {
  --       --     ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
  --       --     ["vim.lsp.util.stylize_markdown"] = true,
  --       --     ["cmp.entry.get_documentation"] = true,
  --       --   },
  --       -- },
  --     })
  --   end,
  --   dependencies = {
  --     -- if you lazy-load any plugin below, make sure to add proper `module="..."` entries
  --     "MunifTanjim/nui.nvim",
  --     -- OPTIONAL:
  --     --   `nvim-notify` is only needed, if you want to use the notification view.
  --     --   If not available, we use `mini` as the fallback
  --     "rcarriga/nvim-notify",
  --   },
  -- },

  -- =========================================================================
  -- Neorg
  -- =========================================================================

  -- {
  --   "nvim-neorg/neorg",
  --   config = function()
  --     require("neorg").setup({
  --       load = {
  --         ["core.defaults"] = {}, -- Loads default behaviour
  --         ["core.concealer"] = {}, -- Adds pretty icons to your documents
  --         ["core.presenter"] = {
  --           config = {
  --             zen_mode = "zen-mode",
  --           },
  --         },
  --         ["core.dirman"] = { -- Manages Neorg workspaces
  --           config = {
  --             workspaces = {
  --               home = "~/Documents/notes/home",
  --               work = "~/Documents/notes/work",
  --               -- home = "~/Documents/school-notes/notes",
  --               -- personal = "~/Documents/school-notes/personal",
  --               -- college = "~/Documents/school-notes/college",
  --             },
  --             index = "index.norg",
  --           },
  --         },
  --       },
  --       build = ":Neorg sync-parsers",
  --       dependencies = { { "nvim-lua/plenary.nvim" } },
  --     })
  --   end,
  -- },
}
