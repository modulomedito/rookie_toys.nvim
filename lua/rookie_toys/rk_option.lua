local M = {}

function M.setup()
    vim.opt_global.autoindent = true
    vim.opt_global.autoread = true
    vim.opt_global.background = "dark"
    vim.opt_global.belloff = "all"
    vim.opt_global.breakindent = true
    vim.opt_global.clipboard = "unnamed"
    vim.opt_global.cmdheight = 2
    vim.opt_global.colorcolumn = { "81", "101", "121" }
    vim.opt_global.complete = { ".", "w", "b", "u", "t" }
    vim.opt_global.completeopt = { "menuone", "noselect", "popup" }
    vim.opt_global.cursorcolumn = true
    vim.opt_global.cursorline = true
    vim.opt_global.expandtab = true
    vim.opt_global.fileformat = "unix"
    vim.opt_global.fileencoding = "utf-8"
    vim.opt_global.formatoptions:append("mB")
    vim.opt_global.grepformat = "%f:%l:%c:%m,%f:%l:%m"

    if vim.fn.has("gui_running") == 1 then
        vim.opt_global.guifont = "Cascadia Code:h9"
        vim.opt_global.guioptions:append("k")
        vim.opt_global.guioptions:remove("L")
        vim.opt_global.guioptions:remove("T")
        vim.opt_global.guioptions:remove("e")
        vim.opt_global.guioptions:remove("m")
        vim.opt_global.guioptions:remove("r")
        vim.opt_global.columns = 107
        vim.opt_global.lines = 25
    end

    vim.opt_global.hlsearch = true
    vim.opt_global.ignorecase = true
    vim.opt_global.infercase = true
    vim.opt_global.iskeyword = "@,48-57,_,192-255,-"
    vim.opt_global.laststatus = 2
    vim.opt_global.list = true
    vim.opt_global.listchars = { tab = "-->", trail = "~", nbsp = "␣" }
    vim.opt_global.modeline = true
    vim.opt_global.modelines = 5
    vim.opt_global.backup = false
    vim.opt_global.foldenable = false
    vim.opt_global.swapfile = false
    vim.opt_global.wrap = false
    vim.opt_global.writebackup = false
    vim.opt_global.number = true
    vim.opt_global.path:append("**")
    vim.opt_global.pumheight = 50
    -- vim.opt_global.relativenumber = true
    vim.opt_global.sessionoptions:append({ "tabpages", "globals" })
    vim.opt_global.shiftwidth = 4
    vim.opt_global.shortmess = "flnxtocTO"
    vim.opt_global.signcolumn = "yes"
    vim.opt_global.smartcase = true
    vim.opt_global.smarttab = true
    vim.opt_global.smoothscroll = true
    vim.opt_global.softtabstop = 4
    vim.opt_global.splitbelow = true
    vim.opt_global.splitright = true
    vim.opt_global.tabstop = 4
    vim.opt_global.termguicolors = true
    vim.opt_global.textwidth = 100
    vim.opt_global.undofile = true
    vim.opt_global.updatetime = 300
    vim.opt_global.wildcharm = vim.fn.char2nr("\t") -- <Tab>
    vim.opt_global.wildignorecase = true
    vim.opt_global.wildoptions = "pum"

    if vim.fn.has("unix") == 1 then
        vim.opt_global.undodir = vim.fn.expand("$HOME/.vim/undo/")
        vim.opt_global.shadafile = vim.fn.expand("$HOME/.vim/main.shada")
    else
        vim.opt_global.undodir = vim.fn.expand("$HOME/vimfiles/undo/")
        vim.opt_global.shadafile = vim.fn.expand("$HOME/vimfiles/main.shada")
    end
end

return M
