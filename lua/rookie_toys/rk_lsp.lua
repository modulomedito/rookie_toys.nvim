local M = {}

function M.setup()
    -- Global variable to control enabling LSP keymaps
    if vim.g.rookie_toys_lsp_enable == false then
        return
    end

    -- Map gd to jump to LSP definition
    vim.keymap.set(
        "n",
        "gd",
        vim.lsp.buf.definition,
        { desc = "LSP: [G]oto [D]efinition" }
    )
end

return M
