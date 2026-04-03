local M = {}

function M.setup()
    local ok, conform = pcall(require, "conform")
    if not ok then
        return
    end

    conform.setup({
        formatters_by_ft = {
            c = { "clang-format" },
            cpp = { "clang-format" },
        },
        format_on_save = {
            -- These options will be passed to conform.format()
            timeout_ms = 500,
            lsp_fallback = true,
        },
    })
end

return M
