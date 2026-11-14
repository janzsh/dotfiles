local keys = {
  { "<S-h>", "<cmd>BufferLineCyclePrev<cr>", desc = "Buffer anterior" },
  { "<S-l>", "<cmd>BufferLineCycleNext<cr>", desc = "Buffer siguiente" },
  { "<leader>bd", function() require("bufdelete").bufdelete(0, false) end, desc = "Cerrar buffer" },
  { "<leader>bo", "<cmd>BufferLineCloseOthers<cr>", desc = "Cerrar los demás" },
  { "<leader>bp", "<cmd>BufferLineTogglePin<cr>", desc = "Fijar buffer" },
  { "<leader>bb", "<cmd>BufferLinePick<cr>", desc = "Elegir buffer por letra" },
  { "<leader>bh", "<cmd>BufferLineMovePrev<cr>", desc = "Mover buffer a la izquierda" },
  { "<leader>bl", "<cmd>BufferLineMoveNext<cr>", desc = "Mover buffer a la derecha" },
  { "<leader>bH", "<cmd>BufferLineCloseLeft<cr>", desc = "Cerrar buffers a la izquierda" },
  { "<leader>bL", "<cmd>BufferLineCloseRight<cr>", desc = "Cerrar buffers a la derecha" },
}
-- Alt+1..9 salta al buffer por su posición (el número que muestra la línea).
for i = 1, 9 do
  keys[#keys + 1] = { "<A-" .. i .. ">", "<cmd>BufferLineGoToBuffer " .. i .. "<cr>", desc = "Buffer " .. i }
end

return {
  "akinsho/bufferline.nvim",
  version = "*",
  event = "VeryLazy",
  dependencies = {
    "nvim-tree/nvim-web-devicons",
    -- Cierra un buffer sin romper la disposición de las ventanas.
    { "famiu/bufdelete.nvim", lazy = true },
  },
  keys = keys,
  -- Solo lo que difiere de los valores por defecto.
  opts = function()
    return {
      -- Colores de catppuccin (debe cargarse después de su setup: VeryLazy lo garantiza).
      highlights = require("catppuccin.special.bufferline").get_theme(),
      options = {
        numbers = "ordinal",
        close_command = function(n) require("bufdelete").bufdelete(n, false) end,
        right_mouse_command = function(n) require("bufdelete").bufdelete(n, false) end,
        indicator = { style = "underline" },
        separator_style = "thin",
        show_close_icon = false,
        max_name_length = 24,
        sort_by = "insert_at_end", -- mantiene estables los números de Alt+1..9
        diagnostics = "nvim_lsp",
        diagnostics_indicator = function(_, _, diagnostics)
          local parts = {}
          for _, item in ipairs({ { "error", "" }, { "warning", "" } }) do
            local count = diagnostics[item[1]] or 0
            if count > 0 then parts[#parts + 1] = item[2] .. " " .. count end
          end
          return table.concat(parts, " ")
        end,
        offsets = {
          { filetype = "neo-tree", text = "Explorador", text_align = "left", separator = false },
        },
        hover = { enabled = true, delay = 200, reveal = { "close" } },
      },
    }
  end,
}
