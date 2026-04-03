-- Dependencies list that add to lazy.nvim
--   {
--     'modulomedito/rookie_toys.nvim', -- Line break for dependencies
--     dependencies = {
--       'nvim-tree/nvim-tree.lua',
--       'isakbm/gitgraph.nvim',
--       'sindrets/diffview.nvim',
--     },
--   },

local M = {}

function M.setup()
    require("rookie_toys.dependencies.nvim-tree").setup()
    require("rookie_toys.dependencies.telescope").setup()
end

return M
