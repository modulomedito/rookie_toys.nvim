local M = {}

function M.setup()
    require("mini.align").setup()
    require("mini.jump2d").setup()
    
    pcall(function()
        require("mini.ai").setup({
            mappings = {
                around_next = "aa",
                inside_next = "ii",
            },
            n_lines = 500,
        })
    end)

    pcall(function()
        require("mini.surround").setup()
    end)

    pcall(function()
        local statusline = require("mini.statusline")
        statusline.setup({ use_icons = vim.g.have_nerd_font })
        statusline.section_location = function()
            return "%2l:%-2v"
        end
    end)
end

return M
