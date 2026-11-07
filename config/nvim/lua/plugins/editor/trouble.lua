return {
  "folke/trouble.nvim",
  cmd = "Trouble",
  opts = {},
  keys = {
    { "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnósticos (proyecto)" },
    { "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Diagnósticos (buffer)" },
    { "<leader>xL", "<cmd>Trouble loclist toggle<cr>", desc = "Location list" },
    { "<leader>xQ", "<cmd>Trouble qflist toggle<cr>", desc = "Quickfix" },
    { "<leader>cs", "<cmd>Trouble symbols toggle focus=false<cr>", desc = "Símbolos" },
    { "<leader>cl", "<cmd>Trouble lsp toggle focus=false win.position=right<cr>", desc = "Definiciones/referencias LSP" },
  },
}
