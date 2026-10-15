local tools = require("dko.tools")

-- efm runs commands via sh with cwd at the matched rootMarker, so prefer the
-- project's composer bin and fall back to the global ($COMPOSER_HOME) one
---@param bin string
---@return string
local function composer_bin(bin)
  return ("$([ -x vendor/bin/%s ] && echo vendor/bin/%s || echo %s)"):format(
    bin,
    bin,
    bin
  )
end

local PHPCS_RULESETS = {
  ".phpcs.xml",
  "phpcs.xml",
  ".phpcs.xml.dist",
  "phpcs.xml.dist",
}

-- bin/dko-php-style is Pint-first: projects with a pint.json (e.g. Roots
-- Bedrock/Sage) are formatted by Pint and phpcs stays quiet there. Otherwise
-- phpcs lints and phpcbf formats. It also skips git-ignored files (composer-
-- installed plugins) and the ruleset's <exclude-pattern>s when formatting.
tools.register({
  fts = { "php" },
  name = "phpcs",
  efm = function()
    ---@type EfmLinter
    return vim.tbl_extend("force", require("efmls-configs.linters.phpcs"), {
      lintCommand = 'dko-php-style lint "${INPUT}"',
    })
  end,
})

-- Only format in projects that opt into a style config; other PHP is left
-- alone (use :call PhpCsFixerFixFile() there).
tools.register({
  fts = { "php" },
  name = "php-style",
  efm = function()
    ---@type EfmFormatter
    return {
      formatCommand = 'dko-php-style format "${INPUT}"',
      formatStdin = true,
      requireMarker = true,
      rootMarkers = vim.list_extend({ "pint.json" }, PHPCS_RULESETS),
    }
  end,
})

-- Only where the project configures phpstan. Reads the file from disk, so
-- results reflect the last write.
tools.register({
  fts = { "php" },
  name = "phpstan",
  efm = function()
    ---@type EfmLinter
    return vim.tbl_extend("force", require("efmls-configs.linters.phpstan"), {
      lintCommand = composer_bin("phpstan")
        .. ' analyse --memory-limit=1G --no-progress --no-ansi --error-format=raw "${INPUT}"',
      requireMarker = true,
      rootMarkers = { "phpstan.neon", "phpstan.neon.dist" },
    })
  end,
})

-- Sage views
tools.register({
  fts = { "blade" },
  name = "blade-formatter",
  efm = function()
    return require("efmls-configs.formatters.blade_formatter")
  end,
})

-- WordPress stubs, hover, completion -- see after/lsp/intelephense.lua
tools.register({
  name = "intelephense",
  runner = "lspconfig",
})
