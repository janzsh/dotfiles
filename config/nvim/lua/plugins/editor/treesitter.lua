-- Rama `main` (reescritura): ya no hay `configs.setup{ highlight = ... }`.
-- Los parsers se instalan con install() y el resaltado se activa por FileType.
-- Cada archivo de lua/plugins/lang/ añade sus parsers a `ensure_installed`
-- (`opts_extend` indica a lazy que concatene esa lista entre specs).
return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  lazy = false,
  build = ":TSUpdate",
  opts_extend = { "ensure_installed" },
  opts = { ensure_installed = {} },
  config = function(_, opts)
    local ts = require("nvim-treesitter")
    ts.setup({})
    if #opts.ensure_installed > 0 then
      ts.install(opts.ensure_installed)
    end

    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("janz_treesitter", { clear = true }),
      callback = function(ev)
        -- pcall: filetypes sin parser simplemente se quedan sin treesitter.
        if pcall(vim.treesitter.start, ev.buf) then
          vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
      end,
    })
  end,
}
