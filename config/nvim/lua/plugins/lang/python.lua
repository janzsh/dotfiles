-- Python: basedpyright (tipos) + ruff (lint por LSP y formato).
-- Paquetes en nix/home/janz/neovim.nix. Opciones de buffer: ftplugin/python.lua.
return {
  { "nvim-treesitter/nvim-treesitter", opts = { ensure_installed = { "python" } } },
  { "neovim/nvim-lspconfig", opts = { servers = { basedpyright = {}, ruff = {} } } },
  {
    "stevearc/conform.nvim",
    opts = { formatters_by_ft = { python = { "ruff_organize_imports", "ruff_format" } } },
  },
  -- debugpy-adapter viene de python3Packages.debugpy (nix); usa el python del
  -- venv activo para ejecutar el programa.
  {
    "mfussenegger/nvim-dap-python",
    ft = "python",
    dependencies = { "mfussenegger/nvim-dap" },
    config = function() require("dap-python").setup("debugpy-adapter") end,
  },
  {
    "nvim-neotest/neotest",
    dependencies = { "nvim-neotest/neotest-python" },
    opts = { adapters = { ["neotest-python"] = { dap = { justMyCode = false } } } },
  },
}
