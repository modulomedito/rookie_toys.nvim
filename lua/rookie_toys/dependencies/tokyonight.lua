local M = {}

function M.setup()
    local ok, tokyonight = pcall(require, "tokyonight")
    if not ok then
        return
    end
    tokyonight.setup({
        styles = {
            comments = { italic = false },
        },
    })
    vim.cmd.colorscheme("tokyonight-night")
end

return M