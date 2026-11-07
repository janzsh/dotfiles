-- Guías de indentación discretas; solo el bloque actual (scope) se resalta.
return {
  "lukas-reineke/indent-blankline.nvim",
  main = "ibl",
  event = { "BufReadPost", "BufNewFile" },
  ---@module "ibl"
  ---@type ibl.config
  opts = {
    indent = { char = "│" },
    scope = { show_start = false, show_end = false },
    exclude = { filetypes = { "help", "neo-tree", "lazy", "trouble" } },
  },
}
