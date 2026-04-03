-- Dependencies list that add to lazy.nvim
-- dependencies = {
--     "nvim-tree/nvim-tree.lua",
-- }

local M = {}

function M.setup()
    require("rookie_toys.dependencies.nvim-tree").setup()
end

return M
