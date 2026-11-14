return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  cmd = "Neotree",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
    "MunifTanjim/nui.nvim",
    -- Al abrir un archivo con varios splits, pregunta en cuál (letra sobre cada ventana).
    {
      "s1n7ax/nvim-window-picker",
      version = "2.*",
      opts = {
        filter_rules = {
          include_current_win = false,
          autoselect_one = true,
          bo = {
            filetype = { "neo-tree", "neo-tree-popup", "notify", "noice" },
            buftype = { "terminal", "quickfix" },
          },
        },
      },
    },
    -- Previsualizar imágenes con `P` (protocolo gráfico de kitty). magick_cli usa
    -- el binario de imagemagick (nix/home/janz/neovim.nix) en vez de la luarock.
    {
      "3rd/image.nvim",
      opts = {
        backend = "kitty",
        processor = "magick_cli",
        integrations = { markdown = { enabled = false } },
        max_width = 100,
        max_height = 12,
      },
    },
  },
  keys = {
    { "<C-m>", "<cmd>Neotree toggle<cr>", desc = "Explorador" },
    { "<C-S-m>", "<cmd>Neotree focus<cr>", desc = "Enfocar explorador" },
    { "<leader>e", "<cmd>Neotree toggle<cr>", desc = "Explorador" },
    { "<leader>E", "<cmd>Neotree reveal<cr>", desc = "Explorador (archivo actual)" },
  },
  -- Lazy-load, pero `nvim .` / `nvim carpeta` debe abrir el explorador: neo-tree
  -- necesita estar cargado para secuestrar netrw, así que lo cargamos solo si el
  -- primer argumento es un directorio.
  init = function()
    vim.api.nvim_create_autocmd("BufEnter", {
      group = vim.api.nvim_create_augroup("janz_neotree_dir", { clear = true }),
      once = true,
      callback = function()
        local stat = vim.uv.fs_stat(vim.fn.argv(0) --[[@as string]])
        if stat and stat.type == "directory" then
          require("neo-tree")
        end
      end,
    })
  end,
  ---@module "neo-tree"
  ---@type neotree.Config
  opts = {
    close_if_last_window = true,
    popup_border_style = "rounded",
    open_files_do_not_replace_types = { "terminal", "trouble", "qf" },
    default_component_configs = {
      indent = { indent_size = 2 },
      git_status = {
        symbols = {
          added = " ", deleted = "󰩹 ", modified = " ", renamed = "󱇧 ",
          untracked = " ", ignored = "󰈉 ", unstaged = "󱧙 ", staged = "󱧘 ", conflict = " ",
        },
      },
    },
    window = {
      width = 36,
      mappings = {
        ["P"] = { "toggle_preview", config = { use_float = false, use_image_nvim = true } },
      },
    },
    filesystem = {
      follow_current_file = { enabled = true },
      use_libuv_file_watcher = true,
      filtered_items = {
        hide_gitignored = true,
        hide_by_name = { "node_modules", "__pycache__", ".git" },
      },
    },
  },
}
