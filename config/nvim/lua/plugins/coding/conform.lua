-- Formateo. Cada archivo de lua/plugins/lang/ añade su `formatters_by_ft`.
-- Sin formateador para un filetype, cae al LSP (lsp_format = "fallback").
return {
  "stevearc/conform.nvim",
  event = "BufWritePre",
  cmd = "ConformInfo",
  keys = {
    {
      "<leader>cf",
      function() require("conform").format({ async = true }) end,
      desc = "Formatear buffer",
    },
  },
  opts = {
    formatters_by_ft = {},
    default_format_opts = { lsp_format = "fallback" },
    format_on_save = { timeout_ms = 1000, lsp_format = "fallback" },
  },
}
