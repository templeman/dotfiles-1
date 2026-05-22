local claude = vim.fn.exepath("claude")
if claude == "" then
  claude = "claude"
end

return {
  {
    "coder/claudecode.nvim",
    dependencies = { "folke/snacks.nvim" },
    cmd = {
      "ClaudeCode",
      "ClaudeCodeFocus",
      "ClaudeCodeSend",
      "ClaudeCodeAdd",
      "ClaudeCodeDiffAccept",
      "ClaudeCodeDiffDeny",
      "ClaudeCodeSelectModel",
    },
    opts = {
      terminal_cmd = claude, -- works well with mise shims
      git_repo_cwd = true, -- open Claude at repo root when possible
      focus_after_send = false,
      terminal = {
        provider = "auto", -- lets the plugin use snacks/native terminal handling
        split_side = "right",
        split_width_percentage = 0.33,
        auto_close = true,
      },
      diff_opts = {
        layout = "vertical",
        open_in_new_tab = false,
        keep_terminal_focus = false,
      },
    },
    config = true,
  },
}
