-- Depurador. La UI se abre y cierra sola con la sesión. Los adaptadores de cada
-- lenguaje viven en lua/plugins/lang/ (delve para Go, debugpy para Python).
return {
  "mfussenegger/nvim-dap",
  dependencies = {
    { "rcarriga/nvim-dap-ui", dependencies = { "nvim-neotest/nvim-nio" }, opts = {} },
    { "theHamsta/nvim-dap-virtual-text", opts = {} },
  },
  keys = {
    { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "Breakpoint" },
    { "<leader>ds", function() require("dap").new() end, desc = "Nueva sesión" },
    { "<leader>dc", function() require("dap").continue() end, desc = "Continuar" },
    { "<leader>do", function() require("dap").step_over() end, desc = "Step over" },
    { "<leader>di", function() require("dap").step_into() end, desc = "Step into" },
    { "<leader>dO", function() require("dap").step_out() end, desc = "Step out" },
    { "<leader>dt", function() require("dap").terminate() end, desc = "Terminar" },
    { "<leader>du", function() require("dapui").toggle() end, desc = "Alternar UI" },
  },
  config = function()
    local dap, dapui = require("dap"), require("dapui")
    dap.listeners.before.attach.dapui_config = dapui.open
    dap.listeners.before.launch.dapui_config = dapui.open
    dap.listeners.before.event_terminated.dapui_config = dapui.close
    dap.listeners.before.event_exited.dapui_config = dapui.close
  end,
}
