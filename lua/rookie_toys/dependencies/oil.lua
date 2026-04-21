local M = {}

function M.setup()
    require("oil").setup({
        -- Oil will take over directory buffers (e.g., `vim .` or `:e src/`)
        default_file_explorer = true,
        -- Set to true to watch the filesystem for changes and reload oil
        watch_for_changes = false,

        -- Default columns to display
        columns = {
            "icon",
            -- "permissions",
            -- "size",
            -- "mtime",
        },

        -- Buffer-local options to use for oil buffers
        buf_options = {
            buflisted = false,
            bufhidden = "hide",
        },

        -- Window-local options to use for oil buffers
        win_options = {
            wrap = false,
            signcolumn = "no",
            cursorcolumn = false,
            foldcolumn = "0",
            spell = false,
            list = false,
            conceallevel = 3,
            concealcursor = "nvic",
        },

        -- Set to true to auto-delete hidden buffers (useful to keep buffers clean)
        delete_to_trash = false,
        skip_confirm_for_simple_edits = false,
        prompt_save_on_select_new_entry = true,

        -- Keymaps in oil buffer
        keymaps = {
            ["g?"] = "actions.show_help",
            ["<CR>"] = "actions.select",
            ["<C-s>"] = { "actions.select", opts = { vertical = true }, desc = "Open the entry in a vertical split" },
            ["<C-h>"] = { "actions.select", opts = { horizontal = true }, desc = "Open the entry in a horizontal split" },
            ["<C-t>"] = { "actions.select", opts = { tab = true }, desc = "Open the entry in new tab" },
            ["<C-p>"] = "actions.preview",
            ["<C-c>"] = "actions.close",
            ["<C-l>"] = "actions.refresh",
            ["-"] = "actions.parent",
            ["_"] = "actions.open_cwd",
            ["`"] = "actions.cd",
            ["~"] = { "actions.cd", opts = { scope = "tab" }, desc = ":tcd to the current oil directory" },
            ["gs"] = "actions.change_sort",
            ["gx"] = "actions.open_external",
            ["g."] = "actions.toggle_hidden",
            ["g\\"] = "actions.toggle_trash",
        },

        view_options = {
            -- Show files and directories that start with "."
            show_hidden = true,
            is_hidden_file = function(name, bufnr)
                return vim.startswith(name, ".")
            end,
            is_always_hidden = function(name, bufnr)
                return false
            end,
            sort = {
                { "type", "asc" },
                { "name", "asc" },
            },
        },
    })

    -- Optional global keymap to open oil in the current directory
    vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })
end

return M
