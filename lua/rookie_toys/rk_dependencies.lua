-- Dependencies list that add to lazy.nvim
--   {
--     'modulomedito/rookie_toys.nvim', -- Line break for dependencies
--     dependencies = {
--       'neovim/nvim-lspconfig', -- Quickstart configs for Nvim LSP
--       'nvim-tree/nvim-tree.lua', -- File explorer
--       'isakbm/gitgraph.nvim', -- Git graph visualization
--       'sindrets/diffview.nvim', -- Git diff view
--       'azabiong/vim-highlighter', -- Highlight words/patterns
--       'NeogitOrg/neogit', -- Git wrapper
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
