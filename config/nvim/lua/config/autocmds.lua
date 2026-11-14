local group = vim.api.nvim_create_augroup("janz", { clear = true })

vim.api.nvim_create_autocmd("TextYankPost", {
  group = group,
  desc = "Resaltar lo copiado",
  callback = function() vim.hl.on_yank() end,
})

vim.api.nvim_create_user_command("OpenDotfilesConfig", function()
  local root = vim.fn.expand("~/dotfiles")
  vim.fn.chdir(root)
  require("telescope.builtin").find_files({ cwd = root, hidden = true })
end, { desc = "Abrir los dotfiles (cambia el cwd)" })
