local M = {}

function M.setup()
    require("rookie_toys.dependencies.nvim-tree").setup()
    require("rookie_toys.dependencies.telescope").setup()
    require("rookie_toys.dependencies.grugfar").setup()
    require("rookie_toys.dependencies.gitgraph").setup()
    require("rookie_toys.dependencies.conform").setup()
    require("rookie_toys.dependencies.mini").setup()
    require("rookie_toys.dependencies.flash").setup()
    require("rookie_toys.dependencies.luasnip").setup()
    require("rookie_toys.dependencies.gitsigns").setup()
    require("rookie_toys.dependencies.codecompanion").setup()
    require("rookie_toys.dependencies.imselect").setup()
    require("rookie_toys.dependencies.smear-cursor").setup()
    require("rookie_toys.dependencies.oil").setup()
    require("rookie_toys.dependencies.diffview").setup()
    require("rookie_toys.dependencies.claudecode").setup()

    -- New kickstart dependencies
    require("rookie_toys.dependencies.guessindent").setup()
    require("rookie_toys.dependencies.whichkey").setup()
    require("rookie_toys.dependencies.tokyonight").setup()
    require("rookie_toys.dependencies.todocomments").setup()
    require("rookie_toys.dependencies.fidget").setup()
    require("rookie_toys.dependencies.lspconfig").setup()
    require("rookie_toys.dependencies.blinkcmp").setup()
    require("rookie_toys.dependencies.treesitter").setup()
end

return M
