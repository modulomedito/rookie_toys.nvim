local default_config = {
    preset = {
        {
            name = "",
            project_dir = {},
            compiler = "",
            define = {},
            exclude_dir = {},
            extra_flags = {},
            header_pattern = {},
            include = {},
            source_pattern = {},
            hooks = {
                before_generation_callback = function() end,
                after_generation_callback = function() end,
            },
        },
    },
    compiler = "gcc", -- Any as you like, it's just a trick
    define = {},
    include = {},
    exclude_dir = { ".git", ".cache", ".vscode" },
    extra_flags = { "-ferror-limit=3000" }, -- Prevent Clangd stop when too many errors emitted
    project_dir_pattern = { ".git", ".gitignore", "Cargo.toml", "package.json", "go.mod" },
    header_pattern = { "h" },
    source_pattern = { "c" },
    hooks = {
        before_generation_callback = function() end,
        after_generation_callback = function()
            vim.cmd("LspRestart")
        end,
    },
}

local default_param = {
    build_dir = {},
    compiler = "gcc",
    defines = {},
    extra_flags = { "-ferror-limit=3000" },
    file = {},
    includes = {},
    sources = {},
}

Rookie_clangd_config = default_config
Rookie_clangd_param = default_param

local M = {}

M.setup = function(user_config)
    local previous_config = Rookie_clangd_config or default_config
    Rookie_clangd_config = vim.tbl_deep_extend("force", previous_config, user_config or {})
        or default_config
end

return M
