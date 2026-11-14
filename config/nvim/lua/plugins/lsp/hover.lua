-- Sustituye a `K`: ventana de documentación con varias fuentes (LSP, diagnósticos...)
-- entre las que se cambia con <C-p>/<C-n>, y también al pasar el ratón.
return {
  "lewis6991/hover.nvim",
  keys = {
    { "K", function() require("hover").open() end, desc = "Documentación (hover)" },
    { "<C-p>", function() require("hover").switch("previous") end, desc = "Hover: fuente anterior" },
    { "<C-n>", function() require("hover").switch("next") end, desc = "Hover: fuente siguiente" },
    { "<MouseMove>", function() require("hover").mouse() end, desc = "Hover con el ratón" },
  },
  -- Su API es `config()`, no `setup()`: por eso no sirve `opts`.
  config = function()
    require("hover").config({
      preview_opts = { border = "rounded" },
      mouse_delay = 1000,
    })
  end,
}
