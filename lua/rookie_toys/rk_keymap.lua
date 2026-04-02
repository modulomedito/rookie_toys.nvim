local M = {}

function M.setup()
    -- Global variable to control enabling keymaps
    -- Default to true if not set (nil), or check explicitly if false
    if vim.g.rookie_toys_enable_keymap == false then
        return
    end

    -- Edit init.lua quickly
    vim.keymap.set(
        "n",
        "<leader>vimrc",
        "<cmd>e $MYVIMRC<cr>",
        { desc = "Open init.lua" }
    )

    -- Edit this plugin quickly
    vim.keymap.set(
        "n",
        "<leader>vimrk",
        "<cmd>e $MYVIMRC:h/../../nvim-data/lazy/rookie_toys.nvim/plugin/rookie_toys.lua<cr>",
        { desc = "Open rookie_toys.lua" }
    )

    -- vim.g.mapleader = " "
    -- vim.g.maplocalleader = " "

    -- local map = vim.keymap.set
    -- local opts = { silent = true }

    -- -- Command mode
    -- map("c", "<C-v>", "<C-r>*")

    -- -- Normal mode
    -- map("n", "*", "*Nzz")
    -- map("n", "<C-j>", ":m .+1<CR>==")
    -- map("n", "<C-k>", ":m .-2<CR>==")
    -- map("n", "<C-p>", ":find *")
    -- map("n", "<F2>", ":%s/\\C\\<<C-r><C-w>\\>/<C-r><C-w>/g<Left><Left>")
    -- map("n", "<M-Down>", ":m .+1<CR>==")
    -- map("n", "<M-Up>", ":m .-2<CR>==")
    -- map("n", "<M-i>", ":b<Space><Tab>")
    -- map("n", "<M-j>", ":m .+1<CR>==")
    -- map("n", "<M-k>", ":m .-2<CR>==")
    -- map("n", "<M-u>", ":b<Space><Tab><S-Tab><S-Tab>")

    -- -- Silent mappings
    -- map("n", "+", ":vertical resize +2<CR>", opts)
    -- map("n", "<C-M-PageDown>", ":tabmove +1<CR>", opts)
    -- map("n", "<C-M-PageUp>", ":tabmove -1<CR>", opts)
    -- map("n", "<C-S-Tab>", "gT", opts)
    -- map("n", "<C-S-t>", ":tabnew<CR>", opts)
    -- map("n", "<C-Tab>", "gt", opts)
    -- map("n", "<C-q>", ":q<CR>", opts)
    -- map("n", "<C-s>", "m6:%s/\\s\\+$//e<Bar>w<CR>`6zz:noh<CR>", opts)
    -- map("n", "<C-w>i", "gt", opts)
    -- map("n", "<C-w>u", "gT", opts)
    -- map("n", "<F10>", ":cnext<CR>", opts)
    -- map("n", "<F11>", ":cclose<CR>", opts)
    -- map("n", "<F8>", ":copen<CR>", opts)
    -- map("n", "<F9>", ":cprevious<CR>", opts)
    -- map("n", "<leader>clr", ":%bd<bar>e #<bar>normal `<CR>", opts)
    -- map("n", "<leader>vim", ":vs $MYVIMRC<CR>", opts)
    -- map("n", "_", ":vertical resize -2<CR>", opts)

    -- map("n", "K", "i<CR><Esc>")
    -- map("n", "O", "O<Space><BS><Esc>")
    -- map("n", "gd", "<C-]>")
    -- map("n", "go", '"0yi):!start <C-r>0<CR>')
    -- map("n", "j", "gj")
    -- map("n", "k", "gk")
    -- map("n", "o", "o<Space><BS><Esc>")

    -- -- Noremap (Normal, Visual, Operator-pending)
    -- map({ "n", "v", "o" }, "<leader>P", '"0P')
    -- map({ "n", "v", "o" }, "<leader>p", '"0p')
    -- map({ "n", "v", "o" }, "H", "g^")
    -- map({ "n", "v", "o" }, "L", "g_")

    -- -- Visual mode
    -- map("v", "/", '"-y/<C-r>-<CR>N')
    -- map("v", "<C-j>", ":m '><+1<CR>gv=gv")
    -- map("v", "<C-k>", ":m '<-2<CR>gv=gv")
    -- map("v", "<F2>", '"-y:%s/<C-r>-\\C/<C-r>-/g<Left><Left>')
    -- map("v", "<M-Down>", ":m '><+1<CR>gv=gv")
    -- map("v", "<M-Up>", ":m '<-2<CR>gv=gv")
    -- map("v", "<M-j>", ":m '><+1<CR>gv=gv")
    -- map("v", "<M-k>", ":m '<-2<CR>gv=gv")
    -- map("v", "<leader>ss", ":sort<CR>")
    -- map("v", "<C-b>", '"-di**<C-r>-**<Esc>', opts)
    -- map("v", "p", "pgv<Esc>")
    -- map("v", "y", "ygv<Esc>")

    -- -- Git obs mapping
    -- map("n", "<leader>obs", function()
    --     vim.cmd("wa")
    --     vim.cmd("silent !git pull")
    --     vim.cmd("silent !git add .")
    --     vim.cmd('silent !git commit -m "update by vim"')
    --     vim.cmd("silent !git push")
    --     vim.cmd("G fetch")
    --     vim.fn.timer_start(1500, function()
    --         vim.cmd("RookieGitGraph")
    --     end)
    --     vim.cmd("G")
    -- end, opts)
end

return M
