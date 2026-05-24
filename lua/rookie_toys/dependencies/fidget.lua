local M = {}

function M.setup()
    local ok, fidget = pcall(require, "fidget")
    if not ok then
        return
    end
    fidget.setup({})
end

return M