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
  -- Depurar con delve; también `go test` del cursor (dap-go.debug_test).
  { "leoluz/nvim-dap-go", ft = "go", dependencies = { "mfussenegger/nvim-dap" }, opts = {} },
  {
    "nvim-neotest/neotest",
    dependencies = { "fredrikaverpil/neotest-golang" },
    opts = { adapters = { ["neotest-golang"] = {} } },
  },
}
