if vim.g.rookie_clangd_is_loaded == 1 then
    return
end
vim.g.rookie_clangd_is_loaded = 1

-- Setup
require("rookie_clangd").setup()
local git = require("rookie_toys.git")
local c = require("rookie_toys.c")

-- User commands
local api = require("rookie_clangd.api")
vim.api.nvim_create_user_command("RookieClangdGenerateCompileCommands", function()
    api.generate_compile_commands()
end, {})
vim.api.nvim_create_user_command("RookieClangdAddDefineSymbol", function()
    api.add_define_symbol()
    api.generate_compile_commands()
end, {})
vim.api.nvim_create_user_command("RookieClangdRemoveDefineSymbol", function()
    api.remove_define_symbol()
    api.generate_compile_commands()
end, {})
vim.api.nvim_create_user_command("RookieClangdChoosePreset", function()
    api.choose_preset()
    api.generate_compile_commands()
end, {})

-- Git
vim.api.nvim_create_user_command("RookieToysGitOpenGraph", function()
    git.open_git_graph_all()
end, {})
vim.api.nvim_create_user_command("RookieToysGitOpenGraphLocal", function()
    git.open_git_graph_local()
end, {})

-- C
vim.api.nvim_create_user_command("RookieToysCToggleSourceHeader", function()
    c.toggle_source_header()
end, {})
