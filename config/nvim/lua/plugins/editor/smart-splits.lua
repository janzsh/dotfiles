-- Moverse y redimensionar splits con las mismas teclas. Si algún día se usa
-- tmux/kitty como multiplexor, el plugin cruza también sus paneles.
return {
  "mrjones2014/smart-splits.nvim",
  event = "VeryLazy",
  opts = {
    ignored_buftypes = { "nofile", "quickfix", "prompt" },
    ignored_filetypes = { "neo-tree" },
    resize = { amount = 2 },
  },
  keys = {
    { "<C-h>", function() require("smart-splits").move_cursor_left() end, desc = "Ventana izquierda" },
    { "<C-j>", function() require("smart-splits").move_cursor_down() end, desc = "Ventana abajo" },
    { "<C-k>", function() require("smart-splits").move_cursor_up() end, desc = "Ventana arriba" },
    { "<C-l>", function() require("smart-splits").move_cursor_right() end, desc = "Ventana derecha" },
    { "<C-\\>", function() require("smart-splits").move_cursor_previous() end, desc = "Ventana anterior" },
    { "<A-h>", function() require("smart-splits").resize_left() end, desc = "Reducir ancho" },
    { "<A-j>", function() require("smart-splits").resize_down() end, desc = "Aumentar alto" },
    { "<A-k>", function() require("smart-splits").resize_up() end, desc = "Reducir alto" },
    { "<A-l>", function() require("smart-splits").resize_right() end, desc = "Aumentar ancho" },
  },
}
