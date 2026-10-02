local BRACKETED_DISABLED = ""

return require("dko.utils.lazyspec")(function(ctx)
  ---@type LazySpec
  return {
    {
      -- Auto-update on filesystem events
      -- The built-in autoread will support filesystem events as of nvim-0.13
      -- as opposed to nvim-0.12 only supporting on FocusGained and other
      -- checktime events
      -- https://github.com/neovim/neovim/pull/37971
      "awalland/nvim-file-watch",
      cond = not ctx.is_giteditor and vim.fn.has("nvim-0.13") == 0,
      opts = { notify = false },
    },

    -- because https://github.com/neovim/neovim/issues/1496
    -- once https://github.com/neovim/neovim/pull/10842 is merged, there will
    -- probably be a better implementation for this
    -- { "lambdalisue/vim-suda", cmd = "SudaWrite" },
    --- https://github.com/gnsfujiwara/suda.nvim
    { "gnsfujiwara/suda.nvim", event = "VeryLazy" },

    {
      "nvim-mini/mini.align",
      version = false,
      config = function()
        require("mini.align").setup()
      end,
    },

    {
      "nvim-mini/mini.bracketed",
      cond = ctx.has_ui,
      version = false,
      opts = {
        -- nil -> keep mini's default suffix ("b"), whose ]b [b shadow Neovim's
        -- built-in ]b [b. In the git commit editor there's nothing to navigate,
        -- so disable it (and dko.mappings also deletes the built-in defaults).
        buffer = ctx.is_giteditor and { suffix = BRACKETED_DISABLED } or nil,
        -- comment = { suffix = "c" },
        -- conflict = { suffix = "x" },
        diagnostic = {
          --- something weird about the cursor positioning of this compared to the
          --- built-in ]d [d
          suffix = BRACKETED_DISABLED,
          -- options = {
          --   float = require("dko.settings").get("diagnostics.goto_float"),
          -- },
        },
        -- nil -> keep mini's default suffix ("f"); disabled in the git commit
        -- editor like `buffer` above.
        file = ctx.is_giteditor and { suffix = BRACKETED_DISABLED } or nil,
        indent = { suffix = BRACKETED_DISABLED }, -- confusing
        jump = { suffix = BRACKETED_DISABLED }, -- redundant
        -- location = { suffix = "l" },
        -- oldfile = { suffix = "o" },
        -- quickfix = { suffix = "q" },
        treesitter = { suffix = "n" }, -- n for node, default was t, using it for tab
        undo = { suffix = BRACKETED_DISABLED }, -- I'm using for url
        window = { suffix = BRACKETED_DISABLED }, -- broken going to unlisted
        yank = { suffix = BRACKETED_DISABLED }, -- confusing
      },
    },

    {
      "folke/snacks.nvim",
      priority = 1000,
      lazy = false,
      --- opts will be merged from other specs, e.g. from
      --- ./indent.lua
      --- ./components.lua
      opts = {
        styles = {
          notification = {
            wo = {
              winblend = 0,
            },
          },
        },
        picker = {
          layout = "ivy",
          win = {
            input = {
              keys = vim
                .iter({
                  require("dko.mappings.finder").features,
                })
                :fold({}, function(acc, features)
                  vim.iter(features):each(function(_, config)
                    acc[config.shortcut] = { "close", mode = { "n", "i" } }
                  end)
                  return acc
                end),
            },
          },
        },
      },
      config = true,
      init = function()
        vim.g.snacks_animate = false
      end,
    },

    -- https://github.com/AndrewRadev/bufferize.vim
    -- `:Bufferize messages` to get messages (or any :command) in a new buffer
    {
      "AndrewRadev/bufferize.vim",
      cmd = "Bufferize",
      config = function()
        vim.g.bufferize_command = "tabnew"
        vim.g.bufferize_keep_buffers = 1
      end,
    },

    -- =========================================================================
    -- ui: diagnostic
    -- =========================================================================

    -- Show diagnostic as virtual text at EOL
    -- https://github.com/rachartier/tiny-inline-diagnostic.nvim
    -- {
    --   "rachartier/tiny-inline-diagnostic.nvim",
    --   -- event = "VeryLazy",
    --   config = function()
    --     require("tiny-inline-diagnostic").setup({
    --       -- blend = {
    --       --   factor = 0.3,
    --       -- },
    --       -- options = {
    --       --   break_line = {
    --       --     enabled = true,
    --       --     after = 80,
    --       --   },
    --       --   multiple_diag_under_cursor = true,
    --       --   show_source = true,
    --       -- },
    --     })
    --     require("dko.settings").set("diagnostics.goto_float", false)
    --   end,
    -- },

    -- =========================================================================
    -- ui: buffer and window manipulation
    -- =========================================================================

    -- pretty format quickfix and loclist
    {
      "yorickpeterse/nvim-pqf",
      event = { "BufReadPost", "BufNewFile" },
      cond = ctx.has_ui,
      config = true,
    },

    -- remove buffers without messing up window layout
    -- https://github.com/nvim-mini/mini.bufremove
    {
      "nvim-mini/mini.bufremove",
      cond = ctx.has_ui,
      config = true,
      version = false, -- dev version
    },

    -- zoom in/out of a window
    -- this plugin accounts for command window and doesn't use sessions
    -- overrides <C-w>o (originally does an :only)
    {
      "troydm/zoomwintab.vim",
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
      cmd = {
        "VSResize",
        "VSSplit",
        "VSSplitAbove",
        "VSSplitBelow",
      },
    },

    -- <leader>w for picker
    -- https://github.com/yorickpeterse/nvim-window
    {
      "yorickpeterse/nvim-window",
      keys = vim.tbl_values(require("dko.mappings").nvim_window),
      config = function()
        require("nvim-window").setup({})
        require("dko.mappings").bind_nvim_window()
      end,
    },

    -- Remember/restore last cursor position in files
    --
    -- https://github.com/ethanholz/nvim-lastplace
    -- this plugin is archived by author
    -- maybe switch to https://github.com/vladdoster/remember.nvim if there are
    -- ever issues
    {
      "ethanholz/nvim-lastplace",
      cond = ctx.has_ui and not ctx.is_giteditor,
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
          float_opts = {
            border = require("dko.settings").get("winborder"),
          },
          -- built-in mappings only work on LAST USED terminal, so it confuses
          -- the buffer terminal with the floating terminal
          open_mapping = nil,
        })
        require("dko.mappings").bind_toggleterm()
      end,
    },

    {
      "nvim-mini/mini.files",
      version = false, -- use latest
      opts = {}, -- default setup
      keys = {
        {
          "<A-o>",
          function()
            require("mini.files").open() -- opens at current working directory
            -- or, to open at current buffer's directory:
            -- require("mini.files").open(vim.api.nvim_buf_get_name(0), true)
          end,
          desc = "Mini Files: open",
        },
      },
      config = function()
        require("mini.files").setup()
      end,
    },

    -- =========================================================================
    -- ui: diffing
    -- =========================================================================

    -- diff partial selections
    -- { "rickhowe/spotdiff.vim" },

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
      cond = ctx.has_ui,
    },

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

    -- =========================================================================
    -- Syntax
    -- =========================================================================

    -- highlight matching html/xml tag
    -- % textobject
    {
      "andymass/vim-matchup",
      cond = ctx.has_ui,
      -- author recommends against lazy loading
      lazy = false,
      init = function()
        vim.g.matchup_matchparen_deferred = 1
        vim.g.matchup_matchparen_status_offscreen = 0
      end,
    },

    -- Better highlighting than treesitter
    { "NoahTheDuke/vim-just" },

    -- https://github.com/brenoprata10/nvim-highlight-colors
    -- see output comparison here https://www.reddit.com/r/neovim/comments/1b5gw12/nvimhighlightcolors_now_supports_virtual_text/kt8gog6/?share_id=aUVLJ5zC3yMKjFuHqumGE
    -- can request and colorize from LSP textDocument/documentColor if available
    {
      "brenoprata10/nvim-highlight-colors",
      cond = ctx.has_ui,
      event = { "BufReadPost", "BufNewFile" },
      opts = {
        ---@usage 'background'|'foreground'|'virtual'
        render = "background",
        -- virtual_symbol_position = 'eow',
        -- virtual_symbol_prefix = ' ',
        -- virtual_symbol_suffix = '',
        ---Highlight tailwind colors, e.g. 'bg-blue-500'
        enable_tailwind = true,
        enable_var_usage = true,
        exclude_filetypes = {
          "lazy",
        },
      },
    },

    -- https://github.com/catgoose/nvim-colorizer.lua
    -- {
    --   "catgoose/nvim-colorizer.lua",
    --   cond = ctx.has_ui,
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

    --- A yank-ring
    --- https://github.com/gbprod/yanky.nvim
    {
      "gbprod/yanky.nvim",
      cond = ctx.has_ui,
      event = { "BufReadPost", "BufNewFile" },
      config = function()
        require("yanky").setup({
          highlight = { timer = 300 },
        })
        require("dko.mappings").bind_yanky()
      end,
    },

    -- Override <A-hjkl> to move lines in any mode
    -- NB: Normally in insert mode, <A-hjkl> will exit insert and move cursor.
    -- You can use arrow keys in insert mode, so it's a little redundant.
    {
      "nvim-mini/mini.move",
      cond = ctx.has_ui,
      config = true,
    },

    -- gcc / <Leader>gbc to comment with treesitter integration
    -- 0.10 has built-in treesitter comments, see :h commenting
    -- BUT it does not properly do jsx/tsx which is provided by
    -- ts_context_commentstring
    -- https://github.com/numToStr/Comment.nvim
    {
      "numToStr/Comment.nvim",
      cond = ctx.has_ui,
      event = { "BufReadPost", "BufNewFile" },
      dependencies = {
        {
          -- https://github.com/JoosepAlviste/nvim-ts-context-commentstring
          "JoosepAlviste/nvim-ts-context-commentstring",
          -- No longer needs nvim-treesitter after https://github.com/JoosepAlviste/nvim-ts-context-commentstring/pull/80
          opts = {
            -- Disable for Comment.nvim https://github.com/JoosepAlviste/nvim-ts-context-commentstring/wiki/Integrations#commentnvim
            enable_autocmd = false,
          },
        },
      },
      config = function()
        require("Comment").setup(
          require("dko.mappings").with_commentnvim_mappings({
            -- add treesitter support, want tsx/jsx in particular
            pre_hook = require(
              "ts_context_commentstring.integrations.comment_nvim"
            ).create_pre_hook(),
          })
        )
      end,
    },

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
      enabled = false,
      ft = {
        "lua",
        "javascript",
        "typescript",
        "typescriptreact",
        "javascriptreact",
        "python",
        "go",
        "rust",
        "php",
      },
      -- init = function()
      --   vim.g.copilot_filetypes = {
      --     markdown = false,
      --   }
      -- end,
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
      "obsidian-nvim/obsidian.nvim",
      version = "*", -- recommended, use latest release instead of latest commit
      lazy = true,
      -- vault paths, periodic notes, template substitutions: lua/dko/obsidian.lua
      event = require("dko.obsidian").lazy_events(),
      keys = require("dko.obsidian").keys,
      dependencies = {
        -- Required.
        "nvim-lua/plenary.nvim",
        "nvim-treesitter/nvim-treesitter",
        "hrsh7th/nvim-cmp",
        "nvim-telescope/telescope.nvim",
      },
      config = function()
        local dko_obsidian = require("dko.obsidian")
        require("obsidian").setup({
          legacy_commands = false,
          workspaces = dko_obsidian.workspaces(),
          picker = {
            -- Set your preferred picker. Can be one of 'telescope.nvim', 'fzf-lua', 'snacks.pick' or 'mini.pick'.
            name = "telescope.nvim",
          },
          -- Templates own the frontmatter; obsidian.nvim never rewrites it.
          frontmatter = {
            enabled = false,
            sort = false,
          },
          completion = {
            min_chars = 2,
          },
          -- `:Obsidian quick_switch` shows latest modified first
          search = {
            sort_by = "modified",
            sort_reversed = true,
          },
          new_notes_location = "notes_subdir",
          -- Human-readable filenames: the note id is its title.
          note_id_func = function(title)
            return title
          end,
          callbacks = {
            post_setup = dko_obsidian.post_setup,
          },
        })
        dko_obsidian.attach_buffer_maps()
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

    -- vim-sandwich provides a textobj!
    -- sa/sr/sd operators and ib/ab textobjs
    -- https://github.com/nvim-mini/mini.surround -- no textobj
    -- https://github.com/kylechui/nvim-surround -- no textobj
    {
      "machakann/vim-sandwich",
      cond = ctx.has_ui,
    },

    -- https://github.com/chrisgrieser/nvim-various-textobj
    {
      "chrisgrieser/nvim-various-textobjs",
      cond = ctx.has_ui,
      config = function()
        require("various-textobjs").setup({
          keymaps = {
            useDefaults = false,
          },
          textobjs = {
            indentation = {
              -- `false`: only indentation decreases delimit the text object
              -- `true`: indentation decreases as well as blank lines serve as delimiter
              blanksAreDelimiter = false,
            },
          },
        })
        require("dko.mappings").bind_nvim_various_textobjs()
      end,
    },
  }
end)
