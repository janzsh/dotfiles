-- Nombres de los LSP activos en el buffer (vacío si no hay ninguno).
local function lsp_clients()
  local names = {}
  for _, c in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
    names[#names + 1] = c.name
  end
  return #names > 0 and (" " .. table.concat(names, ",")) or ""
end

return {
  "nvim-lualine/lualine.nvim",
  event = "VeryLazy",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  opts = {
    options = {
      theme = "auto", -- toma los colores de catppuccin
      globalstatus = true,
      component_separators = { left = "", right = "" },
      section_separators = { left = "", right = "" },
      disabled_filetypes = { statusline = { "neo-tree" } },
    },
    -- `sections` va al nivel superior, no dentro de `options`.
    sections = {
      lualine_a = { "mode" },
      lualine_b = { "branch", "diff" },
      lualine_c = { { "filename", path = 1 }, "diagnostics" },
      lualine_x = { lsp_clients, "filetype" },
      lualine_y = { "progress" },
      lualine_z = { "location" },
    },
    extensions = { "neo-tree", "lazy", "trouble" },
  },
}
