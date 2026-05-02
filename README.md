# rookie_toys.nvim

Small, miscellaneous tools for neovim written in lua

## Install

Use lazy.nvim to install this plugin.

```lua
{
  'modulomedito/rookie_toys.nvim', -- Line break for dependencies
  dependencies = {
    'NeogitOrg/neogit', -- Git wrapper
    'azabiong/vim-highlighter', -- Highlight words/patterns
    'fedorenchik/VimCalc3', -- Vim calculator
    'godlygeek/tabular', -- Markdown code syntax highlight
    'hotoo/pangu.vim', -- Pangu spacing
    'isakbm/gitgraph.nvim', -- Git graph visualization
    'lewis6991/gitsigns.nvim', -- Git gutter-like features
    'kshenoy/vim-signature', -- Bookmarks
    'neovim/nvim-lspconfig', -- Quickstart configs for Nvim LSP
    'nvim-mini/mini.nvim', -- Collection of various small
    'nvim-tree/nvim-tree.lua', -- File explorer
    'sindrets/diffview.nvim', -- Git diff view
    't9md/vim-textmanip', -- Text movement
    -- 'vim-scripts/DrawIt', -- Draw ASCII art
    'tpope/vim-fugitive', -- Git wrapper
    'olimorris/codecompanion.nvim', -- AI coding assistant
    'nvim-lua/plenary.nvim', -- Lua utility functions
    'nvim-treesitter/nvim-treesitter', -- Better syntax parsing/highlighting
    'MeanderingProgrammer/render-markdown.nvim', -- Render markdown in buffers
    'HakonHarnes/img-clip.nvim', -- Paste images from clipboard
    'MagicDuck/grug-far.nvim', -- Search and replace UI
    'keaising/im-select.nvim', -- Auto switch input method
    'tpope/vim-surround', -- Edit surrounding characters
    'sphamba/smear-cursor.nvim', -- Cursor trail animation
    'stevearc/oil.nvim', -- File explorer
  },
  config = function()
    vim.g.rookie_toys_ai_model = "gemma2:9b"
    vim.g.rookie_toys_ai_adapter = "gemini"
    vim.g.rookie_toys_ai_model = "gemini-3-pro"
    vim.g.rookie_toys_ai_api_key = "sk-1234567890abcdef1234567890abcdef"
    vim.g.gitlab_url = 'https:///gitlab.com'
    vim.g.gitlab_token = 'glpat-11111111111111111111'
    require("rookie_toys").setup()
    -- Other configs
  end,
},
```
