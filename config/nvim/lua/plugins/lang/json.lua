-- JSON: jsonls (vscode-langservers-extracted); formatea por el fallback LSP.
return {
  { "nvim-treesitter/nvim-treesitter", opts = { ensure_installed = { "json" } } },
  { "neovim/nvim-lspconfig", opts = { servers = { jsonls = {} } } },
}
