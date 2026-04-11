local M = {}

function M.open_gitgraph()
    local timed_out = false
    vim.notify("Git fetching...", vim.log.levels.INFO)
    local job_id = vim.fn.jobstart({ "git", "fetch" }, {
        on_exit = function(_, exit_code)
            if exit_code == 0 then
                vim.notify("Git fetch completed", vim.log.levels.INFO)
            elseif not timed_out then
                vim.notify("Git fetch failed", vim.log.levels.WARN)
            end
            M.draw_gitgraph()
        end,
    })

    -- 200ms timeout
    vim.defer_fn(function()
        if vim.fn.jobwait({ job_id }, 0)[1] == -1 then
            timed_out = true
            vim.fn.jobstop(job_id)
            vim.notify("Git fetch timed out, showing graph", vim.log.levels.INFO)
        end
    end, 200)
end

function M.draw_gitgraph()
    local fugitive_buf = -1
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.bo[buf].filetype == "fugitive" then
            fugitive_buf = buf
            break
        end
    end

    if fugitive_buf == -1 then
        local ok, err = pcall(vim.cmd, "G")
        if not ok then
            vim.notify("Fugitive failed: " .. tostring(err), vim.log.levels.ERROR)
            return
        end
        vim.schedule(function()
            M.draw_gitgraph()
        end)
        return
    else
        -- Focus fugitive window if it exists, otherwise open it
        local fugitive_win = vim.fn.bufwinid(fugitive_buf)
        if fugitive_win ~= -1 then
            vim.api.nvim_set_current_win(fugitive_win)
        else
            vim.api.nvim_set_current_buf(fugitive_buf)
        end
        -- Refresh fugitive
        pcall(vim.cmd, "G")
    end

    local gitgraph_buf = -1
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.bo[buf].filetype == "gitgraph" then
            gitgraph_buf = buf
            break
        end
    end

    if gitgraph_buf ~= -1 then
        -- Find a window showing this buffer
        local win = vim.fn.bufwinid(gitgraph_buf)
        if win ~= -1 then
            vim.api.nvim_set_current_win(win)
        else
            -- If not visible, split right and switch to it
            vim.cmd("rightbelow vsplit")
            vim.api.nvim_set_current_buf(gitgraph_buf)
        end
    else
        -- If doesn't exist, split right
        vim.cmd("rightbelow vsplit")
    end
    -- Run GitGraph command to update/draw
    require("gitgraph").draw({}, { all = true, max_count = 5000 })
end

function M.setup()
    -- Apply Tokyonight colors if available
    local has_tokyonight, tokyonight_colors =
        pcall(require, "tokyonight.colors")
    if has_tokyonight then
        local colors = tokyonight_colors.setup()
        local highlights = {
            GitGraphHash = { fg = colors.purple },
            GitGraphTimestamp = { fg = colors.blue2 },
            GitGraphAuthor = { fg = colors.green },
            GitGraphBranchName = { fg = colors.magenta },
            GitGraphBranchTag = { fg = colors.orange },
            GitGraphBranchMsg = { fg = colors.fg },
            GitGraphBranch1 = { fg = colors.blue },
            GitGraphBranch2 = { fg = colors.magenta },
            GitGraphBranch3 = { fg = colors.green },
            GitGraphBranch4 = { fg = colors.yellow },
            GitGraphBranch5 = { fg = colors.orange },
        }
        for group, hl in pairs(highlights) do
            vim.api.nvim_set_hl(0, group, hl)
        end
    end

    require("gitgraph").setup({
        symbols = {
            merge_commit = "M",
            commit = "*",
        },
        format = {
            timestamp = "%Y-%m-%d %H:%M:%S",
            fields = { "hash", "timestamp", "author", "branch_name", "tag" },
        },
        hooks = {
            -- Check diff of a commit
            on_select_commit = function(commit)
                vim.notify("DiffviewOpen " .. commit.hash .. "^!")
                vim.cmd(":DiffviewOpen " .. commit.hash .. "^!")
            end,
            -- Check diff from commit a -> commit b
            on_select_range_commit = function(from, to)
                vim.notify("DiffviewOpen " .. from.hash .. "~1.." .. to.hash)
                vim.cmd(":DiffviewOpen " .. from.hash .. "~1.." .. to.hash)
            end,
        },
    })

    vim.api.nvim_create_user_command("RkGitGraph", function()
        M.open_gitgraph()
    end, { desc = "Rookie GitGraph - Draw" })

    vim.api.nvim_create_user_command("Gg", function()
        M.open_gitgraph()
    end, { desc = "Rookie GitGraph - Draw" })
end

return M
