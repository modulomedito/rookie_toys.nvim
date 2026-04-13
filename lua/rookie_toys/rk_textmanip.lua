local M = {}

function M.setup()
    local opts = { noremap = true, silent = true, expr = true }

    -- Move text down
    vim.keymap.set("x", "<C-j>", function()
        local mode = vim.fn.mode()
        if mode == "V" or mode == "v" then
            return ":m '>+1<CR>gv=gv"
        else
            -- Block mode: delete, move down, paste, reselect
            return "djp`[<C-v>`]"
        end
    end, vim.tbl_extend("force", opts, { desc = "Move text down" }))

    -- Move text up
    vim.keymap.set("x", "<C-k>", function()
        local mode = vim.fn.mode()
        if mode == "V" or mode == "v" then
            return ":m '<-2<CR>gv=gv"
        else
            -- Block mode: delete, move up, paste before, reselect
            return "dkP`[<C-v>`]"
        end
    end, vim.tbl_extend("force", opts, { desc = "Move text up" }))

    -- Move text left
    vim.keymap.set("x", "<C-h>", function()
        local mode = vim.fn.mode()
        if mode == "V" then
            -- Line mode: indent left
            return "<gv"
        else
            -- Char/Block mode: delete, move left, paste before, reselect
            -- For block mode, `\22` is returned by mode()
            local reselect = mode == "v" and "v" or "<C-v>"
            return "dhP`[" .. reselect .. "`]"
        end
    end, vim.tbl_extend("force", opts, { desc = "Move text left" }))

    -- Move text right
    vim.keymap.set("x", "<C-l>", function()
        local mode = vim.fn.mode()
        if mode == "V" then
            -- Line mode: indent right
            return ">gv"
        else
            -- Char/Block mode: delete, move right, paste, reselect
            local reselect = mode == "v" and "v" or "<C-v>"
            return "dp`[" .. reselect .. "`]"
        end
    end, vim.tbl_extend("force", opts, { desc = "Move text right" }))
end

return M
