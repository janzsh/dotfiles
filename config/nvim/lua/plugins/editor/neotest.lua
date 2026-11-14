-- Ejecutar tests desde el editor. Cada archivo de lua/plugins/lang/ añade su
-- adaptador a `opts.adapters` (nombre del módulo = config).
return {
  "nvim-neotest/neotest",
  dependencies = {
    "nvim-neotest/nvim-nio",
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
  },
  keys = {
    { "<leader>Tt", function() require("neotest").run.run() end, desc = "Test más cercano" },
    { "<leader>Tf", function() require("neotest").run.run(vim.fn.expand("%")) end, desc = "Tests del archivo" },
    { "<leader>Td", function() require("neotest").run.run({ strategy = "dap" }) end, desc = "Depurar test" },
    { "<leader>Ts", function() require("neotest").summary.toggle() end, desc = "Resumen" },
    { "<leader>To", function() require("neotest").output.open({ enter = true }) end, desc = "Salida" },
  },
  opts = { adapters = {} },
  config = function(_, opts)
    local adapters = {}
    for name, cfg in pairs(opts.adapters) do
      if cfg ~= false then adapters[#adapters + 1] = require(name)(cfg) end
    end
    require("neotest").setup(vim.tbl_extend("force", opts, { adapters = adapters }))
  end,
}
