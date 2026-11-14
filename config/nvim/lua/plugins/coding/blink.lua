return {
  "saghen/blink.cmp",
  version = "1.*",
  event = { "InsertEnter", "CmdlineEnter" },
  -- Colorea la etiqueta del menú como el código real (tipos, firmas...).
  dependencies = { "xzbdmw/colorful-menu.nvim" },
  ---@module 'blink.cmp'
  ---@type blink.cmp.Config
  opts = {
    keymap = { preset = "enter" },
    appearance = { nerd_font_variant = "mono" },
    completion = {
      list = { selection = { preselect = true, auto_insert = true } },
      accept = { auto_brackets = { enabled = true } },
      documentation = { auto_show = true, auto_show_delay_ms = 300 },
      menu = {
        draw = {
          columns = { { "kind_icon" }, { "label", gap = 1 } },
          components = {
            label = {
              text = function(ctx) return require("colorful-menu").blink_components_text(ctx) end,
              highlight = function(ctx) return require("colorful-menu").blink_components_highlight(ctx) end,
            },
          },
        },
      },
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
