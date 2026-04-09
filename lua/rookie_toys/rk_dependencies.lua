local M = {}

function M.setup()
    require("rookie_toys.dependencies.nvim-tree").setup()
    require("rookie_toys.dependencies.telescope").setup()
    require("rookie_toys.dependencies.gitgraph").setup()
    require("rookie_toys.dependencies.conform").setup()
    require("rookie_toys.dependencies.mini").setup()
    require("rookie_toys.dependencies.flash").setup()
    require("rookie_toys.dependencies.luasnip").setup()
    require("rookie_toys.dependencies.gitsigns").setup()
    require("rookie_toys.dependencies.codecompanion").setup()
end

return M
