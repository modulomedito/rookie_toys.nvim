local M = {}

function M.setup()
    local has_codecompanion, codecompanion = pcall(require, "codecompanion")
    if not has_codecompanion then
        return
    end

    codecompanion.setup({
        strategies = {
            chat = {
                adapter = "ollama",
            },
            inline = {
                adapter = "ollama",
            },
            agent = {
                adapter = "ollama",
            },
        },
        adapters = {
            ollama = function()
                return require("codecompanion.adapters").extend("ollama", {
                    schema = {
                        model = {
                            default = "gemma2:9b",
                        },
                        num_ctx = {
                            default = 16384,
                        },
                    },
                })
            end,
        },
    })

    -- Keymaps
    vim.keymap.set(
        { "n", "v" },
        "<leader>ca",
        "<cmd>CodeCompanionActions<cr>",
        { noremap = true, silent = true }
    )
    vim.keymap.set(
        { "n", "v" },
        "<leader>cc",
        "<cmd>CodeCompanionChat Toggle<cr>",
        { noremap = true, silent = true }
    )
    vim.keymap.set(
        "v",
        "<C-u>",
        "<cmd>CodeCompanionChat Add<cr>",
        { noremap = true, silent = true }
    )

    -- Expand 'cc' into 'CodeCompanion' in the command line
    vim.cmd([[cab CC CodeCompanion]])
end

return M
