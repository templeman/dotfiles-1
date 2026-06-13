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
        local function fix_normalfloat()
          vim.api.nvim_set_hl(0, "NormalFloat", { link = "Normal" })
        end
        fix_normalfloat()
        vim.api.nvim_create_autocmd("ColorScheme", {
          group = vim.api.nvim_create_augroup("dko_normalfloat", { clear = true }),
          callback = fix_normalfloat,
        })
        if vim.env.TERM_PROGRAM == "WezTerm" then
          require("dko.colors").wezterm_sync()
        end
      end,
    },
  }
end)
