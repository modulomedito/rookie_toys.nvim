local M = {}

function M.setup()
    local ok, flash = pcall(require, "flash")
    if not ok then
        return
    end

    flash.setup({
        -- Sensible defaults
        search = {
            -- Don't jump between windows by default
            multi_window = false,
            -- Incremental search
            incremental = false
        },
        modes = {
            -- Enable flash for / and ?
            search = {
                enabled = true,
                highlight = {
                    backdrop = true
                },
                jump = {
                    history = true,
                    register = true,
                    incsearch = true
                }
            },
            -- Enable flash for f, F, t, T
            char = {
                enabled = true,
                -- Hide after jump
                autohide = true,
                -- Show jump labels
                jump_labels = true,
                -- Keep to current line
                multi_window = false,
                -- Highlight the search matches
                highlight = {
                    backdrop = true
                },
                -- Jump immediately to the match
                jump = {
                    autojump = true
                }
            }
        }
    })

    -- Keymaps
    vim.keymap.set({"n", "x", "o"}, "s", function()
        require("flash").jump()
    end, {
        desc = "Flash"
    })

    vim.keymap.set({"n", "x", "o"}, "S", function()
        require("flash").treesitter()
    end, {
        desc = "Flash Treesitter"
    })

    vim.keymap.set("o", "r", function()
        require("flash").remote()
    end, {
        desc = "Remote Flash"
    })

    vim.keymap.set({"o", "x"}, "R", function()
        require("flash").treesitter_search()
    end, {
        desc = "Treesitter Search"
    })

    vim.keymap.set("c", "<c-s>", function()
        require("flash").toggle()
    end, {
        desc = "Toggle Flash Search"
    })
end

return M
