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
local function make_request(endpoint)
    if vim.g.gitlab_token == nil or vim.g.gitlab_token == "" then
        vim.notify("[RkGitlab] Token is not set. Please set vim.g.gitlab_token", vim.log.levels.ERROR)
        return nil
    end

    local url = vim.g.gitlab_url .. "/api/v4" .. endpoint
    -- Use vim.fn.system to avoid external dependencies
    local cmd = string.format('curl -s --header "PRIVATE-TOKEN: %s" "%s"', vim.g.gitlab_token, url)

    local stdout = vim.fn.system(cmd)
    if vim.v.shell_error ~= 0 then
        vim.notify("[RkGitlab] API request failed.", vim.log.levels.ERROR)
        return nil
    end

    local success, data = pcall(vim.fn.json_decode, stdout)
    if not success then
        vim.notify("[RkGitlab] Failed to parse API response.", vim.log.levels.ERROR)
        return nil
    end

    if type(data) == "table" and data.message then
        vim.notify("[RkGitlab] API Error: " .. tostring(data.message), vim.log.levels.ERROR)
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
        vim.api.nvim_buf_set_keymap(state.buf, "n", "q", "<cmd>lua require('rookie_toys.rk_gitlab').close()<CR>", opts)
        vim.api.nvim_buf_set_keymap(state.buf, "n", "<CR>", "<cmd>lua require('rookie_toys.rk_gitlab').on_enter()<CR>", opts)
        vim.api.nvim_buf_set_keymap(state.buf, "n", "r", "<cmd>lua require('rookie_toys.rk_gitlab').refresh()<CR>", opts)
        vim.api.nvim_buf_set_keymap(state.buf, "n", "/", "<cmd>lua require('rookie_toys.rk_gitlab').search()<CR>", opts)
        vim.api.nvim_buf_set_keymap(state.buf, "n", "M", "<cmd>lua require('rookie_toys.rk_gitlab').toggle_quick_filter()<CR>", opts)
        vim.api.nvim_buf_set_keymap(state.buf, "n", "<BS>", "<cmd>lua require('rookie_toys.rk_gitlab').go_back()<CR>", opts)
        vim.api.nvim_buf_set_keymap(state.buf, "n", "<C-o>", "<cmd>lua require('rookie_toys.rk_gitlab').go_back()<CR>", opts)
        vim.api.nvim_buf_set_keymap(state.buf, "n", "<C-i>", "<cmd>lua require('rookie_toys.rk_gitlab').go_forward()<CR>", opts)
        vim.api.nvim_buf_set_keymap(state.buf, "n", "g?", "<cmd>lua require('rookie_toys.rk_gitlab').toggle_help()<CR>", opts)
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
            local data = make_request("/projects?membership=true&simple=true&order_by=updated_at&sort=desc&per_page=100")
            state.projects = data or {}

            -- Ensure the list is sorted by modified date (new at top, old at bottom) locally as fallback
            table.sort(state.projects, function(a, b)
                local time_a = a.last_activity_at or a.updated_at or ""
                local time_b = b.last_activity_at or b.updated_at or ""
                return time_a > time_b
            end)
        end

        local lines = { "=== GitLab Projects ===", "" }
        for _, p in ipairs(state.projects) do
            table.insert(lines, string.format("[%d] %s", p.id, p.name_with_namespace))
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
            local data = make_request(string.format("/projects/%d/issues?per_page=100", project_id))
            state.issues[project_id] = data or {}
        end

        local issues = state.issues[project_id]
        local lines = { "=== Issues (Project " .. project_id .. ") ===" }
        if state.filter_text ~= "" then
            table.insert(lines, "Filter: " .. state.filter_text)
        end
        if state.quick_filter_active then
            table.insert(lines, "Quick Filter: [" .. state.quick_filter_pattern .. "]")
        end
        table.insert(lines, "")

        local filter = state.filter_text:lower()
        for _, issue in ipairs(issues) do
            local title = issue.title:lower()
            local author = (type(issue.author) == "table" and issue.author.name or ""):lower()
            local state_str = (issue.state or ""):lower()

            local assignee_names = {}
            if type(issue.assignees) == "table" and #issue.assignees > 0 then
                for _, a in ipairs(issue.assignees) do
                    table.insert(assignee_names, a.name)
                end
            elseif type(issue.assignee) == "table" then
                table.insert(assignee_names, issue.assignee.name)
            end

            local assignee_str = #assignee_names > 0 and table.concat(assignee_names, ", ") or "Unassigned"
            local assignee_lower = assignee_str:lower()

            local quick_match_str = string.format("%s@%s", issue.state, assignee_str)

            local match = true
            if filter ~= "" then
                match = title:find(filter, 1, true) or author:find(filter, 1, true) or state_str:find(filter, 1, true) or assignee_lower:find(filter, 1, true)
            end

            if state.quick_filter_active and state.quick_filter_pattern ~= "" then
                if quick_match_str ~= state.quick_filter_pattern then
                    match = false
                end
            end

            if match then
                table.insert(lines, string.format("#%d [%s@%s] %s", issue.iid, issue.state, assignee_str, issue.title))
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
        local issue = make_request(string.format("/projects/%d/issues/%d", project_id, issue_iid))
        if not issue then
            set_lines({ "Failed to load issue." })
            return
        end

        local notes = make_request(string.format("/projects/%d/issues/%d/notes", project_id, issue_iid))

        local lines = {}
        table.insert(lines, "# " .. issue.title)
        table.insert(lines, "**ID:** " .. issue.iid)
        table.insert(lines, "**Author:** " .. (type(issue.author) == "table" and issue.author.name or "Unknown"))
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
                    table.insert(lines, "### " .. note.author.name .. " (" .. note.created_at .. ")")
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
    if state.current_view ~= "issues" then
        vim.notify("[RkGitlab] Filtering is only available in the issues view", vim.log.levels.INFO)
        return
    end
    vim.ui.input({ prompt = "Filter Issues: ", default = state.filter_text }, function(input)
        if input ~= nil then
            state.filter_text = input
            render_issues(state.selected_project)
        end
    end)
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
    if state.current_view == "projects" and state.forward_view == "issues" and state.selected_project then
        render_issues(state.selected_project)
    elseif state.current_view == "issues" and state.forward_view == "issue_detail" and state.selected_issue then
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
            "Press g?, <BS>, or <C-o> to return to the previous view."
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

-- Setup function to register the command
function M.setup()
    vim.api.nvim_create_user_command("RkGitlabIssue", function()
        create_ui_buffer()
        render_projects()
    end, { desc = "Open GitLab Projects and Issues Browser" })
end

return M
