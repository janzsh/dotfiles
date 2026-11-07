local group = vim.api.nvim_create_augroup("janz", { clear = true })

vim.api.nvim_create_autocmd("TextYankPost", {
  group = group,
  desc = "Resaltar lo copiado",
  callback = function() vim.hl.on_yank() end,
})
