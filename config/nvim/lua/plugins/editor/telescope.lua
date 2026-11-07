return {
  "nvim-telescope/telescope.nvim",
  branch = "master",
  cmd = "Telescope",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
    { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
  },
  keys = {
    { "<leader>ff", function() require("telescope.builtin").find_files() end, desc = "Buscar archivos" },
    { "<leader>fg", function() require("telescope.builtin").live_grep() end, desc = "Buscar texto (grep)" },
    { "<leader>fb", function() require("telescope.builtin").buffers() end, desc = "Buffers" },
    { "<leader>fr", function() require("telescope.builtin").oldfiles() end, desc = "Archivos recientes" },
    { "<leader>fh", function() require("telescope.builtin").help_tags() end, desc = "Ayuda" },
    { "<leader>fd", function() require("telescope.builtin").diagnostics() end, desc = "Diagnósticos" },
  },
  config = function()
    local telescope = require("telescope")
    telescope.setup({
      defaults = {
        mappings = { i = { ["<C-h>"] = "which_key" } },
      },
    })
    -- El plugin nativo se compila con `make` (gnumake en extraPackages).
    pcall(telescope.load_extension, "fzf")
  end,
}
