-- Cmdline flotante, mensajes y notificaciones con mejor presentación.
return {
  "folke/noice.nvim",
  event = "VeryLazy",
  keys = {
    { "<leader>nh", "<cmd>Noice history<cr>", desc = "Historial de mensajes" },
    { "<leader>nl", "<cmd>Noice last<cr>", desc = "Último mensaje" },
    { "<leader>nd", "<cmd>Noice dismiss<cr>", desc = "Ocultar notificaciones" },
  },
  dependencies = {
    "MunifTanjim/nui.nvim",
    {
      "rcarriga/nvim-notify",
      opts = { render = "compact", stages = "fade", timeout = 3000, top_down = false },
    },
  },
  opts = {
    lsp = {
      override = {
        ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
        ["vim.lsp.util.stylize_markdown"] = true,
      },
      -- La firma de funciones ya la muestra blink.cmp; evita duplicarla.
      signature = { enabled = false },
    },
    presets = {
      bottom_search = true,
      command_palette = true,
      long_message_to_split = true,
      lsp_doc_border = true,
    },
    routes = {
      -- "archivo escrito" en cada guardado es ruido.
      { filter = { event = "msg_show", kind = "", find = "written" }, opts = { skip = true } },
    },
  },
}
