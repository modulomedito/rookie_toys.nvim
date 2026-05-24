local M = {}

function M.setup()
    local ok, which_key = pcall(require, "which-key")
    if not ok then
        return
    end
    which_key.setup({
        delay = 0,
        icons = { mappings = vim.g.have_nerd_font },
        spec = {
            { "<leader>s", group = "[S]earch", mode = { "n", "v" } },
            { "<leader>t", group = "[T]oggle" },
            { "<leader>h", group = "Git [H]unk", mode = { "n", "v" } },
            { "gr", group = "LSP Actions", mode = { "n" } },
        },
    })
end

return M