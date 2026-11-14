-- Bootstrap de lazy.nvim (el gestor de plugins) y carga de los specs.
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  local out = vim.fn.system({
    "git", "clone", "--filter=blob:none", "--branch=stable",
    "https://github.com/folke/lazy.nvim.git", lazypath,
  })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({ { "No se pudo clonar lazy.nvim:\n" .. out, "ErrorMsg" } }, true, {})
    return
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  -- Cada import carga todos los archivos de esa carpeta. Un archivo = un plugin
  -- (o un grupo mínimo que no funciona separado). Para desactivar uno: `enabled = false`
  -- en su spec, o renombrarlo a algo que no termine en .lua.
  spec = {
    { import = "plugins.ui" },
    { import = "plugins.editor" },
    { import = "plugins.lsp" },
    { import = "plugins.coding" },
    { import = "plugins.lang" },
  },
  -- El lockfile queda en el repo (config/nvim): :Lazy restore si algo se rompe tras un update.
  lockfile = vim.fn.stdpath("config") .. "/lazy-lock.json",
  install = { colorscheme = { "catppuccin-frappe", "habamax" } },
  -- Sin luarocks: en NixOS no compila, y lo único que lo pedía (image.nvim y su
  -- rock `magick`) usa el binario de imagemagick (processor = "magick_cli").
  rocks = { enabled = false },
  checker = { enabled = false },
  change_detection = { notify = false },
})
