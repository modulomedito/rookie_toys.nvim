local M = {}

-- Global variables for Authentication
vim.g.gitlab_url = vim.g.gitlab_url or "https://gitlab.com"
vim.g.gitlab_token = vim.g.gitlab_token or ""

-- State Management
local state = {
    projects = nil,
    issues = {},
    current_view = "projects",
    previous_view = nil,
    forward_view = nil,
    selected_project = nil,
    selected_issue = nil,
    filter_text = "",
    quick_filter_active = false,
    quick_filter_pattern = "",
    buf = nil,
    win = nil,
}

-- Make API request using curl
local function make_request(endpoint, method, payload)
    if vim.g.gitlab_token == nil or vim.g.gitlab_token == "" then
        vim.notify(
            "[RkGitlab] Token is not set. Please set vim.g.gitlab_token",
            vim.log.levels.ERROR
        )
        return nil
    end

    local url = vim.g.gitlab_url .. "/api/v4" .. endpoint
    method = method or "GET"

    local cmd = string.format(
        'curl -s -X %s --header "PRIVATE-TOKEN: %s"',
        method,
        vim.g.gitlab_token
    )
    local tmp_file = nil

    if payload then
        tmp_file = vim.fn.tempname()
        local f = io.open(tmp_file, "w")
        if f then
            f:write(vim.fn.json_encode(payload))
            f:close()
            cmd = cmd
                .. string.format(
                    ' --header "Content-Type: application/json" -d "@%s"',
                    tmp_file
                )
        end
    end

    cmd = cmd .. string.format(' "%s"', url)

    local stdout = vim.fn.system(cmd)
    if tmp_file then
        os.remove(tmp_file)
    end

    if vim.v.shell_error ~= 0 then
        vim.notify("[RkGitlab] API request failed.", vim.log.levels.ERROR)
        return nil
    end

    local success, data = pcall(vim.fn.json_decode, stdout)
    if not success then
        if stdout == "" then
            return true
        end
        vim.notify(
            "[RkGitlab] Failed to parse API response.",
            vim.log.levels.ERROR
        )
        return nil
    end

    if type(data) == "table" and data.message then
        vim.notify(
            "[RkGitlab] API Error: " .. tostring(data.message),
            vim.log.levels.ERROR
        )
        return nil
    end

    return data
end

-- Forward declarations
local render_projects
local render_issues
local render_issue_detail

-- Create or focus the UI buffer
local function create_ui_buffer()
    if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
        if state.win and vim.api.nvim_win_is_valid(state.win) then
            vim.api.nvim_set_current_win(state.win)
            return
        end
    else
        state.buf = vim.api.nvim_create_buf(false, true)

        -- Buffer options
        vim.bo[state.buf].buftype = "nofile"
        vim.bo[state.buf].bufhidden = "hide"
        vim.bo[state.buf].swapfile = false
        vim.bo[state.buf].modifiable = false
        vim.bo[state.buf].filetype = "rk_gitlab"

        -- Keymaps
        local opts = { noremap = true, silent = true }
        vim.api.nvim_buf_set_keymap(
            state.buf,
            "n",
            "q",
            "<cmd>lua require('rookie_toys.rk_gitlab').close()<CR>",
            opts
        )
        vim.api.nvim_buf_set_keymap(
            state.buf,
            "n",
            "<CR>",
            "<cmd>lua require('rookie_toys.rk_gitlab').on_enter()<CR>",
            opts
        )
        vim.api.nvim_buf_set_keymap(
            state.buf,
            "n",
            "r",
            "<cmd>lua require('rookie_toys.rk_gitlab').refresh()<CR>",
            opts
        )
        vim.api.nvim_buf_set_keymap(
            state.buf,
            "n",
            "/",
            "<cmd>lua require('rookie_toys.rk_gitlab').search()<CR>",
            opts
        )
        vim.api.nvim_buf_set_keymap(
            state.buf,
            "n",
            "M",
            "<cmd>lua require('rookie_toys.rk_gitlab').toggle_quick_filter()<CR>",
            opts
        )
        vim.api.nvim_buf_set_keymap(
            state.buf,
            "n",
            "<BS>",
            "<cmd>lua require('rookie_toys.rk_gitlab').go_back()<CR>",
            opts
        )
        vim.api.nvim_buf_set_keymap(
            state.buf,
            "n",
            "<C-o>",
            "<cmd>lua require('rookie_toys.rk_gitlab').go_back()<CR>",
            opts
        )
        vim.api.nvim_buf_set_keymap(
            state.buf,
            "n",
            "<C-i>",
            "<cmd>lua require('rookie_toys.rk_gitlab').go_forward()<CR>",
            opts
        )
        vim.api.nvim_buf_set_keymap(
            state.buf,
            "n",
            "g?",
            "<cmd>lua require('rookie_toys.rk_gitlab').toggle_help()<CR>",
            opts
        )
    end

    local width = math.floor(vim.o.columns * 0.8)
    local height = math.floor(vim.o.lines * 0.8)
    local col = math.floor((vim.o.columns - width) / 2)
    local row = math.floor((vim.o.lines - height) / 2)

    local win_opts = {
        relative = "editor",
        width = width,
        height = height,
        col = col,
        row = row,
        style = "minimal",
        border = "rounded",
        title = " GitLab ",
        title_pos = "center",
    }

    state.win = vim.api.nvim_open_win(state.buf, true, win_opts)
end

local function set_lines(lines)
    if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
        vim.bo[state.buf].modifiable = true
        vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
        vim.bo[state.buf].modifiable = false
    end
end

render_projects = function()
    state.current_view = "projects"
    set_lines({ "Loading projects..." })

    vim.defer_fn(function()
        if not state.projects then
            local data = make_request(
                "/projects?membership=true&simple=true&order_by=updated_at&sort=desc&per_page=100"
            )
            state.projects = data or {}

            -- Ensure the list is sorted by modified date (new at top, old at bottom) locally as fallback
            table.sort(state.projects, function(a, b)
                local time_a = a.last_activity_at or a.updated_at or ""
                local time_b = b.last_activity_at or b.updated_at or ""
                return time_a > time_b
            end)
        end

        local lines = { "=== GitLab Projects ===" }
        if state.filter_text ~= "" then
            table.insert(lines, "Filter: " .. state.filter_text)
        end
        table.insert(lines, "")

        local filter = state.filter_text:lower()
        for _, p in ipairs(state.projects) do
            local match = true
            if filter ~= "" then
                local name = p.name_with_namespace:lower()
                match = name:find(filter, 1, true)
            end

            if match then
                table.insert(
                    lines,
                    string.format("[%d] %s", p.id, p.name_with_namespace)
                )
            end
        end

        set_lines(lines)
    end, 10)
end

render_issues = function(project_id)
    state.current_view = "issues"
    state.selected_project = project_id
    set_lines({ "Loading issues..." })

    vim.defer_fn(function()
        if not state.issues[project_id] then
            local data = make_request(
                string.format("/projects/%d/issues?per_page=100", project_id)
            )
            state.issues[project_id] = data or {}
        end

        local issues = state.issues[project_id]
        local lines = { "=== Issues (Project " .. project_id .. ") ===" }
        if state.filter_text ~= "" then
            table.insert(lines, "Filter: " .. state.filter_text)
        end
        if state.quick_filter_active then
            table.insert(
                lines,
                "Quick Filter: [" .. state.quick_filter_pattern .. "]"
            )
        end
        table.insert(lines, "")

        local filter = state.filter_text:lower()
        for _, issue in ipairs(issues) do
            local title = issue.title:lower()
            local author = (
                type(issue.author) == "table" and issue.author.name or ""
            ):lower()
            local state_str = (issue.state or ""):lower()

            local assignee_names = {}
            if type(issue.assignees) == "table" and #issue.assignees > 0 then
                for _, a in ipairs(issue.assignees) do
                    table.insert(assignee_names, a.name)
                end
            elseif type(issue.assignee) == "table" then
                table.insert(assignee_names, issue.assignee.name)
            end

            local assignee_str = #assignee_names > 0
                    and table.concat(assignee_names, ", ")
                or "Unassigned"
            local assignee_lower = assignee_str:lower()

            local quick_match_str =
                string.format("%s@%s", issue.state, assignee_str)

            local match = true
            if filter ~= "" then
                match = title:find(filter, 1, true)
                    or author:find(filter, 1, true)
                    or state_str:find(filter, 1, true)
                    or assignee_lower:find(filter, 1, true)
            end

            if
                state.quick_filter_active
                and state.quick_filter_pattern ~= ""
            then
                if quick_match_str ~= state.quick_filter_pattern then
                    match = false
                end
            end

            if match then
                table.insert(
                    lines,
                    string.format(
                        "#%d [%s@%s] %s",
                        issue.iid,
                        issue.state,
                        assignee_str,
                        issue.title
                    )
                )
            end
        end

        set_lines(lines)
    end, 10)
end

render_issue_detail = function(issue_iid)
    state.current_view = "issue_detail"
    local project_id = state.selected_project

    set_lines({ "Loading issue details..." })

    vim.defer_fn(function()
        local issue = make_request(
            string.format("/projects/%d/issues/%d", project_id, issue_iid)
        )
        if not issue then
            set_lines({ "Failed to load issue." })
            return
        end

        local notes = make_request(
            string.format("/projects/%d/issues/%d/notes", project_id, issue_iid)
        )

        local lines = {}
        table.insert(lines, "# " .. issue.title)
        table.insert(lines, "**ID:** " .. issue.iid)
        table.insert(
            lines,
            "**Author:** "
                .. (
                    type(issue.author) == "table" and issue.author.name
                    or "Unknown"
                )
        )
        table.insert(lines, "**State:** " .. issue.state)
        table.insert(lines, "**Created:** " .. issue.created_at)

        local labels_str = ""
        if issue.labels and #issue.labels > 0 then
            labels_str = table.concat(issue.labels, ", ")
        else
            labels_str = "None"
        end
        table.insert(lines, "**Labels:** " .. labels_str)

        local assignee_str = "Unassigned"
        if type(issue.assignees) == "table" and #issue.assignees > 0 then
            local assignees = {}
            for _, a in ipairs(issue.assignees) do
                table.insert(assignees, a.name)
            end
            assignee_str = table.concat(assignees, ", ")
        elseif type(issue.assignee) == "table" then
            assignee_str = issue.assignee.name
        end
        table.insert(lines, "**Assignee:** " .. assignee_str)
        table.insert(lines, "")

        table.insert(lines, "## Description")
        if issue.description and issue.description ~= "" then
            for s in issue.description:gmatch("[^\r\n]+") do
                table.insert(lines, s)
            end
        else
            table.insert(lines, "*No description provided.*")
        end

        table.insert(lines, "")
        table.insert(lines, "## Comments")
        if notes and #notes > 0 then
            for _, note in ipairs(notes) do
                if not note.system then
                    table.insert(
                        lines,
                        "### "
                            .. note.author.name
                            .. " ("
                            .. note.created_at
                            .. ")"
                    )
                    for s in note.body:gmatch("[^\r\n]+") do
                        table.insert(lines, s)
                    end
                    table.insert(lines, "")
                end
            end
        else
            table.insert(lines, "*No comments.*")
        end

        set_lines(lines)
        if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
            vim.bo[state.buf].filetype = "markdown"
        end
    end, 10)
end

-- Actions exported for keymaps
function M.close()
    if state.win and vim.api.nvim_win_is_valid(state.win) then
        vim.api.nvim_win_close(state.win, true)
        state.win = nil
    end
end

function M.toggle()
    if state.win and vim.api.nvim_win_is_valid(state.win) then
        vim.api.nvim_win_close(state.win, true)
        state.win = nil
    else
        local is_new = not (state.buf and vim.api.nvim_buf_is_valid(state.buf))
        create_ui_buffer()
        if is_new then
            render_projects()
        end
    end
end

function M.refresh()
    if state.current_view == "projects" then
        state.projects = nil
        render_projects()
    elseif state.current_view == "issues" then
        state.issues[state.selected_project] = nil
        render_issues(state.selected_project)
    end
end

function M.search()
    if state.current_view ~= "issues" and state.current_view ~= "projects" then
        vim.notify(
            "[RkGitlab] Filtering is only available in projects or issues view",
            vim.log.levels.INFO
        )
        return
    end
    local prompt = state.current_view == "projects" and "Filter Projects: "
        or "Filter Issues: "
    vim.ui.input(
        { prompt = prompt, default = state.filter_text },
        function(input)
            if input ~= nil then
                state.filter_text = input
                if state.current_view == "projects" then
                    render_projects()
                else
                    render_issues(state.selected_project)
                end
            end
        end
    )
end

function M.toggle_quick_filter()
    if state.current_view ~= "issues" then
        return
    end

    if state.quick_filter_active then
        state.quick_filter_active = false
        state.quick_filter_pattern = ""
        render_issues(state.selected_project)
        return
    end

    local line = vim.api.nvim_get_current_line()
    local pattern = line:match("%[([^%]]+@[^%]]+)%]")
    if pattern then
        state.quick_filter_pattern = pattern
        state.quick_filter_active = true
        render_issues(state.selected_project)
    end
end

function M.go_back()
    if state.current_view == "help" then
        M.toggle_help()
    elseif state.current_view == "issue_detail" then
        if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
            vim.bo[state.buf].filetype = "rk_gitlab"
        end
        state.forward_view = "issue_detail"
        render_issues(state.selected_project)
    elseif state.current_view == "issues" then
        state.forward_view = "issues"
        state.filter_text = ""
        render_projects()
    end
end

function M.go_forward()
    if
        state.current_view == "projects"
        and state.forward_view == "issues"
        and state.selected_project
    then
        render_issues(state.selected_project)
    elseif
        state.current_view == "issues"
        and state.forward_view == "issue_detail"
        and state.selected_issue
    then
        render_issue_detail(state.selected_issue)
    end
end

function M.toggle_help()
    if state.current_view == "help" then
        state.current_view = state.previous_view
        if state.current_view == "projects" then
            render_projects()
        elseif state.current_view == "issues" then
            render_issues(state.selected_project)
        end
    else
        state.previous_view = state.current_view
        state.current_view = "help"
        local lines = {
            "=== RkGitlab Keymaps ===",
            "",
            "  <CR>      : Open Project / View Issue Details",
            "  <BS>/<C-o>: Go back",
            "  <C-i>     : Go forward",
            "  /         : Search / Filter Issues",
            "  M         : Toggle quick filter for [state@assignee]",
            "  r         : Refresh current view",
            "  q         : Close window",
            "  g?        : Toggle this help menu",
            "",
            "Press g?, <BS>, or <C-o> to return to the previous view.",
        }
        set_lines(lines)
    end
end

function M.on_enter()
    local line = vim.api.nvim_get_current_line()
    if state.current_view == "projects" then
        local id_str = line:match("%[(%d+)%]")
        if id_str then
            state.forward_view = nil
            state.filter_text = "" -- Clear project filter when entering issues
            render_issues(tonumber(id_str))
        end
    elseif state.current_view == "issues" then
        local iid_str = line:match("^#(%d+)")
        if iid_str then
            state.forward_view = nil
            state.selected_issue = tonumber(iid_str)
            render_issue_detail(tonumber(iid_str))
        end
    end
end

function M.close_issue()
    if
        state.current_view ~= "issue_detail"
        or not state.selected_project
        or not state.selected_issue
    then
        vim.notify("[RkGitlab] No issue currently open", vim.log.levels.WARN)
        return
    end

    local res = make_request(
        string.format(
            "/projects/%d/issues/%d",
            state.selected_project,
            state.selected_issue
        ),
        "PUT",
        { state_event = "close" }
    )
    if res then
        vim.notify(
            string.format("[RkGitlab] Issue #%d closed", state.selected_issue),
            vim.log.levels.INFO
        )
        -- Invalidate issues cache for this project so it refreshes when we go back
        state.issues[state.selected_project] = nil
        render_issue_detail(state.selected_issue)
    end
end

function M.open_issue()
    if
        state.current_view ~= "issue_detail"
        or not state.selected_project
        or not state.selected_issue
    then
        vim.notify("[RkGitlab] No issue currently open", vim.log.levels.WARN)
        return
    end

    local res = make_request(
        string.format(
            "/projects/%d/issues/%d",
            state.selected_project,
            state.selected_issue
        ),
        "PUT",
        { state_event = "reopen" }
    )
    if res then
        vim.notify(
            string.format("[RkGitlab] Issue #%d reopened", state.selected_issue),
            vim.log.levels.INFO
        )
        -- Invalidate issues cache for this project so it refreshes when we go back
        state.issues[state.selected_project] = nil
        render_issue_detail(state.selected_issue)
    end
end

function M.comment_issue()
    if
        state.current_view ~= "issue_detail"
        or not state.selected_project
        or not state.selected_issue
    then
        vim.notify("[RkGitlab] No issue currently open", vim.log.levels.WARN)
        return
    end

    local project_id = state.selected_project
    local issue_iid = state.selected_issue

    local buf = vim.api.nvim_create_buf(false, true)
    vim.bo[buf].buftype = "acwrite"
    vim.bo[buf].filetype = "markdown"
    vim.bo[buf].bufhidden = "wipe"

    local tmp_name =
        string.format("gitlab_comment_%d_%d.md", project_id, issue_iid)
    pcall(vim.api.nvim_buf_set_name, buf, tmp_name)

    local instructions = {
        "",
        "<!-- Please enter your comment above. -->",
        "<!-- Empty or unchanged comments will be aborted. -->",
        string.format("<!-- Issue #%d -->", issue_iid),
    }
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, instructions)

    local width = math.floor(vim.o.columns * 0.6)
    local height = math.floor(vim.o.lines * 0.6)
    local col = math.floor((vim.o.columns - width) / 2)
    local row = math.floor((vim.o.lines - height) / 2)

    local win_opts = {
        relative = "editor",
        width = width,
        height = height,
        col = col,
        row = row,
        style = "minimal",
        border = "rounded",
        title = string.format(" Comment on Issue #%d ", issue_iid),
        title_pos = "center",
    }

    vim.api.nvim_open_win(buf, true, win_opts)
    vim.api.nvim_win_set_cursor(0, { 1, 0 })

    local submitted_body = nil

    vim.api.nvim_create_autocmd("BufWriteCmd", {
        buffer = buf,
        callback = function()
            local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
            local comment_lines = {}
            for _, line in ipairs(lines) do
                if not line:match("^<!%-%-.*%-%->$") then
                    table.insert(comment_lines, line)
                end
            end

            local body = table.concat(comment_lines, "\n")
            body = body:gsub("^%s+", ""):gsub("%s+$", "")

            if body == "" then
                submitted_body = nil
                vim.notify(
                    "[RkGitlab] Comment empty, will abort on exit.",
                    vim.log.levels.WARN
                )
            else
                submitted_body = body
                vim.notify(
                    "[RkGitlab] Comment saved. Exit buffer to submit.",
                    vim.log.levels.INFO
                )
            end
            vim.bo[buf].modified = false
        end,
    })

    vim.api.nvim_create_autocmd("BufDelete", {
        buffer = buf,
        callback = function()
            if submitted_body and submitted_body ~= "" then
                local res = make_request(
                    string.format(
                        "/projects/%d/issues/%d/notes",
                        project_id,
                        issue_iid
                    ),
                    "POST",
                    { body = submitted_body }
                )
                if res then
                    vim.notify(
                        string.format(
                            "[RkGitlab] Comment added to Issue #%d",
                            issue_iid
                        ),
                        vim.log.levels.INFO
                    )
                    if
                        state.current_view == "issue_detail"
                        and state.selected_issue == issue_iid
                    then
                        -- Use schedule to avoid issues during buffer deletion
                        vim.schedule(function()
                            render_issue_detail(issue_iid)
                        end)
                    end
                else
                    vim.notify(
                        "[RkGitlab] Failed to add comment",
                        vim.log.levels.ERROR
                    )
                end
            else
                vim.notify("[RkGitlab] Comment aborted.", vim.log.levels.INFO)
            end
        end,
    })
end

function M.add_issue(edit_iid)
    if not state.selected_project then
        vim.notify(
            "[RkGitlab] Please select a project first to create or edit an issue",
            vim.log.levels.WARN
        )
        return
    end

    local project_id = state.selected_project
    local is_edit = (edit_iid ~= nil)

    local buf_title = vim.api.nvim_create_buf(false, true)
    local buf_desc = vim.api.nvim_create_buf(false, true)
    local buf_flags = vim.api.nvim_create_buf(false, true)

    for _, b in ipairs({ buf_title, buf_desc, buf_flags }) do
        vim.bo[b].buftype = "acwrite"
        vim.bo[b].filetype = "markdown"
        vim.bo[b].bufhidden = "wipe"
    end

    if is_edit then
        pcall(
            vim.api.nvim_buf_set_name,
            buf_title,
            string.format("gitlab_issue_title_%d_%d.md", project_id, edit_iid)
        )
        pcall(
            vim.api.nvim_buf_set_name,
            buf_desc,
            string.format("gitlab_issue_desc_%d_%d.md", project_id, edit_iid)
        )
        pcall(
            vim.api.nvim_buf_set_name,
            buf_flags,
            string.format("gitlab_issue_flags_%d_%d.md", project_id, edit_iid)
        )
    else
        pcall(
            vim.api.nvim_buf_set_name,
            buf_title,
            string.format("gitlab_issue_title_%d.md", project_id)
        )
        pcall(
            vim.api.nvim_buf_set_name,
            buf_desc,
            string.format("gitlab_issue_desc_%d.md", project_id)
        )
        pcall(
            vim.api.nvim_buf_set_name,
            buf_flags,
            string.format("gitlab_issue_flags_%d.md", project_id)
        )
    end

    vim.api.nvim_buf_set_lines(buf_title, 0, -1, false, { "" })
    vim.api.nvim_buf_set_lines(
        buf_desc,
        0,
        -1,
        false,
        { "", "<!-- Issue Description -->" }
    )
    vim.api.nvim_buf_set_lines(
        buf_flags,
        0,
        -1,
        false,
        {
            "",
            "<!-- /assign @user, /reassign, /label bug, see https://docs.gitlab.com/user/project/quick_actions/ -->",
        }
    )

    if is_edit then
        local issue = make_request(
            string.format("/projects/%d/issues/%d", project_id, edit_iid)
        )
        if issue then
            vim.api.nvim_buf_set_lines(buf_title, 0, -1, false, { issue.title })
            if issue.description then
                local desc_lines = vim.split(issue.description, "\n")
                table.insert(desc_lines, "")
                table.insert(desc_lines, "<!-- Issue Description -->")
                vim.api.nvim_buf_set_lines(buf_desc, 0, -1, false, desc_lines)
            end
        end
    end

    local total_width = math.floor(vim.o.columns * 0.6)
    local total_height = math.floor(vim.o.lines * 0.8)
    local base_col = math.floor((vim.o.columns - total_width) / 2)
    local base_row = math.floor((vim.o.lines - total_height) / 2)

    local title_h = 1
    local flags_h = 3
    local desc_h = total_height - title_h - flags_h - 4

    local win_title = vim.api.nvim_open_win(buf_title, true, {
        relative = "editor",
        width = total_width,
        height = title_h,
        col = base_col,
        row = base_row,
        style = "minimal",
        border = "rounded",
        title = " Title ",
        title_pos = "center",
    })

    local win_desc = vim.api.nvim_open_win(buf_desc, true, {
        relative = "editor",
        width = total_width,
        height = desc_h,
        col = base_col,
        row = base_row + title_h + 2,
        style = "minimal",
        border = "rounded",
        title = " Description ",
        title_pos = "center",
    })

    local win_flags = vim.api.nvim_open_win(buf_flags, true, {
        relative = "editor",
        width = total_width,
        height = flags_h,
        col = base_col,
        row = base_row + title_h + 2 + desc_h + 2,
        style = "minimal",
        border = "rounded",
        title = " Flags ",
        title_pos = "center",
    })

    local confirm_w = math.floor((total_width - 2) / 2)
    local cancel_w = total_width - 2 - confirm_w

    local buf_confirm = vim.api.nvim_create_buf(false, true)
    local buf_cancel = vim.api.nvim_create_buf(false, true)

    vim.bo[buf_confirm].buftype = "nofile"
    vim.bo[buf_confirm].filetype = "markdown"
    vim.bo[buf_confirm].bufhidden = "wipe"

    vim.bo[buf_cancel].buftype = "nofile"
    vim.bo[buf_cancel].filetype = "markdown"
    vim.bo[buf_cancel].bufhidden = "wipe"

    local function center_text(text, width)
        local padding = width - #text
        if padding <= 0 then
            return text
        end
        local left = math.floor(padding / 2)
        local right = padding - left
        return string.rep(" ", left) .. text .. string.rep(" ", right)
    end

    vim.api.nvim_buf_set_lines(
        buf_confirm,
        0,
        -1,
        false,
        { center_text("Confirm", confirm_w) }
    )
    vim.api.nvim_buf_set_lines(
        buf_cancel,
        0,
        -1,
        false,
        { center_text("Cancel", cancel_w) }
    )

    local win_confirm = vim.api.nvim_open_win(buf_confirm, true, {
        relative = "editor",
        width = confirm_w,
        height = 1,
        col = base_col,
        row = base_row + title_h + 2 + desc_h + 2 + flags_h + 2,
        style = "minimal",
        border = "rounded",
    })

    local win_cancel = vim.api.nvim_open_win(buf_cancel, true, {
        relative = "editor",
        width = cancel_w,
        height = 1,
        col = base_col + confirm_w + 2,
        row = base_row + title_h + 2 + desc_h + 2 + flags_h + 2,
        style = "minimal",
        border = "rounded",
    })

    -- Add keymaps for window navigation
    local opts = { noremap = true, silent = true }

    -- title buffer
    vim.api.nvim_buf_set_keymap(
        buf_title,
        "n",
        "<C-w>j",
        string.format("<cmd>lua vim.api.nvim_set_current_win(%d)<CR>", win_desc),
        opts
    )
    vim.api.nvim_buf_set_keymap(
        buf_title,
        "n",
        "<C-w>k",
        string.format(
            "<cmd>lua vim.api.nvim_set_current_win(%d)<CR>",
            win_flags
        ),
        opts
    )
    vim.api.nvim_buf_set_keymap(
        buf_title,
        "n",
        "<C-j>",
        string.format("<cmd>lua vim.api.nvim_set_current_win(%d)<CR>", win_desc),
        opts
    )
    vim.api.nvim_buf_set_keymap(
        buf_title,
        "n",
        "<C-k>",
        string.format(
            "<cmd>lua vim.api.nvim_set_current_win(%d)<CR>",
            win_flags
        ),
        opts
    )

    -- desc buffer
    vim.api.nvim_buf_set_keymap(
        buf_desc,
        "n",
        "<C-w>j",
        string.format(
            "<cmd>lua vim.api.nvim_set_current_win(%d)<CR>",
            win_flags
        ),
        opts
    )
    vim.api.nvim_buf_set_keymap(
        buf_desc,
        "n",
        "<C-w>k",
        string.format(
            "<cmd>lua vim.api.nvim_set_current_win(%d)<CR>",
            win_title
        ),
        opts
    )
    vim.api.nvim_buf_set_keymap(
        buf_desc,
        "n",
        "<C-j>",
        string.format(
            "<cmd>lua vim.api.nvim_set_current_win(%d)<CR>",
            win_flags
        ),
        opts
    )
    vim.api.nvim_buf_set_keymap(
        buf_desc,
        "n",
        "<C-k>",
        string.format(
            "<cmd>lua vim.api.nvim_set_current_win(%d)<CR>",
            win_title
        ),
        opts
    )

    -- flags buffer
    vim.api.nvim_buf_set_keymap(
        buf_flags,
        "n",
        "<C-w>j",
        string.format(
            "<cmd>lua vim.api.nvim_set_current_win(%d)<CR>",
            win_confirm
        ),
        opts
    )
    vim.api.nvim_buf_set_keymap(
        buf_flags,
        "n",
        "<C-w>k",
        string.format("<cmd>lua vim.api.nvim_set_current_win(%d)<CR>", win_desc),
        opts
    )
    vim.api.nvim_buf_set_keymap(
        buf_flags,
        "n",
        "<C-j>",
        string.format(
            "<cmd>lua vim.api.nvim_set_current_win(%d)<CR>",
            win_confirm
        ),
        opts
    )
    vim.api.nvim_buf_set_keymap(
        buf_flags,
        "n",
        "<C-k>",
        string.format("<cmd>lua vim.api.nvim_set_current_win(%d)<CR>", win_desc),
        opts
    )

    -- confirm buffer
    vim.api.nvim_buf_set_keymap(
        buf_confirm,
        "n",
        "<C-w>k",
        string.format(
            "<cmd>lua vim.api.nvim_set_current_win(%d)<CR>",
            win_flags
        ),
        opts
    )
    vim.api.nvim_buf_set_keymap(
        buf_confirm,
        "n",
        "<C-k>",
        string.format(
            "<cmd>lua vim.api.nvim_set_current_win(%d)<CR>",
            win_flags
        ),
        opts
    )
    vim.api.nvim_buf_set_keymap(
        buf_confirm,
        "n",
        "<C-w>j",
        string.format(
            "<cmd>lua vim.api.nvim_set_current_win(%d)<CR>",
            win_title
        ),
        opts
    )
    vim.api.nvim_buf_set_keymap(
        buf_confirm,
        "n",
        "<C-j>",
        string.format(
            "<cmd>lua vim.api.nvim_set_current_win(%d)<CR>",
            win_title
        ),
        opts
    )
    vim.api.nvim_buf_set_keymap(
        buf_confirm,
        "n",
        "<C-w>l",
        string.format(
            "<cmd>lua vim.api.nvim_set_current_win(%d)<CR>",
            win_cancel
        ),
        opts
    )
    vim.api.nvim_buf_set_keymap(
        buf_confirm,
        "n",
        "<C-l>",
        string.format(
            "<cmd>lua vim.api.nvim_set_current_win(%d)<CR>",
            win_cancel
        ),
        opts
    )

    -- cancel buffer
    vim.api.nvim_buf_set_keymap(
        buf_cancel,
        "n",
        "<C-w>k",
        string.format(
            "<cmd>lua vim.api.nvim_set_current_win(%d)<CR>",
            win_flags
        ),
        opts
    )
    vim.api.nvim_buf_set_keymap(
        buf_cancel,
        "n",
        "<C-k>",
        string.format(
            "<cmd>lua vim.api.nvim_set_current_win(%d)<CR>",
            win_flags
        ),
        opts
    )
    vim.api.nvim_buf_set_keymap(
        buf_cancel,
        "n",
        "<C-w>j",
        string.format(
            "<cmd>lua vim.api.nvim_set_current_win(%d)<CR>",
            win_title
        ),
        opts
    )
    vim.api.nvim_buf_set_keymap(
        buf_cancel,
        "n",
        "<C-j>",
        string.format(
            "<cmd>lua vim.api.nvim_set_current_win(%d)<CR>",
            win_title
        ),
        opts
    )
    vim.api.nvim_buf_set_keymap(
        buf_cancel,
        "n",
        "<C-w>h",
        string.format(
            "<cmd>lua vim.api.nvim_set_current_win(%d)<CR>",
            win_confirm
        ),
        opts
    )
    vim.api.nvim_buf_set_keymap(
        buf_cancel,
        "n",
        "<C-h>",
        string.format(
            "<cmd>lua vim.api.nvim_set_current_win(%d)<CR>",
            win_confirm
        ),
        opts
    )

    vim.api.nvim_set_current_win(win_title)

    local submitted_data = nil

    local function save_action()
        local title_lines = vim.api.nvim_buf_get_lines(buf_title, 0, -1, false)
        local desc_lines = vim.api.nvim_buf_get_lines(buf_desc, 0, -1, false)
        local flags_lines = vim.api.nvim_buf_get_lines(buf_flags, 0, -1, false)

        local title =
            table.concat(title_lines, ""):gsub("^%s+", ""):gsub("%s+$", "")

        local clean_desc = {}
        for _, line in ipairs(desc_lines) do
            if not line:match("^<!%-%-.*%-%->$") then
                table.insert(clean_desc, line)
            end
        end
        local desc =
            table.concat(clean_desc, "\n"):gsub("^%s+", ""):gsub("%s+$", "")

        local clean_flags = {}
        for _, line in ipairs(flags_lines) do
            if not line:match("^<!%-%-.*%-%->$") then
                table.insert(clean_flags, line)
            end
        end
        local flags =
            table.concat(clean_flags, "\n"):gsub("^%s+", ""):gsub("%s+$", "")

        if title == "" then
            submitted_data = nil
            vim.notify(
                "[RkGitlab] Title empty, will abort on exit.",
                vim.log.levels.WARN
            )
        else
            local full_desc = desc
            if flags ~= "" then
                full_desc = full_desc .. "\n\n" .. flags
            end
            submitted_data = { title = title, description = full_desc }
            vim.notify(
                "[RkGitlab] Issue saved. Exit any buffer to submit.",
                vim.log.levels.INFO
            )
        end

        pcall(function()
            vim.bo[buf_title].modified = false
        end)
        pcall(function()
            vim.bo[buf_desc].modified = false
        end)
        pcall(function()
            vim.bo[buf_flags].modified = false
        end)
    end

    local is_submitting = false
    local function close_action()
        if is_submitting then
            return
        end
        is_submitting = true

        for _, w in ipairs({
            win_title,
            win_desc,
            win_flags,
            win_confirm,
            win_cancel,
        }) do
            if vim.api.nvim_win_is_valid(w) then
                pcall(vim.api.nvim_win_close, w, true)
            end
        end

        if submitted_data and submitted_data.title ~= "" then
            local res = nil
            if is_edit then
                res = make_request(
                    string.format(
                        "/projects/%d/issues/%d",
                        project_id,
                        edit_iid
                    ),
                    "PUT",
                    submitted_data
                )
            else
                res = make_request(
                    string.format("/projects/%d/issues", project_id),
                    "POST",
                    submitted_data
                )
            end

            if res then
                local action_str = is_edit and "updated" or "created"
                vim.notify(
                    string.format(
                        "[RkGitlab] Issue '%s' %s",
                        submitted_data.title,
                        action_str
                    ),
                    vim.log.levels.INFO
                )
                state.issues[project_id] = nil
                if
                    state.current_view == "issues"
                    or state.current_view == "projects"
                then
                    vim.schedule(function()
                        render_issues(project_id)
                    end)
                end
            else
                local action_str = is_edit and "update" or "create"
                vim.notify(
                    "[RkGitlab] Failed to " .. action_str .. " issue",
                    vim.log.levels.ERROR
                )
            end
        else
            local action_str = is_edit and "update" or "creation"
            vim.notify(
                "[RkGitlab] Issue " .. action_str .. " aborted.",
                vim.log.levels.INFO
            )
        end

        if state.win and vim.api.nvim_win_is_valid(state.win) then
            pcall(vim.api.nvim_set_current_win, state.win)
        end
    end

    -- Add Enter keymap to Confirm and Cancel
    vim.api.nvim_buf_set_keymap(buf_confirm, "n", "<CR>", "", {
        noremap = true,
        silent = true,
        callback = function()
            save_action()
            vim.schedule(close_action)
        end,
    })

    vim.api.nvim_buf_set_keymap(buf_cancel, "n", "<CR>", "", {
        noremap = true,
        silent = true,
        callback = function()
            submitted_data = nil
            vim.schedule(close_action)
        end,
    })

    for _, b in ipairs({ buf_title, buf_desc, buf_flags }) do
        vim.api.nvim_create_autocmd("BufWriteCmd", {
            buffer = b,
            callback = save_action,
        })
        vim.api.nvim_create_autocmd("BufDelete", {
            buffer = b,
            callback = function()
                vim.schedule(close_action)
            end,
        })
    end
end

function M.edit_issue()
    if state.current_view ~= "issues" then
        vim.notify(
            "[RkGitlab] Please edit an issue from the issues view",
            vim.log.levels.WARN
        )
        return
    end

    local line = vim.api.nvim_get_current_line()
    local iid_str = line:match("^#(%d+)")

    if not iid_str then
        vim.notify(
            "[RkGitlab] No issue found under cursor",
            vim.log.levels.WARN
        )
        return
    end

    M.add_issue(tonumber(iid_str))
end

-- Setup function to register the command
function M.setup()
    vim.api.nvim_create_user_command("RkGitlabIssue", function(opts)
        local args = opts.fargs
        if #args == 0 then
            create_ui_buffer()
            render_projects()
        else
            local action = args[1]
            if action == "close" then
                M.close_issue()
            elseif action == "open" then
                M.open_issue()
            elseif action == "comment" then
                M.comment_issue()
            elseif action == "add" then
                M.add_issue()
            elseif action == "edit" then
                M.edit_issue()
            elseif action == "toggle" then
                M.toggle()
            else
                vim.notify(
                    "[RkGitlab] Unknown action: " .. action,
                    vim.log.levels.ERROR
                )
            end
        end
    end, {
        nargs = "*",
        desc = "Open GitLab Projects and Issues Browser or perform actions",
        complete = function()
            return { "open", "close", "comment", "add", "edit", "toggle" }
        end,
    })

    vim.keymap.set("n", "<leader>gl", "<cmd>RkGitlabIssue toggle<CR>", {
        silent = true,
    })
end

return M
