-- SQL: sin LSP por ahora; formato con sqlfluff. El dialecto se fija aquí
-- (mysql); cámbialo si trabajas con otro motor.
return {
  { "nvim-treesitter/nvim-treesitter", opts = { ensure_installed = { "sql" } } },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = { sql = { "sqlfluff" } },
      formatters = {
        -- require_cwd = false: el builtin exige .sqlfluff/pyproject.toml en la raíz y se niega en archivos sueltos.
        sqlfluff = { args = { "fix", "--dialect", "mysql", "-" }, require_cwd = false },
      },
    },
  },
}
