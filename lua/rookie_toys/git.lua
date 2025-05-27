local function open_git_graph_local()
    local cmd = '!git log --graph --decorate '
    local decorate = '--pretty=format:"%h [%ad] {%an} |%d %s" --date=format-local:"%y-%m-%d %H:%M"'
    cmd = cmd .. decorate
    vim.cmd(cmd)
end

local function open_git_graph_all()
    local cmd = '!git log --all --graph --decorate '
    local decorate = '--pretty=format:"%h [%ad] {%an} |%d %s" --date=format-local:"%y-%m-%d %H:%M"'
    cmd = cmd .. decorate
    vim.cmd(cmd)
end

return {
    open_git_graph_all = open_git_graph_all,
    open_git_graph_local = open_git_graph_local,
}
