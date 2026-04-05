-- Dependencies list that add to lazy.nvim
--   {
--     'modulomedito/rookie_toys.nvim', -- Line break for dependencies
--     dependencies = {
--       'azabiong/vim-highlighter', -- Highlight words/patterns
--       'fedorenchik/VimCalc3', -- Vim calculator
--       'isakbm/gitgraph.nvim', -- Git graph visualization
--       'NeogitOrg/neogit', -- Git wrapper
--       'neovim/nvim-lspconfig', -- Quickstart configs for Nvim LSP
--       'nvim-tree/nvim-tree.lua', -- File explorer
--       'sindrets/diffview.nvim', -- Git diff view
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
