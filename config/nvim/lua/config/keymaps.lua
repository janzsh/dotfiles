local map = vim.keymap.set

map("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "Quitar resaltado de búsqueda" })
map({ "n", "i", "x" }, "<C-s>", "<cmd>write<cr><esc>", { desc = "Guardar" })
map("n", "<C-S-a>", "<cmd>wall<cr>", { desc = "Guardar todos" })
map("n", "<leader>w", "<cmd>write<cr>", { desc = "Guardar" })
map("n", "<leader>q", "<cmd>quit<cr>", { desc = "Salir" })

-- Moverse entre splits (smart-splits los sustituye al cargar; esto es el respaldo)
map("n", "<C-h>", "<C-w>h")
map("n", "<C-j>", "<C-w>j")
map("n", "<C-k>", "<C-w>k")
map("n", "<C-l>", "<C-w>l")
