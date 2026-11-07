-- TOML: taplo como LSP (diagnósticos/hover) y como formateador vía CLI; su LSP
-- no formatea archivos fuera de un workspace, el CLI sí.
return {
  { "nvim-treesitter/nvim-treesitter", opts = { ensure_installed = { "toml" } } },
  { "neovim/nvim-lspconfig", opts = { servers = { taplo = {} } } },
  { "stevearc/conform.nvim", opts = { formatters_by_ft = { toml = { "taplo" } } } },
}
