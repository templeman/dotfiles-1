-- =========================================================================
-- LSP
-- Scaffold dependencies like LazyVim
-- https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/plugins/lsp/init.lua
-- =========================================================================

-- Tools to auto-install with mason
-- Must then be configured, e.g. as null-ls formatter or diagnostic provider
local extras = {
  "editorconfig-checker",
  "markdownlint",
  "stylua",
  "vint",
}

-- LSPs to install with mason via mason-lspconfig
-- https://github.com/williamboman/mason-lspconfig.nvim#available-lsp-servers
local lsps = {
  "ansiblels",
  "bashls",
  "cssls",
  "cssmodules_ls", -- jumping into classnames from jsx/tsx
  "docker_compose_language_service",
  "dockerls",
  "eslint",
  "html",
  "jsonls",
  "stylelint_lsp",
  "lua_ls",
  --"pyright" -- eventually add this or ruff_lsp
  "tailwindcss",
  "tsserver",
  "vimls",
  "yamlls",
}
if vim.fn.executable("go") == 1 then
  table.insert(lsps, "gopls")
end

-- Lazy.nvim specs
return {
  {
    "jose-elias-alvarez/null-ls.nvim",
    dependencies = {
      "jose-elias-alvarez/typescript.nvim",
      "nvim-lua/plenary.nvim",
    },
    config = function()
      local null_ls = require("null-ls")

      -- =====================================================================
      -- Configure formatters
      -- =====================================================================

      local formatters = {
        null_ls.builtins.formatting.markdownlint,
        null_ls.builtins.formatting.prettier,
        null_ls.builtins.formatting.qmlformat,
        null_ls.builtins.formatting.shfmt,
        null_ls.builtins.formatting.stylua,
      }
      for i, provider in ipairs(formatters) do
        formatters[i] = provider.with({
          runtime_condition = function(params)
            require("dko.lsp").null_ls_notify_on_format(params)
            local original = provider.runtime_condition
            if original ~= nil then
              return original()
            end
            return true
          end,
        })
      end

      -- =====================================================================
      -- Configure diagnostics
      -- =====================================================================

      local diagnostics = {
        null_ls.builtins.diagnostics.editorconfig_checker,
        null_ls.builtins.diagnostics.markdownlint,
        null_ls.builtins.diagnostics.qmllint,
        null_ls.builtins.diagnostics.vint,
        null_ls.builtins.diagnostics.zsh,

        -- selene not picking up config
        null_ls.builtins.diagnostics.selene.with({
          extra_args = function(params)
            local results = vim.fs.find({ "selene.toml" }, {
              upward = true,
              path = vim.api.nvim_buf_get_name(0),
            })
            if #results == 0 then
              return params
            end
            return { "--config", results[1] }
          end,
        }),
      }
      -- Switch ALL diagnostics to DIAGNOSTICS_ON_SAVE only
      -- or null_ls will keep spamming LSP events
      --[[ for i, provider in ipairs(diagnostics) do
        -- @TODO handle existing runtime_condition?
        diagnostics[i] = provider.with({
          method = null_ls.methods.DIAGNOSTICS_ON_SAVE,
        })
      end ]]

      -- =====================================================================
      -- Combine sources
      -- =====================================================================

      local sources = {
        -- provide the typescript.nvim commands as LSP actions
        require("typescript.extensions.null-ls.code-actions"),

        -- add gitsigns.nvim commands
        null_ls.builtins.code_actions.gitsigns.with({
          config = {
            filter_actions = function(title)
              -- only want the "preview hunk" action, I do git stuff in
              -- terminal
              return title:lower():match("preview") ~= nil
            end,
          },
        }),

        -- bashls does not provide these quick ignore actions
        null_ls.builtins.code_actions.shellcheck,
      }
      require("dko.utils.table").concat(sources, formatters)
      require("dko.utils.table").concat(sources, diagnostics)

      -- =====================================================================
      -- Apply config
      -- =====================================================================

      null_ls.setup({
        border = "rounded",
        sources = sources,
        -- defaults to false, but lets just sync it in case I want to change
        -- in my diagnostic-lsp.lua
        update_in_insert = vim.diagnostic.config().update_in_insert,
      })
    end,
  },

  {
    "folke/neodev.nvim",
    config = function()
      require("neodev").setup({
        override = function(root_dir, library)
          if string.find(root_dir, ".nvim") then
            library.enabled = true
            library.plugins = true
          end
        end,
      })
    end,
  },

  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "folke/neodev.nvim",
    },
  },

  {
    "williamboman/mason.nvim",
    lazy = false,
    config = function()
      require("mason").setup({
        ui = {
          border = "rounded",
          icons = {
            package_installed = "✓",
            package_pending = "➜",
            package_uninstalled = "✗",
          },
        },
      })
      -- Auto-install some linters for null-ls
      -- https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/plugins/lsp/init.lua#L157-L163
      local mr = require("mason-registry")
      for _, tool in ipairs(extras) do
        local p = mr.get_package(tool)
        if not p:is_installed() then
          p:install()
        end
      end
    end,
  },

  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = {
      "b0o/schemastore.nvim", -- wait for schemastore for jsonls
      "hrsh7th/cmp-nvim-lsp", -- provides some capabilities
      "jose-elias-alvarez/typescript.nvim",
      "neovim/nvim-lspconfig", -- wait for lspconfig, which waits for neodev
    },
    config = function()
      local masonLspConfig = require("mason-lspconfig")
      masonLspConfig.setup({
        ensure_installed = lsps,
        automatic_installation = true,
      })

      local cmpNvimLsp = require("cmp_nvim_lsp")

      local defaultOptions = {
        capabilities = cmpNvimLsp.default_capabilities(),
      }

      local lspconfig = require("lspconfig")

      -- Note that instead of on_attach for each server setup,
      -- diagnostic-lsp.lua has an autocmd defined
      masonLspConfig.setup_handlers({
        function(server)
          lspconfig[server].setup(defaultOptions)
        end,

        ["bashls"] = function()
          lspconfig.bashls.setup(vim.tbl_extend("force", defaultOptions, {
            settings = {
              bashIde = {
                shellcheckArguments = "--exclude=SC1090,SC1091",
              },
            },
          }))
        end,

        ["jsonls"] = function()
          lspconfig.jsonls.setup(vim.tbl_extend("force", defaultOptions, {
            settings = {
              json = {
                schemas = require("schemastore").json.schemas(),
                validate = { enable = true },
              },
            },
          }))
        end,

        ['lua_ls'] = function()
          lspconfig.lua_ls.setup(vim.tbl_extend("force", defaultOptions, {
            settings = {
              Lua = {
                workspace = {
                  maxPreload = 1000,
                  preloadFileSize = 500,
                  checkThirdParty = false,
                },
              },
            }
          }))
        end,

        ["stylelint_lsp"] = function()
          lspconfig.stylelint_lsp.setup(
            vim.tbl_extend("force", defaultOptions, {
              -- Disable on some filetypes
              -- https://github.com/neovim/nvim-lspconfig/blob/master/lua/lspconfig/server_configurations/stylelint_lsp.lua
              filetypes = {
                "css",
                "less",
                "scss",
                "sugarss",
                -- 'vue',
                "wxss",
                -- 'javascript',
                -- 'javascriptreact',
                -- 'typescript',
                -- 'typescriptreact',
              },
            })
          )
        end,

        ["tsserver"] = function()
          -- use jose-elias-alvarez/typescript.nvim instead
          -- This will do lspconfig.tsserver.setup()
          require("typescript").setup(defaultOptions)
        end,
      })
    end,
  },
}