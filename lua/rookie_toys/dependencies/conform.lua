local M = {}

function M.setup()
    local ok, conform = pcall(require, "conform")
    if not ok then
        return
    end

    conform.setup({
        formatters_by_ft = {
            c = {
                "clang-format",
                "uncrustify",
                stop_after_first = true
            },
            cpp = {
                "clang-format",
                "uncrustify",
                stop_after_first = true
            }
        },
        format_on_save = false
    })

    vim.keymap.set({"n", "v"}, "<M-S-f>", function()
        conform.format({
            lsp_fallback = true,
            async = false,
            timeout_ms = 500
        })
        vim.api.nvim_input("<Esc>")
    end, {
        silent = true,
        desc = "Format file or range (conform)"
    })

    vim.keymap.set("n", "<C-s>", function()
        vim.cmd("normal! m6")
        vim.cmd("%s/\\s\\+$//e")
        local ok, conform = pcall(require, "conform")
        if ok then
            conform.format({
                lsp_fallback = true,
                async = false
            })
        else
            vim.lsp.buf.format()
        end
        vim.cmd("w")
        vim.cmd("normal! `6zz")
        vim.cmd("noh")
    end, {
        silent = true,
        desc = "Format and save (conform)"
    })
end

return M
