local tools = require("dko.tools")

tools.register({
  type = "tool",
  require = "python",
  name = "vint",
  runner = "efm",
  efm = function()
    return {
      languages = { "vim" },
      config = require("efmls-configs.linters.vint"),
    }
  end,
})

tools.register({
  type = "lsp",
  require = "npm",
  name = "vimls",
})