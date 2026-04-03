-- Dependencies list that add to lazy.nvim
--   {
--     'modulomedito/rookie_toys.nvim', -- Line break for dependencies
--     dependencies = {
--       'nvim-tree/nvim-tree.lua',
--       'isakbm/gitgraph.nvim',
--       'sindrets/diffview.nvim',
--       'azabiong/vim-highlighter',
--     },
--   },

local M = {}

function M.setup()
    require("rookie_toys.dependencies.nvim-tree").setup()
    require("rookie_toys.dependencies.telescope").setup()
    require("rookie_toys.dependencies.gitgraph").setup()
    require("rookie_toys.dependencies.conform").setup()
end

return M
