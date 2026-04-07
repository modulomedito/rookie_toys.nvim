local M = {}

function M.open_gitgraph()
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
            -- If not visible, switch current window to it
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

    -- vim.api.nvim_create_user_command("Gg", function()
    --     require("gitgraph").draw({}, { all = true, max_count = 5000 })
    -- end, { desc = "GitGraph - Draw" })

    vim.api.nvim_create_user_command("RkGitGraph", function()
        M.open_gitgraph()
    end, { desc = "Rookie GitGraph - Draw" })
end

return M
