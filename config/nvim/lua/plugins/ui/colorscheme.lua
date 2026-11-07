return {
  "catppuccin/nvim",
  name = "catppuccin",
  lazy = false,
  priority = 1000, -- cargar antes que el resto de plugins de UI
  opts = {
    flavour = "frappe",
    transparent_background = false,
    -- Una línea por plugin que tenga integración (ver :h catppuccin)
    integrations = {
      native_lsp = { enabled = true },
      treesitter = true,
      telescope = { enabled = true },
      blink_cmp = true,
      which_key = true,
    },
  },
  config = function(_, opts)
    require("catppuccin").setup(opts)
    vim.cmd.colorscheme("catppuccin-frappe")
  end,
}
