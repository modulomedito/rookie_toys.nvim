local M = {}

function M.setup()
    local ok, guess_indent = pcall(require, "guess-indent")
    if not ok then
        return
    end
    guess_indent.setup({})
end

return M