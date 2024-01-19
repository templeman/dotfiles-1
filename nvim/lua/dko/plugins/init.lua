local SIGNS = require("dko.diagnostic").SIGNS

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
    config = true,
  },

  -- Replace vim.ui.select and vim.ui.input, which are used by things like
  -- vim.lsp.buf.code_action and rename
  -- Alternatively could use nvim-telescope/telescope-ui-select.nvim
  {
    "stevearc/dressing.nvim",
    event = "VeryLazy",
    -- dependencies = {
    --   "nvim-telescope/telescope.nvim",
    -- },
    config = function()
      require("dressing").setup({
        select = {
          get_config = function(opts)
            if opts.kind == "codeaction" then
              return {
                telescope = require("telescope.themes").get_cursor({
                  prompt_prefix = "🔍 ",
                }),
              }
            end
          end,
        },
      })
    end,
  },

  -- =========================================================================
  -- ui: buffer and window manipulation
  -- =========================================================================

  -- pretty format quickfix and loclist
  {
    "yorickpeterse/nvim-pqf",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      require("pqf").setup({
        signs = {
          error = SIGNS.Error,
          warning = SIGNS.Warn,
          hint = SIGNS.Hint,
          info = SIGNS.Info,
        },
        --show_multiple_lines = false,
      })
    end,
  },

  -- remove buffers without messing up window layout
  {
    "echasnovski/mini.bufremove",
    version = "*",
    config = function()
      require("mini.bufremove").setup()
    end,
  },

  {
    "ghillb/cybu.nvim",
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
          border = "rounded",
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
    keys = {
      "<C-w>o",
      "<C-w><C-o>",
    },
    cmd = {
      "ZoomWinTabIn",
      "ZoomWinTabOut",
      "ZoomWinTabToggle",
    },
  },

  -- resize window to selection, or split new window with selection size
  {
    "wellle/visual-split.vim",
    cmd = {
      "VSResize",
      "VSSplit",
      "VSSplitAbove",
      "VSSplitBelow",
    },
  },

  {
    "yorickpeterse/nvim-window",
    config = function()
      require("nvim-window").setup({})
      require("dko.mappings").bind_nvim_window()
    end,
  },

  -- remember/restore last cursor position in files
  {
    "ethanholz/nvim-lastplace",
    config = true,
  },

  -- =========================================================================
  -- ui: terminal
  -- =========================================================================

  {
    "akinsho/toggleterm.nvim",
    keys = require("dko.mappings").toggleterm_all_keys,
    cmd = "ToggleTerm",
    config = function()
      require("toggleterm").setup({
        float_opts = { border = "curved" },
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
    config = function()
      require("gitsigns").setup({
        on_attach = require("dko.mappings").bind_gitsigns,
        preview_config = { border = "rounded" },
      })
    end,
  },

  -- diff partial selections
  -- { "rickhowe/spotdiff.vim" },

  -- =========================================================================
  -- Reading
  -- =========================================================================

  -- jump to :line:column in filename:3:20
  -- https://github.com/lewis6991/fileline.nvim/
  { "lewis6991/fileline.nvim" },

  -- ]u [u mappings to jump to urls
  -- <A-u> to open link picker
  -- https://github.com/axieax/urlview.nvim
  {
    "axieax/urlview.nvim",
    keys = vim.tbl_values(require("dko.mappings").urlview),
    cmd = "UrlView",
    config = function()
      require("dko.mappings").bind_urlview()
    end,
  },

  -- highlight undo/redo text change
  -- https://github.com/tzachar/highlight-undo.nvim
  {
    "tzachar/highlight-undo.nvim",
    keys = { "u", "<c-r>" },
    config = function()
      require("highlight-undo").setup({})
    end,
  },

  -- package diff
  -- https://github.com/vuki656/package-info.nvim
  {
    "davidosomething/package-info.nvim",
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

  -- Works better than https://github.com/IndianBoy42/tree-sitter-just
  {
    "NoahTheDuke/vim-just",
    event = { "BufReadPre", "BufNewFile" },
    ft = { "\\cjustfile", "*.just", ".justfile" },
  },

  {
    "NvChad/nvim-colorizer.lua",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      require("colorizer").setup({
        buftypes = {
          "*",
          unpack(vim.tbl_map(function(v)
            return "!" .. v
          end, require("dko.utils.buffer").SPECIAL_BUFTYPES)),
        },
        filetypes = {
          "css",
          "html",
          "javascript",
          "javascriptreact",
          "scss",
          "typescript",
          "typescriptreact",
        },
        css = true,
        tailwind = true,
      })
    end,
  },

  -- =========================================================================
  -- Writing
  -- =========================================================================

  -- because https://github.com/neovim/neovim/issues/1496
  {
    "lambdalisue/suda.vim",
    cmd = "SudaWrite",
  },

  -- =========================================================================
  -- Editing
  -- =========================================================================

  {
    -- @TODO remove after nvim 0.11 released
    "ojroques/nvim-osc52",
    enabled = function()
      -- has built-in osc52? https://github.com/neovim/neovim/pull/25872/files
      -- was moved to vim.ui.clipboard in https://github.com/neovim/neovim/pull/26040
      return (vim.clipboard == nil and vim.ui.clipboard == nil)
        and require("dko.utils.vte").is_remote()
    end,
    config = function()
      local function copy(lines, _)
        require("osc52").copy(table.concat(lines, "\n"))
      end
      local function paste()
        local contents = vim.fn.getreg("") --[[@as string]]
        return { vim.fn.split(contents, "\n"), vim.fn.getregtype("") }
      end
      vim.g.clipboard = {
        name = "osc52",
        copy = { ["+"] = copy, ["*"] = copy },
        paste = { ["+"] = paste, ["*"] = paste },
      }

      local registers_to_copy = {
        "", -- unnamed, e.g. yy
        "+",
      }
      vim.api.nvim_create_autocmd("TextYankPost", {
        callback = function()
          if
            vim.v.event.operator == "y"
            and vim.list_contains(registers_to_copy, vim.v.event.regname)
          then
            require("osc52").copy_register("+")
          end
        end,
        desc = "copy + yanks into osc52",
      })
    end,
  },

  {
    "gbprod/yanky.nvim",
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
  {
    "numToStr/Comment.nvim",
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
  },

  -- Still using these over nvim-various-textobjs because they are dot
  -- repeatable.
  -- see https://github.com/chrisgrieser/nvim-various-textobjs/issues/7
  {
    "kana/vim-textobj-user",
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
      -- { '<localleader>od', '<Cmd>ObsidianToday<CR>', desc = 'obsidian: open daily note', },
      -- { '<localleader>on', ':ObsidianNew ', desc = 'obsidian: new note' },
      -- { '<localleader>oy', '<Cmd>ObsidianYesterday<CR>', desc = 'obsidian: previous daily note', },
      -- { '<localleader>oo', ':ObsidianOpen ', desc = 'obsidian: open in app' },
      { '<Leader>nv', '<Cmd>ObsidianSearch<CR>', desc = 'obsidian: search', },
      { '<Leader>os', '<Cmd>ObsidianQuickSwitch<CR>', desc = 'obsidian: quick switch', },
      -- { '<localleader>ot', '<Cmd>ObsidianTemplate<CR>', desc = 'obsidian: insert template', },
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "hrsh7th/nvim-cmp",
      "nvim-telescope/telescope.nvim",
    },
    config = function()
      require("obsidian").setup({
        -- disable_frontmatter = true,
        workspaces = {
          { name = "Notes", path = "~/Dropbox (Personal)/Notes" },
        },
        disable_frontmatter = true,
        -- Optional, for templates (see below).
        templates = {
          subdir = "Templates",
          -- date_format = "%Y-%m-%d",
          -- time_format = "%H:%M",
          -- A map for custom variables, the key should be the variable and the value a function
          substitutions = {
            yesterday = function()
              return os.date("%Y-%m-%d", os.time() - 60 * 60 * 24)
            end,
            tomorrow = function()
              return os.date("%Y-%m-%d", os.time() + 60 * 60 * 24)
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
          template = "Temporal/journal-nvim.md",
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
      })
    end,
  },

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
