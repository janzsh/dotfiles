-- Resalta TODO/FIX/NOTE... en los comentarios y permite listarlos.
return {
  "folke/todo-comments.nvim",
  event = { "BufReadPost", "BufNewFile" },
  dependencies = { "nvim-lua/plenary.nvim" },
  keys = {
    { "]t", function() require("todo-comments").jump_next() end, desc = "Siguiente TODO" },
    { "[t", function() require("todo-comments").jump_prev() end, desc = "TODO anterior" },
    { "<leader>ft", "<cmd>TodoTelescope<cr>", desc = "Buscar TODOs" },
    { "<leader>xt", "<cmd>Trouble todo toggle<cr>", desc = "TODOs (Trouble)" },
  },
  opts = {
    -- Nombres de grupo de resaltado en vez de hex: siguen al tema activo.
    keywords = {
      FIX = { icon = "󱚡 ", color = "error", alt = { "ERROR", "BUG", "ISSUE" } },
      TODO = { icon = " ", color = "info" },
      WARN = { icon = " ", color = "warning", alt = { "WARNING" } },
      PERF = { icon = "󰾆 ", color = "hint", alt = { "OPTIMIZE", "PERFORMANCE" } },
      NOTE = { icon = "󰍩 ", color = "hint", alt = { "INFO" } },
      TEST = { icon = "󰙨 ", color = "default", alt = { "TESTING" } },
    },
  },
}
