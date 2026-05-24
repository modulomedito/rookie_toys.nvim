local M = {}

function M.setup()
    local ok_mason, mason = pcall(require, "mason")
    if not ok_mason then
        return
    end

    mason.setup({})

    local servers = {
        stylua = {},
        lua_ls = {
            settings = {
                Lua = {
                    format = { enable = false },
                },
            },
        },
    }

    local ok_mason_tool, mason_tool = pcall(require, "mason-tool-installer")
    if ok_mason_tool then
        local ensure_installed = vim.tbl_keys(servers)
        mason_tool.setup({ ensure_installed = ensure_installed })
    end
end

return M