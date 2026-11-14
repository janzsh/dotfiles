-- Lua (sobre todo esta misma config): lua_ls + stylua. lazydev da a lua_ls los
-- tipos de la API de Neovim y de los plugins instalados.
return {
  { "nvim-treesitter/nvim-treesitter", opts = { ensure_installed = { "lua", "luadoc" } } },
  { "neovim/nvim-lspconfig", opts = { servers = { lua_ls = {} } } },
  { "stevearc/conform.nvim", opts = { formatters_by_ft = { lua = { "stylua" } } } },
  {
    "folke/lazydev.nvim",
    ft = "lua",
    opts = { library = { { path = "${3rd}/luv/library", words = { "vim%.uv" } } } },
  },
  {
    "saghen/blink.cmp",
    opts = {
      sources = {
        per_filetype = { lua = { inherit_defaults = true, "lazydev" } },
        providers = {
          lazydev = { name = "LazyDev", module = "lazydev.integrations.blink", score_offset = 100 },
        },
      },
    },
  },
}
