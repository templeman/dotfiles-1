--- https://github.com/neovim/nvim-lspconfig/blob/master/lsp/intelephense.lua
--- https://github.com/bmewburn/intelephense-docs

local xdg = {
  cache = vim.env.XDG_CACHE_HOME or vim.fs.joinpath(vim.env.HOME, ".cache"),
  config = vim.env.XDG_CONFIG_HOME or vim.fs.joinpath(vim.env.HOME, ".config"),
  data = vim.env.XDG_DATA_HOME
    or vim.fs.joinpath(vim.env.HOME, ".local", "share"),
}

-- Optional premium licence, plain text file
local licence = vim.fs.joinpath(xdg.config, "intelephense", "licence.txt")

-- Extra stubs from global composer packages (php/install-composer-packages)
local composer_home = vim.env.COMPOSER_HOME
  or vim.fs.joinpath(xdg.config, "composer")
local include_paths = vim
  .iter({ "php-stubs/wp-cli-stubs" })
  :map(function(pkg)
    return vim.fs.joinpath(composer_home, "vendor", pkg)
  end)
  :filter(function(path)
    return vim.fn.isdirectory(path) == 1
  end)
  :totable()

---@type vim.lsp.Config
return {
  filetypes = { "php" },
  root_markers = {
    "wp-cli.yml",
    "composer.json",
    ".git",
  },
  init_options = {
    -- Defaults are os.tmpdir() and ~/intelephense
    storagePath = vim.fs.joinpath(xdg.cache, "intelephense"),
    globalStoragePath = vim.fs.joinpath(xdg.data, "intelephense"),
    licenceKey = vim.fn.filereadable(licence) == 1 and licence or nil,
  },
  ---@type lspconfig.settings.intelephense
  settings = {
    intelephense = {
      telemetry = { enabled = false },
      -- phpcbf via efm formats WPCS projects, see dko/tools/php.lua
      format = { enable = false },
      environment = { includePaths = include_paths },
      files = {
        maxSize = 5000000,
        exclude = {
          "**/.git/**",
          "**/node_modules/**",
          "**/vendor/**/{Tests,tests}/**",
          -- Bedrock installs core here, wordpress stubs cover it
          "**/web/wp/**",
        },
      },
      -- Intelephense defaults plus wordpress
      stubs = {
        "apache",
        "bcmath",
        "bz2",
        "calendar",
        "com_dotnet",
        "Core",
        "ctype",
        "curl",
        "date",
        "dba",
        "dom",
        "enchant",
        "exif",
        "FFI",
        "fileinfo",
        "filter",
        "fpm",
        "ftp",
        "gd",
        "gettext",
        "gmp",
        "hash",
        "iconv",
        "imagick",
        "imap",
        "intl",
        "json",
        "ldap",
        "libxml",
        "mbstring",
        "meta",
        "mysqli",
        "oci8",
        "odbc",
        "openssl",
        "pcntl",
        "pcre",
        "PDO",
        "pgsql",
        "Phar",
        "posix",
        "pspell",
        "random",
        "readline",
        "redis",
        "Reflection",
        "session",
        "shmop",
        "SimpleXML",
        "snmp",
        "soap",
        "sockets",
        "sodium",
        "SPL",
        "sqlite3",
        "standard",
        "superglobals",
        "sysvmsg",
        "sysvsem",
        "sysvshm",
        "tidy",
        "tokenizer",
        "wordpress",
        "xml",
        "xmlreader",
        "xmlrpc",
        "xmlwriter",
        "xsl",
        "Zend OPcache",
        "zip",
        "zlib",
      },
    },
  },
}
