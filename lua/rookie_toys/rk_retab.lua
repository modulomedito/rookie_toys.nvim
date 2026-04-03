local M = {}

function M.setup()
    vim.api.nvim_create_user_command("Retab", function()
        vim.opt_local.tabstop = 4
        vim.opt_local.expandtab = false
        vim.cmd("%retab!")
        vim.opt_local.expandtab = true
    end, { desc = "Retab current buffer" })
end

return M
