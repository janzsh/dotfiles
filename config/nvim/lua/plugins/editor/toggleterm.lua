-- Terminal que se abre y oculta con Ctrl+ñ (también desde dentro de ella).
return {
  "akinsho/toggleterm.nvim",
  version = "*",
  cmd = { "ToggleTerm", "TermExec" },
  keys = { { "<C-ñ>", desc = "Terminal" } },
  opts = {
    size = 15,
    open_mapping = [[<C-ñ>]],
    direction = "horizontal",
    persist_mode = true,
    auto_scroll = true,
  },
}
