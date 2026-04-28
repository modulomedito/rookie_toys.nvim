local M = {}

function M.setup()
    vim.opt.autoindent = true
    vim.opt.autoread = true
    vim.opt.background = "dark"
    vim.opt.belloff = "all"
    vim.opt.breakindent = true
    vim.opt.clipboard = "unnamed"
    vim.opt.cmdheight = 2
    vim.opt.colorcolumn = { "81", "101", "121" }
    vim.opt.complete = { ".", "w", "b", "u", "t" }
    vim.opt.completeopt = { "menuone", "noselect", "popup" }
    vim.opt.cursorcolumn = true
    vim.opt.cursorline = true
    vim.opt.expandtab = true
    vim.opt.fileformat = "unix"
    vim.opt.fileencoding = "utf-8"
    vim.opt.formatoptions:append("mB")
    vim.opt.grepformat = "%f:%l:%c:%m,%f:%l:%m"

    if vim.fn.has("gui_running") == 1 or vim.g.neovide then
        pcall(function()
            if vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
                vim.opt.guifont = "Agave Nerd Font:h12"
            else
                vim.opt.guifont = "Agave Nerd Font:h16"
            end
            vim.opt.guioptions:append("k")
            vim.opt.guioptions:remove("L")
            vim.opt.guioptions:remove("T")
            vim.opt.guioptions:remove("e")
            vim.opt.guioptions:remove("m")
            vim.opt.guioptions:remove("r")
        end)
        vim.opt.columns = 107
        vim.opt.lines = 25
    end

    vim.opt.hlsearch = true
    vim.opt.ignorecase = true
    vim.opt.infercase = true
    vim.opt.iskeyword = "@,48-57,_,192-255,-"
    vim.opt.laststatus = 2
    vim.opt.list = true
    vim.opt.listchars = { tab = "-->", trail = "~", nbsp = "␣" }
    vim.opt.modeline = true
    vim.opt.modelines = 5
    vim.opt.backup = false
    vim.opt.foldenable = false
    vim.opt.swapfile = false
    vim.opt.wrap = false
    vim.opt.writebackup = false
    vim.opt.number = true
    vim.opt.path:append("**")
    vim.opt.pumheight = 50
    -- vim.opt.relativenumber = true
    vim.opt.sessionoptions:append({ "tabpages", "globals" })
    vim.opt.shiftwidth = 4
    vim.opt.shortmess = "flnxtocTO"
    vim.opt.signcolumn = "yes"
    vim.opt.smartcase = true
    vim.opt.smarttab = true
    pcall(function()
        vim.opt.smoothscroll = true
    end)
    vim.opt.softtabstop = 4
    vim.opt.splitbelow = true
    vim.opt.splitright = true
    vim.opt.tabstop = 4
    vim.opt.termguicolors = true
    vim.opt.textwidth = 100
    vim.opt.undofile = true
    vim.opt.updatetime = 300
    vim.opt.wildcharm = vim.fn.char2nr("\t") -- <Tab>
    vim.opt.wildignorecase = true
    vim.opt.wildoptions = "pum"

    if vim.fn.has("unix") == 1 then
        vim.opt.undodir = vim.fn.expand("$HOME/.vim/undo/")
        vim.opt.shadafile = vim.fn.expand("$HOME/.vim/main.shada")
    else
        vim.opt.undodir = vim.fn.expand("$HOME/vimfiles/undo/")
        vim.opt.shadafile = vim.fn.expand("$HOME/vimfiles/main.shada")

        -- Fix Windows shell issues (especially for paths with spaces)
        if
            vim.fn.executable("pwsh") == 1
            or vim.fn.executable("powershell") == 1
        then
            local pwsh = vim.fn.executable("pwsh") == 1 and "pwsh"
                or "powershell"
            vim.opt.shell = pwsh
            vim.opt.shellcmdflag =
                "-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command [Console]::InputEncoding=[Console]::OutputEncoding=[System.Text.Encoding]::UTF8;"
            vim.opt.shellquote = ""
            vim.opt.shellxquote = ""
            vim.opt.shellpipe = "| Out-File -Encoding UTF8 %s"
            vim.opt.shellredir = "| Out-File -Encoding UTF8 %s"
        else
            vim.opt.shell = "cmd.exe"
            vim.opt.shellcmdflag = "/s /c"
            vim.opt.shellquote = ""
            vim.opt.shellxquote = '"'
        end

        -- Ensure git executable is found without space issues for fugitive
        vim.g.fugitive_git_executable = "git"
    end
end

return M
