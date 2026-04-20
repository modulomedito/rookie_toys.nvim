local M = {}

function M.setup()
    if vim.g.neovide then
        return
    end

    require("smear_cursor").setup()
end

return M
