local M = {}

function M.setup()
    -- Global variable to control enabling keymaps
    -- Default to true if not set (nil), or check explicitly if false
    if vim.g.rookie_toys_keymap_enable == false then
        return
    end

    -- Edit init.lua quickly
    vim.keymap.set("n", "<leader>vimrc", "<cmd>vs $MYVIMRC<cr>", {
        desc = "Open init.lua",
    })

    -- Edit this plugin quickly
    vim.keymap.set("n", "<leader>vimrk", function()
        local path = vim.fn.stdpath("data")
            .. "/lazy/rookie_toys.nvim/plugin/rookie_toys.lua"
        vim.cmd("vs " .. path)
    end, {
        desc = "Open rookie_toys.lua",
    })

    -- Set leader key as space
    vim.g.mapleader = " "
    vim.g.maplocalleader = " "

    -- Command mode
    vim.keymap.set("c", "<C-v>", "<C-r>*")

    -- Normal mode
    if vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
        vim.keymap.set("n", "*", "*zz") -- windows refine
    else
        vim.keymap.set("n", "*", "*zz") -- macos refine
    end
    -- vim.keymap.set("n", "<C-p>", ":find *")
    vim.keymap.set(
        "n",
        "<F2>",
        ":%s/\\C\\<<C-r><C-w>\\>/<C-r><C-w>/g<Left><Left>"
    )
    vim.keymap.set("n", "<M-Down>", ":m .+1<CR>==")
    vim.keymap.set("n", "<M-Up>", ":m .-2<CR>==")
    vim.keymap.set("n", "<M-j>", ":m .+1<CR>==", { silent = true })
    vim.keymap.set("n", "<M-k>", ":m .-2<CR>==", { silent = true })

    -- Normal mode silent mappings
    vim.keymap.set("n", "+", ":vertical resize +2<CR>", {
        silent = true,
    })
    vim.keymap.set("n", "<C-M-PageDown>", ":tabmove +1<CR>", {
        silent = true,
    })
    vim.keymap.set("n", "<C-M-PageUp>", ":tabmove -1<CR>", {
        silent = true,
    })
    vim.keymap.set("n", "<C-S-Tab>", "gT", {
        silent = true,
    })
    vim.keymap.set("n", "<C-t>", ":tabnew<CR>", {
        silent = true,
    })
    vim.keymap.set("n", "<C-Tab>", "gt", {
        silent = true,
    })
    vim.keymap.set("n", "<C-q>", ":q<CR>", {
        silent = true,
    })
    vim.keymap.set("n", "<leader><C-q>", ":tabclose<CR>", {
        silent = true,
    })
    vim.keymap.set("n", "<C-w>i", "gt", {
        silent = true,
    })
    vim.keymap.set("n", "<C-w>u", "gT", {
        silent = true,
    })
    vim.keymap.set("n", "<F10>", ":cnext<CR>", {
        silent = true,
    })
    vim.keymap.set("n", "<F11>", ":cclose<CR>", {
        silent = true,
    })
    vim.keymap.set("n", "<F8>", ":copen<CR>", {
        silent = true,
    })
    vim.keymap.set("n", "<F9>", ":cprevious<CR>", {
        silent = true,
    })
    vim.keymap.set("n", "<leader>clr", ":%bd<bar>e #<bar>normal `<CR>", {
        silent = true,
    })
    vim.keymap.set("n", "<leader>lh", ":noh<CR>", {
        silent = true,
    })
    vim.keymap.set("n", "<leader>vim", ":vs $MYVIMRC<CR>", {
        silent = true,
    })
    vim.keymap.set("n", "_", ":vertical resize -2<CR>", {
        silent = true,
    })
    vim.keymap.set("n", "<leader>tm", "<cmd>vs|term<CR>", {
        silent = true,
    })

    vim.keymap.set("n", "K", "i<CR><Esc>")
    vim.keymap.set("n", "O", "O<Space><BS><Esc>")
    vim.keymap.set("n", "go", '"0yi):!start <C-r>0<CR>')
    vim.keymap.set("n", "j", "gj")
    vim.keymap.set("n", "k", "gk")
    vim.keymap.set("n", "o", "o<Space><BS><Esc>")

    -- Normal, Visual mode
    vim.keymap.set({ "n", "v" }, "<C-d>", "<C-d>zz", {
        silent = true,
    })
    vim.keymap.set({ "n", "v" }, "<C-f>", "<C-u>zz", {
        silent = true,
    })

    -- Normal, Visual, Operator-pending mode
    -- vim.keymap.set({ "n", "v", "o" }, "<leader>P", '"0P')
    -- vim.keymap.set({ "n", "v", "o" }, "<leader>p", '"0p')
    vim.keymap.set({ "n", "v", "o" }, "H", "g^")
    vim.keymap.set({ "n", "v", "o" }, "L", "g_")

    -- Visual mode
    vim.keymap.set("v", "/", '"-y/<C-r>-<CR>N')
    vim.keymap.set("v", "<C-j>", ":m '><+1<CR>gv=gv")
    vim.keymap.set("v", "<C-k>", ":m '<-2<CR>gv=gv")
    vim.keymap.set("v", "<F2>", '"-y:%s/<C-r>-\\C/<C-r>-/g<Left><Left>')
    vim.keymap.set("v", "<M-Down>", ":m '><+1<CR>gv=gv")
    vim.keymap.set("v", "<M-Up>", ":m '<-2<CR>gv=gv")
    vim.keymap.set("v", "<M-j>", ":m '><+1<CR>gv=gv", { silent = true })
    vim.keymap.set("v", "<M-k>", ":m '<-2<CR>gv=gv", { silent = true })
    vim.keymap.set("v", "<leader>ss", ":sort<CR>")
    vim.keymap.set("v", "<C-b>", '"-di**<C-r>-**<Esc>', {
        silent = true,
    })
    vim.keymap.set("v", "y", "ygv<Esc>")

    -- Select mode
    vim.keymap.set("x", "p", "P")

    -- Git obs mapping
    vim.keymap.set("n", "<leader>obs", function()
        vim.cmd("wa")
        vim.cmd("silent !git pull")
        vim.cmd("silent !git add .")
        vim.cmd('silent !git commit -m "update by vim"')
        vim.cmd("silent !git push")
        vim.cmd("silent !git fetch")
        vim.cmd("!git log --oneline --graph --all --decorate")
    end, {
        silent = true,
    })
end

return M
