local M = {}

function M.setup()
    local has_claudecode, claudecode = pcall(require, "claudecode")
    if not has_claudecode then
        return
    end

    claudecode.setup({
        -- You can add default opts here if needed
    })

    -- Keybindings
    vim.keymap.set("n", "<leader>ac", "<cmd>ClaudeCode<cr>", { desc = "ClaudeCode: Toggle" })
    vim.keymap.set("n", "<leader>af", "<cmd>ClaudeCodeFocus<cr>", { desc = "ClaudeCode: Focus" })
    vim.keymap.set("n", "<leader>ar", "<cmd>ClaudeCode --resume<cr>", { desc = "ClaudeCode: Resume" })
    vim.keymap.set("n", "<leader>aC", "<cmd>ClaudeCode --continue<cr>", { desc = "ClaudeCode: Continue" })
    vim.keymap.set("n", "<leader>am", "<cmd>ClaudeCodeSelectModel<cr>", { desc = "ClaudeCode: Select model" })
    vim.keymap.set("n", "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", { desc = "ClaudeCode: Add current buffer" })
    vim.keymap.set("v", "<leader>as", "<cmd>ClaudeCodeSend<cr>", { desc = "ClaudeCode: Send selection" })

    -- File explorer specific mappings
    vim.api.nvim_create_autocmd("FileType", {
        pattern = { "NvimTree", "neo-tree", "oil", "minifiles", "netrw" },
        callback = function()
            vim.keymap.set("n", "<leader>as", "<cmd>ClaudeCodeTreeAdd<cr>", {
                desc = "ClaudeCode: Add file",
                buffer = true,
            })
        end,
    })

    -- Diff management
    vim.keymap.set("n", "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", { desc = "ClaudeCode: Accept diff" })
    vim.keymap.set("n", "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", { desc = "ClaudeCode: Deny diff" })
end

return M
