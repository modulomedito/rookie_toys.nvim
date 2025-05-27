vim.g.rookie_gitdiff_sha1 = ""
vim.g.rookie_gitdiff_file = ""

local function open_git_graph_local()
    local cmd = 'Git log --graph --decorate '
    local decorate = '--pretty=format:"%h [%ad] {%an} |%d %s" --date=format-local:"%y-%m-%d %H:%M"'
    cmd = cmd .. decorate
    vim.cmd(cmd)
end

local function open_git_graph_all()
    local cmd = 'Git log --all --graph --decorate '
    local decorate = '--pretty=format:"%h [%ad] {%an} |%d %s" --date=format-local:"%y-%m-%d %H:%M"'
    cmd = cmd .. decorate
    vim.cmd(cmd)
end

local function diff()
    if vim.fn.exists(":Git") == 0 then
        print("RookieToysGitDiff: vim-fugitive is NOT installed, diff depends on it!")
        return
    end

    local word = vim.fn.expand("<cword>")
    local is_short_sha = (#word == 7 and word:match("^[0-9a-f]+$") ~= nil)

    if not is_short_sha then
        vim.g.rookie_gitdiff_file = vim.fn.expand("%")
        vim.g.rookie_gitdiff_sha1 = ""
        print("RookieToysGitDiff: Current file path saved, git sha cleared")
        return
    end

    if vim.g.rookie_gitdiff_file == "" then
        print("RookieToysGitDiff: You should run command on your file first")
        return
    end

    if vim.g.rookie_gitdiff_sha1 == "" then
        vim.g.rookie_gitdiff_sha1 = word
        print("RookieToysGitDiff: Git commit sha saved. Next run command on ANOTHER commit sha")
        return
    end

    if vim.g.rookie_gitdiff_sha1 == word then
        print("RookieToysGitDiff: You should put cursor on ANOTHER valid git short sha (7 chars)")
        return
    end

    local commit1 = vim.g.rookie_gitdiff_sha1
    local commit2 = word
    local file_path = vim.g.rookie_gitdiff_file:gsub("\\", "/")
    local cmd1 = "Gsplit " .. commit1 .. ":" .. file_path
    local cmd2 = "vertical Gdiffsplit " .. commit2 .. ":" .. file_path
    local cmd_final = cmd1 .. " | " .. cmd2

    vim.cmd(cmd_final)
    vim.g.rookie_gitdiff_sha1 = ""
end

return {
    open_git_graph_all = open_git_graph_all,
    open_git_graph_local = open_git_graph_local,
    diff = diff,
}
