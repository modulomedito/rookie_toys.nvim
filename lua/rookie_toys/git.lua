local function output_stdout_to_buffer(cmd)
    vim.fn.jobstart(cmd, {
        on_stdout = function(_, data)
            if data then
                vim.schedule(function() -- Schedule to run safely in the main loop
                    vim.cmd("new")
                    vim.api.nvim_buf_set_lines(0, 0, -1, false, data)
                end)
            end
        end,
    })
end

local function open_git_graph_local()
    local cmd = '!git log --graph --decorate '
    local decorate = '--pretty=format:"%h [%ad] {%an} |%d %s" --date=format-local:"%y-%m-%d %H:%M"'
    cmd = cmd .. decorate
    -- vim.cmd(cmd)
    output_stdout_to_buffer(cmd)
end

local function open_git_graph_all()
    local cmd = '!git log --all --graph --decorate '
    local decorate = '--pretty=format:"%h [%ad] {%an} |%d %s" --date=format-local:"%y-%m-%d %H:%M"'
    cmd = cmd .. decorate

    -- vim.cmd(cmd)
    output_stdout_to_buffer(cmd)
end

return {
    open_git_graph_all = open_git_graph_all,
    open_git_graph_local = open_git_graph_local,
}
