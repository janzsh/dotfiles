-- Punto de entrada. Cada cosa vive en su archivo:
--   lua/config/*   opciones, atajos, autocmds y bootstrap de lazy.nvim
--   lua/plugins/*  un archivo por plugin, agrupados por carpeta (ver lua/config/lazy.lua)
-- Los proveedores (node, perl, ruby, python3) se desactivan en nix/home/janz/neovim.nix.

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

require("config.options")
require("config.keymaps")
require("config.autocmds")
require("config.lazy")
