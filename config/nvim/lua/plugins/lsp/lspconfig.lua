-- Base del LSP. No sabe de lenguajes: cada archivo de lua/plugins/lang/ añade
-- sus servidores a `opts.servers` (se mezclan solos) y aquí se habilitan.
-- nvim-lspconfig aporta los defaults (cmd, filetypes, root_markers) de cada
-- servidor; los binarios vienen de nix/home/janz/neovim.nix (no de mason).
return {
  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = { "saghen/blink.cmp" }, -- sus capabilities deben existir antes de iniciar los servidores
  opts = {
    servers = {}, -- nombre = config (tabla vacía = defaults); `false` lo desactiva
  },
  config = function(_, opts)
    vim.lsp.config("*", {
      capabilities = require("blink.cmp").get_lsp_capabilities(),
    })

    for name, cfg in pairs(opts.servers) do
      if cfg ~= false then
        vim.lsp.config(name, cfg)
        vim.lsp.enable(name)
      end
    end

    vim.diagnostic.config({
      virtual_text = { spacing = 4 },
      severity_sort = true,
      signs = {
        text = {
          [vim.diagnostic.severity.ERROR] = " ",
          [vim.diagnostic.severity.WARN] = " ",
          [vim.diagnostic.severity.INFO] = " ",
          [vim.diagnostic.severity.HINT] = "󰞏 ",
        },
      },
    })
  end,
}
