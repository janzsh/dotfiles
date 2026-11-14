-- Go: gopls (LSP) + goimports (ordena imports y formatea como gofmt).
-- Paquetes en nix/home/janz/neovim.nix. Opciones de buffer: ftplugin/go.lua.
return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "go", "gomod", "gosum", "gowork" } },
  },
  { "neovim/nvim-lspconfig", opts = { servers = { gopls = {} } } },
  {
    "stevearc/conform.nvim",
    opts = { formatters_by_ft = { go = { "goimports" } } },
  },
}
