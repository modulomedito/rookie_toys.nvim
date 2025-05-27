local c = require("rookie_toys.c")
local git = require("rookie_toys.git")
local search = require("rookie_toys.search")
local setup = require("rookie_toys.setup")

-- -- User commands
-- local api = require("rookie_clangd.api")
-- vim.api.nvim_create_user_command("RookieClangdGenerateCompileCommands", function()
--     api.generate_compile_commands()
-- end, {})
-- vim.api.nvim_create_user_command("RookieClangdAddDefineSymbol", function()
--     api.add_define_symbol()
--     api.generate_compile_commands()
-- end, {})
-- vim.api.nvim_create_user_command("RookieClangdRemoveDefineSymbol", function()
--     api.remove_define_symbol()
--     api.generate_compile_commands()
-- end, {})
-- vim.api.nvim_create_user_command("RookieClangdChoosePreset", function()
--     api.choose_preset()
--     api.generate_compile_commands()
-- end, {})

-- C
vim.api.nvim_create_user_command("RookieToysCToggleSourceHeader", function()
    c.toggle_source_header()
end, {})

-- Git
vim.api.nvim_create_user_command("RookieToysGitOpenGraph", function()
    git.open_git_graph_all()
end, {})
vim.api.nvim_create_user_command("RookieToysGitOpenGraphLocal", function()
    git.open_git_graph_local()
end, {})

-- Search
vim.api.nvim_create_user_command("RookieToysSearchCurrentWord", function()
    search.grep_word_under_cursor()
end, {})
vim.api.nvim_create_user_command("RookieToysSearchLiveGrep", function()
    search.live_grep()
end, {})

-- Setup
vim.api.nvim_create_user_command("RookieToysSetup", function()
    setup.search()
end, {})
