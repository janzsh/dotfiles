-- Pinta los códigos de color (#rrggbb, rgb(), ...) con su color: útil para
-- editar temas de Quickshell, kitty y Hyprland.
return {
  "NvChad/nvim-colorizer.lua",
  event = { "BufReadPost", "BufNewFile" },
  opts = {
    user_default_options = {
      names = false, -- sin esto pinta palabras como "red" o "blue" en cualquier texto
      mode = "background",
    },
  },
}
