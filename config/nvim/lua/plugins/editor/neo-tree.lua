return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  cmd = "Neotree",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
    "MunifTanjim/nui.nvim",
  },
  keys = {
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
          added = " ", deleted = "󰩹 ", modified = " ", renamed = "󱇧 ",
          untracked = " ", ignored = "󰈉 ", unstaged = "󱧙 ", staged = "󱧘 ", conflict = " ",
        },
      },
    },
    window = {
      width = 36,
      mappings = {
        ["P"] = { "toggle_preview", config = { use_float = false } },
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
