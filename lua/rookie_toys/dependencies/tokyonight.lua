local M = {}

function M.setup()
    local ok, tokyonight = pcall(require, "tokyonight")
    if not ok then
        return
    end

    tokyonight.setup({
        on_highlights = function(hl, c)
            -- More colorful diff colors to make finding diff content easier
            hl.DiffAdd = { bg = "#283B4D", fg = c.green }
            hl.DiffChange = { bg = "#272D43", fg = c.blue }
            hl.DiffDelete = { bg = "#3F2D3D", fg = c.red }
            hl.DiffText = { bg = "#394b70", fg = c.cyan, bold = true }

            -- Git signs (optional but good for consistency)
            hl.GitSignsAdd = { fg = c.green }
            hl.GitSignsChange = { fg = c.blue }
            hl.GitSignsDelete = { fg = c.red }
        end,
    })

    -- Re-apply colorscheme to make changes take effect
    vim.cmd("colorscheme tokyonight")
end

return M
