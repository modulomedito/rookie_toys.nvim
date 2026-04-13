local M = {}

function M.setup()
    -- Move selected lines down
    -- :m '>+1 moves the selected block of lines below the current selection
    -- gv reselects the text so you can keep moving it
    vim.keymap.set("x", "<C-j>", ":m '>+1<CR>gv=gv", { desc = "Move text down", noremap = true, silent = true })

    -- Move selected lines up
    -- :m '<-2 moves the selected block of lines above the current selection
    vim.keymap.set("x", "<C-k>", ":m '<-2<CR>gv=gv", { desc = "Move text up", noremap = true, silent = true })

    -- Move selected text left (dedent)
    -- < shifts the text left, gv reselects it
    vim.keymap.set("x", "<C-h>", "<gv", { desc = "Move text left", noremap = true, silent = true })

    -- Move selected text right (indent)
    -- > shifts the text right, gv reselects it
    vim.keymap.set("x", "<C-l>", ">gv", { desc = "Move text right", noremap = true, silent = true })
end

return M
