-- =========================================================================
-- ui: fzf
-- =========================================================================

return {
  -- Use the repo instead of the version in brew since it includes the help
  -- docs for fzf#run()
  {
    "junegunn/fzf",
    dependencies = {
      "junegunn/fzf.vim",
    },
  },
  {
    "junegunn/fzf.vim",
    init = function()
      vim.g.fzf_command_prefix = "FZF"
      vim.g.fzf_layout = { down = "~40%" }
      vim.g.fzf_buffers_jump = 1
    end,
  },
}
