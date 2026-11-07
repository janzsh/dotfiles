return {
  "saghen/blink.cmp",
  version = "1.*",
  event = { "InsertEnter", "CmdlineEnter" },
  ---@module 'blink.cmp'
  ---@type blink.cmp.Config
  opts = {
    keymap = { preset = "enter" },
    appearance = { nerd_font_variant = "mono" },
    completion = {
      list = { selection = { preselect = true, auto_insert = true } },
      accept = { auto_brackets = { enabled = true } },
      documentation = { auto_show = true, auto_show_delay_ms = 300 },
      ghost_text = { enabled = true },
    },
    sources = { default = { "lsp", "path", "snippets", "buffer" } },
    signature = { enabled = true },
    -- "lua" evita depender del binario precompilado de Rust, que en NixOS
    -- suele fallar al cargarse. Si algún día se empaqueta, cambiar a "prefer_rust".
    fuzzy = { implementation = "lua" },
  },
  opts_extend = { "sources.default" },
}
