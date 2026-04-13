local M = {}

function M.setup()
    -- Move selected lines down
    -- :m '>+1 moves the selected block of lines below the current selection
    -- gv reselects the text so you can keep moving it
    vim.keymap.set(
        "x",
        "<C-j>",
        ":m '>+1<CR>gv=gv",
        { desc = "Move text down", noremap = true, silent = true }
    )

    -- Move selected lines up
    -- :m '<-2 moves the selected block of lines above the current selection
    vim.keymap.set(
        "x",
        "<C-k>",
        ":m '<-2<CR>gv=gv",
        { desc = "Move text up", noremap = true, silent = true }
    )

    -- Move selected text left (one character)
    -- For character-wise/block-wise, it deletes and pastes left.
    -- For line-wise, it removes one space from the beginning of the line.
    vim.keymap.set(
        "x",
        "<C-h>",
        function()
            local mode = vim.fn.mode()
            if mode == "V" then
                return ":s/^ //e<CR>gv"
            end
            local col = vim.fn.col(".")
            if col > 1 then
                return '"zdh"zPgv'
            else
                return '"zd"zPgv'
            end
        end,
        { desc = "Move text left", noremap = true, silent = true, expr = true }
    )

    -- Move selected text right (one character)
    -- For character-wise/block-wise, it deletes and pastes right.
    -- For line-wise, it adds one space to the beginning of the line.
    vim.keymap.set(
        "x",
        "<C-l>",
        function()
            local mode = vim.fn.mode()
            if mode == "V" then
                return ":s/^/ /<CR>gv"
            end
            return '"zd"zpgv'
        end,
        { desc = "Move text right", noremap = true, silent = true, expr = true }
    )
end

return M
