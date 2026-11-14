-- Cierra (), [], {}, comillas... al escribir. check_ts: no lo hace dentro de strings/comentarios.
return {
  "windwp/nvim-autopairs",
  event = "InsertEnter",
  opts = {
    check_ts = true,
    disable_filetype = { "TelescopePrompt", "neo-tree" },
  },
}
