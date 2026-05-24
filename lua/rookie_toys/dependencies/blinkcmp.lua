local M = {}

function M.setup()
    local ok_blink, blink = pcall(require, "blink.cmp")
    if not ok_blink then
        return
    end

    blink.setup({
        keymap = {
            preset = "default",
        },
        appearance = {
            nerd_font_variant = "mono",
        },
        completion = {
            documentation = { auto_show = false, auto_show_delay_ms = 500 },
        },
        sources = {
            default = { "lsp", "path", "snippets" },
        },
        snippets = { preset = "luasnip" },
        fuzzy = { implementation = "lua" },
        signature = { enabled = true },
    })
end

return M