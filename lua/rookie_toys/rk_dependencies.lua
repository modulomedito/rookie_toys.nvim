-- Dependencies list that add to lazy.nvim
--   {
--     'modulomedito/rookie_toys.nvim', -- Line break for dependencies
--     dependencies = {
--       'NeogitOrg/neogit', -- Git wrapper
--       'azabiong/vim-highlighter', -- Highlight words/patterns
--       'fedorenchik/VimCalc3', -- Vim calculator
--       'folke/flash.nvim', -- Visual cursor jump
--       'godlygeek/tabular', -- Markdown code syntax highlight
--       'hotoo/pangu.vim', -- Pangu spacing
--       'isakbm/gitgraph.nvim', -- Git graph visualization
--       'kshenoy/vim-signature', -- Bookmarks
--       'neovim/nvim-lspconfig', -- Quickstart configs for Nvim LSP
--       'nvim-mini/mini.nvim', -- Collection of various small independent plugins
--       'nvim-tree/nvim-tree.lua', -- File explorer
--       'sindrets/diffview.nvim', -- Git diff view
--       't9md/vim-textmanip', -- Text movement
--       'vim-scripts/DrawIt', -- Draw ASCII art
--       'tpope/vim-fugitive', -- Git wrapper
--     },
--   },
local M = {}

function M.setup()
    require("rookie_toys.dependencies.nvim-tree").setup()
    require("rookie_toys.dependencies.telescope").setup()
    require("rookie_toys.dependencies.gitgraph").setup()
    require("rookie_toys.dependencies.conform").setup()
    require("rookie_toys.dependencies.mini").setup()
    require("rookie_toys.dependencies.flash").setup()
    require("rookie_toys.dependencies.luasnip").setup()
end

return M
