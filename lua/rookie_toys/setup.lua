local function setup_misc()
    vim.cmd("colorscheme habamax")
    vim.cmd("language messages en_US")
end

local function setup_keymap()
    local nopt = { noremap = true }
    local nsopt = { noremap = true, silent = true }

    vim.g.mapleader = " "

    vim.keymap.set("n", "<leader>lh", ":noh<CR>", nsopt)
    vim.keymap.set('c', '<C-v>', '<C-r>*', nopt)
    vim.keymap.set('n', '*', '*Nzz', nsopt)
    vim.keymap.set('n', '<C-d>', '<C-d>zz', nsopt)
    vim.keymap.set('n', '<C-f>', '<C-u>zz', nsopt)
    vim.keymap.set('n', '<C-p>', ':find *', nopt)
    vim.keymap.set('n', '<C-q>', ':q<CR>', nsopt)
    vim.keymap.set('n', '<C-s>', ":%s/\\s\\+$//e<bar>w<CR>", nsopt)
    vim.keymap.set('n', '<F2>', ":%s/\\C\\<<C-r><C-w>\\>/<C-r><C-w>/g<Left><Left>", nopt)
    vim.keymap.set('n', '<M-j>', ':m .+1<CR>==', nsopt)
    vim.keymap.set('n', '<M-k>', ':m .-2<CR>==', nsopt)
    vim.keymap.set('n', '<leader>p', '"0p', nsopt)
    vim.keymap.set('n', '<leader>vim', ":vs $MYVIMRC<CR>", nsopt)
    vim.keymap.set('n', 'H', 'g^', nsopt)
    vim.keymap.set('n', 'K', 'i<CR><Esc>', nsopt)
    vim.keymap.set('n', 'L', 'g_', nsopt)
    vim.keymap.set('n', 'O', 'O <BS><Esc>', nsopt)
    vim.keymap.set('n', 'gd', '<C-]>', nsopt)
    vim.keymap.set('n', 'go', '"0yi):silent !start <C-r>0<CR>', nsopt)
    vim.keymap.set('n', 'j', 'gj', nsopt)
    vim.keymap.set('n', 'k', 'gk', nsopt)
    vim.keymap.set('n', 'o', 'o <BS><Esc>', nsopt)
    vim.keymap.set('o', 'H', 'g^', nsopt)
    vim.keymap.set('o', 'L', 'g_', nsopt)
    vim.keymap.set('v', '/', '"-y/<C-r>-<CR>N', nsopt)
    vim.keymap.set('v', '<C-d>', '<C-d>zz', nsopt)
    vim.keymap.set('v', '<C-f>', '<C-u>zz', nsopt)
    vim.keymap.set('v', '<F2>', '"-y:%s/<C-r>-\\C/<C-r>-/g<Left><Left>', nopt)
    vim.keymap.set('v', '<M-j>', ":m '>+1<CR>gv=gv", nsopt)
    vim.keymap.set('v', '<M-k>', ":m '<-2<CR>gv=gv", nsopt)
    vim.keymap.set('v', '<leader>p', '"0p', nsopt)
    vim.keymap.set('v', '<leader>ss', ":sort<CR>", nsopt)
    vim.keymap.set('v', 'H', 'g^', nsopt)
    vim.keymap.set('v', 'L', 'g_', nsopt)
    vim.keymap.set('v', 'y', 'ygv<Esc>', nsopt)

    -- Plugin related keymap
    vim.keymap.set('n', '<C-y>', ':NvimTreeToggle<CR>', nsopt)
    vim.keymap.set('n', '<F10>', ':copen <bar> AsyncRun cargo ', nopt)
    vim.keymap.set('n', '<leader>gf', ':lua require("rookie_toys.search").live_grep()<CR>', nsopt)
    vim.keymap.set('n', '<leader>gg', ':lua require("rookie_toys.search").grep_word_under_cursor()<CR>', nsopt)
    vim.keymap.set("n", "<M-d>", "<Plug>(textmanip-duplicate-down)", nsopt)
    vim.keymap.set("x", "<M-d>", "<Plug>(textmanip-duplicate-down)", nsopt)
    vim.keymap.set("n", "<M-D>", "<Plug>(textmanip-duplicate-up)", nsopt)
    vim.keymap.set("x", "<M-D>", "<Plug>(textmanip-duplicate-up)", nsopt)
    vim.keymap.set("x", "<C-j>", "<Plug>(textmanip-move-down)", nsopt)
    vim.keymap.set("x", "<C-k>", "<Plug>(textmanip-move-up)", nsopt)
    vim.keymap.set("x", "<C-h>", "<Plug>(textmanip-move-left)", nsopt)
    vim.keymap.set("x", "<C-l>", "<Plug>(textmanip-move-right)", nsopt)
    vim.keymap.set("n", "<F6>", "<Plug>(textmanip-toggle-mode)", nsopt)
    vim.keymap.set("x", "<F6>", "<Plug>(textmanip-toggle-mode)", nsopt)
    vim.keymap.set("x", "<Up>", "<Plug>(textmanip-move-up-r)", nsopt)
    vim.keymap.set("x", "<Down>", "<Plug>(textmanip-move-down-r)", nsopt)
    vim.keymap.set("x", "<Left>", "<Plug>(textmanip-move-left-r)", nsopt)
    vim.keymap.set("x", "<Right>", "<Plug>(textmanip-move-right-r)", nsopt)
    vim.keymap.set("n", "<leader>thl", ":TSBufToggle highlight<CR>", nsopt)

    -- Plugin related command
    vim.api.nvim_create_user_command("GD", function(_)
        require("rookie_toys.git").diff()
    end, {})
    vim.api.nvim_create_user_command("GG", function(_)
        local filetype = vim.bo.filetype
        if filetype == "git" then
            vim.cmd("quit")
        end
        require("rookie_toys.git").open_git_graph_all()
    end, {})
    vim.api.nvim_create_user_command("GGL", function(_)
        local filetype = vim.bo.filetype
        if filetype == "git" then
            vim.cmd("quit")
        end
        require("rookie_toys.git").open_git_graph_local()
    end, {})
    vim.api.nvim_create_user_command("CC", function(_)
        require("rookie_toys.c").generate_compile_commands_json()
    end, {})
    vim.api.nvim_create_user_command("CA", function(_)
        require("rookie_toys.c").add_ccj_define_symbol()
    end, {})
    vim.api.nvim_create_user_command("CX", function(_)
        require("rookie_toys.c").remove_ccj_define_symbol()
    end, {})
    vim.api.nvim_create_user_command("Retab", function()
        vim.cmd("set ts=4")
        vim.cmd("set noet")
        vim.cmd("%retab!")
        vim.cmd("set et")
    end, {})
end

local function setup_option()
    vim.opt.autoindent     = true
    vim.opt.autoread       = true
    vim.opt.background     = "dark"
    vim.opt.belloff        = "all"
    vim.opt.breakindent    = true
    vim.opt.clipboard      = "unnamed"
    vim.opt.colorcolumn    = "81,101"
    vim.opt.complete       = ".,w,b,u,t"
    vim.opt.completeopt    = { "menuone", "noselect", "popup" }
    vim.opt.cursorcolumn   = true
    vim.opt.cursorline     = true
    vim.opt.expandtab      = true
    vim.opt.foldenable     = false
    vim.opt.grepformat     = "%f:%l:%c:%m,%f:%l:%m"
    vim.opt.hlsearch       = true
    vim.opt.ignorecase     = true
    vim.opt.infercase      = true
    vim.opt.iskeyword      = "@,48-57,_,192-255,-,#"
    vim.opt.laststatus     = 2
    vim.opt.list           = true
    vim.opt.listchars      = { tab = "-->", trail = "~", nbsp = "␣" }
    vim.opt.number         = true
    vim.opt.pumheight      = 50
    vim.opt.relativenumber = true
    vim.opt.shiftwidth     = 4
    vim.opt.shortmess      = "flnxtocTOCI"
    vim.opt.signcolumn     = "yes"
    vim.opt.smartcase      = true
    vim.opt.smarttab       = true
    vim.opt.softtabstop    = 4
    vim.opt.statusline     = "%f:%l:%c %m%r%h%w%q%y [enc=%{&fileencoding}] [ff=%{&fileformat}] %{FugitiveStatusline()}"
    vim.opt.swapfile       = false
    vim.opt.tabstop        = 4
    vim.opt.termguicolors  = true
    vim.opt.textwidth      = 100
    vim.opt.undodir        = os.getenv("HOME") .. "/.vim/undo/"
    vim.opt.undofile       = true
    vim.opt.wildignorecase = true
    vim.opt.wildoptions    = "pum"
    vim.opt.wrap           = false
    vim.opt.path:append("**")
    vim.opt.shada:append("!")
end

local function setup_plugins()
    -- Setup lazy.nvim
    local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
    if not io.open(lazypath .. "/README.md", "r") then
        local lazyrepo = "https://github.com/folke/lazy.nvim.git"
        vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
    end
    vim.opt.rtp:prepend(lazypath)

    -- Plugins
    require("lazy").setup({
        defaults = { lazy = false },
        { "MattesGroeger/vim-bookmarks" },
        { "dhruvasagar/vim-table-mode" },
        { "karb94/neoscroll.nvim" },
        { "nvim-tree/nvim-tree.lua",          tag = "v1.6.1" },
        { "nvim-treesitter/nvim-treesitter" },
        { "skywind3000/asyncrun.vim" },
        { "t9md/vim-textmanip" },
        { "tpope/vim-commentary" },
        { "tpope/vim-fugitive" },
        { "tpope/vim-surround" },
        { "tpope/vim-unimpaired" },
        { "vim-scripts/DrawIt" },
        { "williamboman/mason-lspconfig.nvim" },
        { "williamboman/mason.nvim" },
        { "modulomedito/rookie_toys.nvim" },
    })

    -- Plugin setups
    require("nvim-tree").setup({
        git = {
            enable = false
        }
    })

    require("neoscroll").setup()
    local keymap = {
        ["<C-u>"] = function() require("neoscroll").ctrl_u({ duration = 350, easing = "sine" }) end,
        ["<C-f>"] = function() require("neoscroll").ctrl_u({ duration = 350, easing = "sine" }) end,
        ["<C-d>"] = function() require("neoscroll").ctrl_d({ duration = 350, easing = "sine" }) end,
    }
    for key, func in pairs(keymap) do
        vim.keymap.set({ "n", "v", "x" }, key, func)
    end
end

local function setup_vimplug()
    local cmd_first = ""
    local env_path = ""
    local loc_path = ""
    local cmd_final = ""
    local url = "https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"

    if vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
        cmd_first = 'iwr -useb ' .. url
        env_path = '$(@($env:XDG_DATA_HOME, $env:LOCALAPPDATA)[$null -eq $env:XDG_DATA_HOME])'
        loc_path = env_path .. '/nvim-data/site/autoload/plug.vim'
        cmd_final = 'ni \\"' .. loc_path .. '\\" -Force'
        if not io.open(loc_path, "r") then
            vim.fn.system('powershell -command "' .. cmd_first .. '|' .. cmd_final)
        end
    else
        cmd_first = 'sh -c \'curl -fLo '
        env_path = '"${XDG_DATA_HOME:-$HOME/.local/share}"'
        loc_path = env_path .. '/nvim/site/autoload/plug.vim'
        cmd_final = cmd_first .. loc_path .. " --create-dirs " .. url
        if not io.open(loc_path, "r") then
            vim.fn.system(cmd_final)
        end
    end

    local plug = vim.fn['plug#']
    vim.call('plug#begin', vim.fn.stdpath('data') .. '/vimplug')
    plug("dhruvasagar/vim-table-mode")
    plug("modulomedito/rookie_toys.nvim")
    plug("preservim/nerdtree")
    plug("skywind3000/asyncrun.vim")
    plug("t9md/vim-textmanip")
    plug("tpope/vim-commentary")
    plug("tpope/vim-fugitive")
    plug("tpope/vim-surround")
    plug("tpope/vim-unimpaired")
    plug("vim-scripts/DrawIt")
    plug("williamboman/mason-lspconfig.nvim")
    plug("williamboman/mason.nvim")
    vim.call('plug#end')
end

local function setup_lsp()
    require("mason").setup()
    require("mason-lspconfig").setup({
        ensure_installed = {
            "clangd", "cmake", "jsonls", "lua_ls", "marksman", "pylsp", "rust_analyzer", "taplo",
        }
    })
    vim.lsp.config('rust-analyzer', {
        cmd = { 'rust-analyzer' },
        root_markers = { '.git', 'Cargo.toml' },
        filetypes = { 'rust' }
    })
    vim.lsp.config("luals", {
        cmd = { 'lua-language-server' },
        root_markers = { '.luarc.json', '.luarc.jsonc' },
        filetypes = { 'lua' }
    })
    vim.lsp.config('markdown', {
        cmd = { 'marksman' },
        root_markers = { '.git' },
        filetypes = { 'markdown' }
    })
    vim.lsp.config("taplo", {
        cmd = { 'taplo', 'lsp', 'stdio' },
        root_markers = { '.git', 'Cargo.toml' },
        filetypes = { 'toml' },
    })
    vim.lsp.config("clangd", {
        cmd = { 'clangd', '--clang-tidy', '--background-index', '--offset-encoding=utf-8', },
        root_markers = { '.clangd', 'compile_commands.json' },
        filetypes = { 'c', 'cpp' },
    })
    vim.lsp.enable({ "clangd", "luals", "markdown", "taplo", "rust-analyzer" })
    vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("LspConfig", { clear = true }),
        callback = function(ev)
            local bufnr = ev.buf
            local bufopt = { noremap = true, silent = true, buffer = bufnr }
            local client = vim.lsp.get_client_by_id(ev.data.client_id)
            if client ~= nil then
                if client:supports_method('textDocument/completion') then
                    vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })
                end
                if client.name == "clangd" then
                    vim.keymap.set("n", "<leader>hh", ':lua require("rookie_toys.c").toggle_source_header()<CR>', bufopt)
                end
            end
            vim.bo[bufnr].omnifunc = "v:lua.vim.lsp.omnifunc"
            vim.keymap.set("i", "<C-k>", vim.lsp.buf.signature_help, bufopt)
            vim.keymap.set("n", "<S-M-f>", vim.lsp.buf.format, bufopt)
            vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, bufopt)
            vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, bufopt)
            vim.keymap.set("n", "gd", vim.lsp.buf.definition, bufopt)
            vim.keymap.set("n", "gD", vim.lsp.buf.declaration, bufopt)
            vim.keymap.set("n", "gh", vim.lsp.buf.hover, bufopt)
            vim.keymap.set("n", "gi", vim.lsp.buf.implementation, bufopt)
            vim.keymap.set("n", "gr", vim.lsp.buf.references, bufopt)
            vim.keymap.set("n", "gs", vim.lsp.buf.document_symbol, bufopt)
            vim.keymap.set("n", "gy", vim.lsp.buf.type_definition, bufopt)
            vim.keymap.set("n", "[d", ":lua vim.diagnostic.jump({ count = 1, float = true })<CR>", bufopt)
            vim.keymap.set("n", "]d", ":lua vim.diagnostic.jump({ count = 1, float = true })<CR>", bufopt)
            vim.keymap.set("n", "]D", ":lua vim.diagnostic.setqflist()<CR>", bufopt)
        end,
    })
end

local function setup_autocmd()
    -- vim.api.nvim_create_autocmd("BufRead", {
    --     pattern = { "*.md", ".lua", ".rs" },
    --     callback = function()
    --         vim.cmd("TSBufEnable highlight")
    --     end,
    -- })
end

local function setup()
    setup_misc()
    setup_plugins()
    setup_keymap()
    setup_option()
    setup_autocmd()
    setup_lsp()
end

return {
    setup = setup,
    setup_vimplug = setup_vimplug,
    setup_keymap = setup_keymap,
    setup_lsp = setup_lsp,
    setup_misc = setup_misc,
    setup_option = setup_option,
}
