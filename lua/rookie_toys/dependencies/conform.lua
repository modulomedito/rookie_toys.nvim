local M = {}

function M.setup()
    local ok, conform = pcall(require, "conform")
    if not ok then
        return
    end

    conform.setup({
        formatters_by_ft = {
            c = { { "uncrustify", "clang-format" } },
            cpp = { { "uncrustify", "clang-format" } },
        },
        format_on_save = {
            timeout_ms = 500,
            lsp_fallback = true,
        },
    })

    vim.keymap.set({ "n", "v" }, "<M-S-f>", function()
        conform.format({
            lsp_fallback = true,
            async = false,
            timeout_ms = 500,
        })
        vim.api.nvim_input("<Esc>")
    end, { silent = true, desc = "Format file or range (conform)" })
end

return M
