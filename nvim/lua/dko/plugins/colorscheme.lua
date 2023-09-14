return {
  {
    --"davidosomething/vim-colors-meh",
    "lifepillar/vim-solarized8",
    dependencies = {
      --"rakr/vim-two-firewatch",
      {
        "mcchrish/zenbones.nvim",
        lazy = true,
        dependencies = { "rktjmp/lush.nvim" },
      },
    },
    branch = "neovim",
    --dev = true,
    lazy = false,
    priority = 1000,
    init = function()
      -- require("dko.settings").set("colors.dark", "meh")
      -- require("dko.settings").set("colors.light", "zenbones")
    end,
    config = function()
      vim.cmd.colorscheme("solarized8")
      if vim.env.TERM_PROGRAM == "WezTerm" then
        require("dko.colors").wezterm_sync()
      end
    end,
  },
}
