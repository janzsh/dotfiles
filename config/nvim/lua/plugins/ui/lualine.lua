-- Nombres de los LSP activos en el buffer (vacío si no hay ninguno).
local function lsp_clients()
  local names, seen = {}, {}
  for _, c in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
    if not seen[c.name] then
      names[#names + 1] = c.name
      seen[c.name] = true
    end
  end
  table.sort(names)
  return table.concat(names, ", ")
end

-- La barra es global: importa el ancho del editor, no el del split activo.
local function wide_enough(columns)
  return function() return vim.o.columns >= columns end
end

local function git_diff()
  local status = vim.b.gitsigns_status_dict
  if status then
    return { added = status.added, modified = status.changed, removed = status.removed }
  end
end

return {
  "nvim-lualine/lualine.nvim",
  event = "VeryLazy",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  opts = {
    options = {
      theme = "auto", -- toma los colores de catppuccin
      globalstatus = true,
      component_separators = { left = "", right = "" },
      section_separators = { left = "", right = "" },
    },
    -- `sections` va al nivel superior, no dentro de `options`.
    sections = {
      lualine_a = {
        { "mode", fmt = function(mode) return vim.o.columns < 80 and mode:sub(1, 1) or mode end },
      },
      lualine_b = {
        { "branch", cond = wide_enough(80) },
        -- Reutiliza los datos de gitsigns; no lanza otro proceso Git.
        { "diff", source = git_diff, cond = wide_enough(100) },
      },
      lualine_c = {
        {
          "filename", path = 1,
          shorting_target = function() return math.floor(vim.o.columns * 0.6) end,
          symbols = { modified = "●", readonly = "", unnamed = "[Sin nombre]" },
        },
        {
          "diagnostics", sources = { "nvim_diagnostic" },
          symbols = { error = " ", warn = " ", info = " ", hint = "󰞏 " },
        },
      },
      lualine_x = {
        "selectioncount",
        { lsp_clients, icon = "", cond = wide_enough(120) },
        { "filetype", cond = wide_enough(80) },
      },
      lualine_y = { { "progress", cond = wide_enough(80) } },
      lualine_z = { "location" },
    },
    extensions = { "neo-tree", "lazy", "trouble", "quickfix" },
  },
}
