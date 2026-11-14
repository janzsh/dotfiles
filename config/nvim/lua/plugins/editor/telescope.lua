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
    { "<leader>fw", function() require("telescope.builtin").grep_string() end, desc = "Buscar palabra actual" },
    { "<leader>fR", function() require("telescope.builtin").resume() end, desc = "Retomar búsqueda" },
    {
      "<leader>fc",
      function()
        require("telescope.builtin").find_files({ cwd = vim.fn.expand("~/dotfiles"), prompt_title = "Dotfiles" })
      end,
      desc = "Buscar en dotfiles",
    },
  },
  opts = {
    defaults = {
      sorting_strategy = "ascending",
      layout_config = {
        width = 0.9,
        height = 0.85,
        horizontal = { prompt_position = "top", preview_cutoff = 100 },
      },
      path_display = { "truncate" },
      dynamic_preview_title = true,
      file_ignore_patterns = { "%.git/" },
      mappings = {
        i = { ["<C-h>"] = "which_key", ["<C-j>"] = "move_selection_next", ["<C-k>"] = "move_selection_previous" },
      },
    },
    pickers = {
      find_files = { hidden = true }, -- incluye .env, .config, etc.; respeta .gitignore
      buffers = { sort_mru = true },
      oldfiles = { cwd_only = true },
    },
  },
  config = function(_, opts)
    local telescope = require("telescope")
    telescope.setup(opts)
    -- El plugin nativo se compila con `make` (gnumake en extraPackages).
    pcall(telescope.load_extension, "fzf")
  end,
}
