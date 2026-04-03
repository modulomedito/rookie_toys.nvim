local M = {}

--- Jump to first differing column between this window and the other diff window
function M.jump_to_change()
    local cur_win = vim.api.nvim_get_current_win()
    local cur_line_content = vim.api.nvim_get_current_line()
    local cur_pos = vim.api.nvim_win_get_cursor(0)
    local cur_row = cur_pos[1]

    -- find another window that has 'diff' enabled
    local other_buf = -1
    for _, win in ipairs(vim.api.nvim_list_wins()) do
        if win ~= cur_win and vim.wo[win].diff then
            other_buf = vim.api.nvim_win_get_buf(win)
            break
        end
    end

    if other_buf == -1 then
        vim.notify("No other diff window found", vim.log.levels.WARN)
        return
    end

    -- nvim_buf_get_lines uses 0-indexed line numbers, so cur_row - 1
    local other_lines =
        vim.api.nvim_buf_get_lines(other_buf, cur_row - 1, cur_row, false)
    if #other_lines == 0 then
        vim.notify(
            "No line found in other buffer at current row",
            vim.log.levels.WARN
        )
        return
    end
    local other_line_content = other_lines[1]

    local a = cur_line_content
    local b = other_line_content
    local m = math.min(#a, #b)
    local col = -1

    for i = 1, m do
        if a:sub(i, i) ~= b:sub(i, i) then
            col = i
            break
        end
    end

    if col == -1 then
        if #a ~= #b then
            col = m + 1
        else
            vim.notify("No difference on this line", vim.log.levels.INFO)
            return
        end
    end

    -- nvim_win_set_cursor uses 0-indexed column, so col - 1
    vim.api.nvim_win_set_cursor(0, { cur_row, col - 1 })
end

function M.setup()
    vim.api.nvim_create_user_command(
        "RkGitdiffJumpToChange",
        M.jump_to_change,
        {
            desc = "Jump to the first differing column in diff windows",
        }
    )

    vim.keymap.set("n", "<leader>jd", M.jump_to_change, {
        desc = "Jump to the first differing column in diff windows",
    })
end

return M
