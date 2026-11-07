-- Muestra los atajos disponibles al pulsar un prefijo. Aquí solo viven los
-- NOMBRES de los grupos de <leader>; los atajos en sí los define cada plugin
-- en su `keys`, así que aparecen aquí sin registrarlos dos veces.
return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts = {
    preset = "modern",
    delay = 300,
    spec = {
      { "<leader>b", group = "buffers" },
      { "<leader>c", group = "código" },
      { "<leader>f", group = "buscar" },
      { "<leader>h", group = "git (hunks)" },
      { "<leader>t", group = "alternar" },
      { "<leader>x", group = "diagnósticos" },
    },
  },
  keys = {
    {
      "<leader>?",
      function() require("which-key").show({ global = false }) end,
      desc = "Atajos del buffer",
    },
  },
}
