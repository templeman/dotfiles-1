local dev = vim.env.NVIM_DEV ~= nil

return require("dko.utils.lazyspec")(function(ctx)
  ---@type LazySpec
  return {
    {
      -- "davidosomething/vim-colors-meh",
      url = "https://codeberg.org/lifepillar/vim-solarized8",
      branch = "neovim",
      cond = ctx.has_ui,
      dependencies = {
        -- { "rakr/vim-two-firewatch", lazy = true },
        -- {
        --   "mcchrish/zenbones.nvim",
        --   lazy = true,
        --   dependencies = { "rktjmp/lush.nvim" },
        -- },
        -- "ntk148v/komau.vim",
        "oskarnurm/koda.nvim",
      },
      dev = dev,
      lazy = false,
      priority = 1000,
      init = function()
        require("dko.settings").set("colors.dark", "solarized8")
        require("dko.settings").set("colors.light", "koda-glade")
      end,
      config = function()
        vim.cmd.colorscheme("solarized8")
        -- NormalFloat has no fg by default; link it to Normal so all float
        -- windows (snacks scratch, pickers, etc.) inherit solarized8 colors.
        -- Re-apply on ColorScheme so wezterm dark/light switching keeps it.
        local function fix_highlights()
          vim.api.nvim_set_hl(0, "NormalFloat", { link = "Normal" })
          -- Badge color for heirline filetype/terminal components: dark navy bg
          -- (base02) with silver fg (base0), derived from StatusLine's raw
          -- fg/bg so it's unaffected by plugins that override Pmenu.
          local sl = vim.api.nvim_get_hl(0, { name = "StatusLine", link = false })
          vim.api.nvim_set_hl(0, "dkoStatusKey", { fg = sl.fg, bg = sl.bg })
        end
        vim.schedule(fix_highlights)
        vim.api.nvim_create_autocmd("ColorScheme", {
          group = vim.api.nvim_create_augroup(
            "dko_highlights",
            { clear = true }
          ),
          callback = fix_highlights,
        })
        if vim.env.TERM_PROGRAM == "WezTerm" then
          require("dko.colors").wezterm_sync()
        end
      end,
    },
  }
end)
