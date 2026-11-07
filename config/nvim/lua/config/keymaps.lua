local map = vim.keymap.set

map("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "Quitar resaltado de búsqueda" })
map("n", "<leader>w", "<cmd>write<cr>", { desc = "Guardar" })
map("n", "<leader>q", "<cmd>quit<cr>", { desc = "Salir" })

-- Moverse entre splits
map("n", "<C-h>", "<C-w>h")
map("n", "<C-j>", "<C-w>j")
map("n", "<C-k>", "<C-w>k")
map("n", "<C-l>", "<C-w>l")
