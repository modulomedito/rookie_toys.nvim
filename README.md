# rookie_toys.nvim

Small, miscellaneous tools for neovim written in lua

## Install

Use lazy.nvim to install this plugin.

```lua
-- Install the lazy.nvim plugin manager
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
    local lazyrepo = "https://github.com/folke/lazy.nvim.git"
    local out = vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "--branch=stable",
        lazyrepo,
        lazypath,
    })
    if vim.v.shell_error ~= 0 then
        error("Error cloning lazy.nvim:\n" .. out)
    end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
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
    'folke/flash.nvim', -- Search and navigation
    'stevearc/conform.nvim', -- Formatter
    'L3MON4D3/LuaSnip', -- Snippet engine
    'nvim-telescope/telescope.nvim', -- Fuzzy finder
    't9md/vim-textmanip', -- Text movement
    -- 'vim-scripts/DrawIt', -- Draw ASCII art
    'tpope/vim-fugitive', -- Git wrapper
    'olimorris/codecompanion.nvim', -- AI coding assistant
    'coder/claudecode.nvim', -- Claude Code integration
    'folke/snacks.nvim', -- Useful Neovim utilities (for Claude Code)
    'nvim-lua/plenary.nvim', -- Lua utility functions
    'nvim-treesitter/nvim-treesitter', -- Better syntax parsing/highlighting
    'MeanderingProgrammer/render-markdown.nvim', -- Render markdown in buffers
    'HakonHarnes/img-clip.nvim', -- Paste images from clipboard
    'MagicDuck/grug-far.nvim', -- Search and replace UI
    'keaising/im-select.nvim', -- Auto switch input method
    'tpope/vim-surround', -- Edit surrounding characters
    'sphamba/smear-cursor.nvim', -- Cursor trail animation
    'stevearc/oil.nvim', -- File explorer
    'NMAC427/guess-indent.nvim', -- Auto indent
    'nvim-tree/nvim-web-devicons', -- Icons
    'folke/which-key.nvim', -- Key bindings popup
    'folke/tokyonight.nvim', -- Colorscheme
    'folke/todo-comments.nvim', -- Highlight todo comments
    'nvim-telescope/telescope-ui-select.nvim', -- Telescope UI select
    'nvim-telescope/telescope-fzf-native.nvim', -- Telescope FZF
    'j-hui/fidget.nvim', -- LSP status updates
    'mason-org/mason.nvim', -- Portable package manager
    'mason-org/mason-lspconfig.nvim', -- Mason LSP config
    'WhoIsSethDaniel/mason-tool-installer.nvim', -- Mason tool installer
    'saghen/blink.cmp', -- Autocompletion
  },
  config = function()
    require("rookie_toys").setup()
  end,
})
```

## In lua/secret.lua

Add your secret configs here.

```lua
vim.g.rookie_toys_ai_adapter = "gemini"
vim.g.rookie_toys_ai_model = "gemini-3-flash-preview"
vim.g.rookie_toys_ai_api_key = "sk-llm-key"
vim.g.rookie_toys_ai_websearch_api = "tvly-search-key"
vim.g.rookie_toys_ai_proxy = "http://127.0.0.1:7890"
vim.g.gitlab_url = 'https://gitlab.com'
vim.g.gitlab_token = 'glpat-11111111111111111111'
```
