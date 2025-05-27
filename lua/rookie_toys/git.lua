local function output_stdout_to_quickfix(cmd)
    local output = vim.fn.systemlist(cmd)
    vim.fn.setqflist({}, 'r', { lines = output })
    vim.cmd("copen")
end

local function open_git_graph_local()
    local cmd = 'git log --graph --decorate '
    local decorate = '--pretty=format:"%h [%ad] {%an} |%d %s" --date=format-local:"%y-%m-%d %H:%M"'
    cmd = cmd .. decorate
    -- vim.cmd(cmd)
    output_stdout_to_quickfix(cmd)
end

local function open_git_graph_all()
    local cmd = 'git log --all --graph --decorate '
    local decorate = '--pretty=format:"%h [%ad] {%an} |%d %s" --date=format-local:"%y-%m-%d %H:%M"'
    cmd = cmd .. decorate

    -- vim.cmd(cmd)
    output_stdout_to_quickfix(cmd)
end

return {
    open_git_graph_all = open_git_graph_all,
    open_git_graph_local = open_git_graph_local,
}
