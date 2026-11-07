return {
  "lewis6991/gitsigns.nvim",
  event = { "BufReadPost", "BufNewFile" },
  opts = {
    -- Sin `linehl`: resaltar líneas enteras es demasiado ruidoso; con los signos
    -- y el número de línea (numhl) basta.
    numhl = true,
    signs = {
      add = { text = "▎" },
      change = { text = "▎" },
      delete = { text = "" },
      topdelete = { text = "" },
      changedelete = { text = "▎" },
    },
    -- Los atajos son locales al buffer: solo existen dentro de un repo git.
    on_attach = function(bufnr)
      local gs = require("gitsigns")
      local function map(lhs, rhs, desc, mode)
        vim.keymap.set(mode or "n", lhs, rhs, { buffer = bufnr, desc = desc })
      end

      map("]h", function()
        if vim.wo.diff then vim.cmd.normal({ "]c", bang = true }) else gs.nav_hunk("next") end
      end, "Siguiente hunk")
      map("[h", function()
        if vim.wo.diff then vim.cmd.normal({ "[c", bang = true }) else gs.nav_hunk("prev") end
      end, "Hunk anterior")

      map("<leader>hs", gs.stage_hunk, "Stage hunk")
      map("<leader>hr", gs.reset_hunk, "Revertir hunk")
      map("<leader>hs", function() gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, "Stage selección", "v")
      map("<leader>hr", function() gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, "Revertir selección", "v")
      map("<leader>hS", gs.stage_buffer, "Stage buffer")
      map("<leader>hp", gs.preview_hunk, "Previsualizar hunk")
      map("<leader>hb", function() gs.blame_line({ full = true }) end, "Blame de la línea")
      map("<leader>hd", gs.diffthis, "Diff contra el índice")
      map("<leader>tb", gs.toggle_current_line_blame, "Blame en línea")
    end,
  },
}
