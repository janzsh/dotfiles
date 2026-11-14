-- Cierra y renombra a la vez las etiquetas HTML/JSX/XML.
return {
  "windwp/nvim-ts-autotag",
  ft = { "html", "xml", "javascriptreact", "typescriptreact", "vue", "svelte", "astro", "markdown" },
  opts = {
    opts = { enable_close = true, enable_rename = true, enable_close_on_slash = true },
  },
}
