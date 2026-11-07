-- Python: basedpyright (tipos) + ruff (lint por LSP y formato).
-- Paquetes en nix/home/janz/neovim.nix. Opciones de buffer: ftplugin/python.lua.
return {
  { "nvim-treesitter/nvim-treesitter", opts = { ensure_installed = { "python" } } },
  { "neovim/nvim-lspconfig", opts = { servers = { basedpyright = {}, ruff = {} } } },
  {
    "stevearc/conform.nvim",
    opts = { formatters_by_ft = { python = { "ruff_organize_imports", "ruff_format" } } },
  },
}
