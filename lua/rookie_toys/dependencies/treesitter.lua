local M = {}

function M.setup()
    local ok, treesitter = pcall(require, "nvim-treesitter.configs")
    if not ok then
        return
    end
    
    treesitter.setup({
        ensure_installed = { "bash", "c", "diff", "html", "lua", "luadoc", "markdown", "markdown_inline", "query", "vim", "vimdoc" },
        auto_install = true,
        highlight = {
            enable = true,
        },
        indent = {
            enable = true,
        },
    })
end

return M