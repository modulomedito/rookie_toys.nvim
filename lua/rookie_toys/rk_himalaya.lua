local M = {}

-- State
local state = {
    buf = nil,
    win = nil,
    last_list_args = "",
}

local function create_term_buf(cmd, title)
    if vim.fn.executable("himalaya") == 0 then
        vim.notify(
            "himalaya CLI not found. Please install it first.",
            vim.log.levels.ERROR
        )
        return
    end

    if state.win and vim.api.nvim_win_is_valid(state.win) then
        vim.api.nvim_win_close(state.win, true)
    end
    if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
        vim.api.nvim_buf_delete(state.buf, { force = true })
    end

    state.buf = vim.api.nvim_create_buf(false, true)

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
        title = " " .. (title or "Himalaya") .. " ",
        title_pos = "center",
    }

    state.win = vim.api.nvim_open_win(state.buf, true, win_opts)

    -- Mappings
    vim.keymap.set("n", "q", function()
        if state.win and vim.api.nvim_win_is_valid(state.win) then
            vim.api.nvim_win_close(state.win, true)
        end
    end, { buffer = state.buf, silent = true, desc = "Close Himalaya" })

    vim.keymap.set("n", "<CR>", function()
        local line = vim.api.nvim_get_current_line()
        local id = line:match("^%s*(%d+)")
        if id then
            M.read_email(id)
        end
    end, { buffer = state.buf, silent = true, desc = "Read Email" })

    vim.keymap.set("n", "u", function()
        M.list_envelopes(state.last_list_args)
    end, { buffer = state.buf, silent = true, desc = "Back to List" })

    vim.fn.termopen(cmd, {
        on_exit = function()
            -- Switch to normal mode on exit to allow mappings like 'q' and 'Enter'
            vim.cmd("stopinsert")
        end,
    })

    vim.cmd("startinsert")
end

function M.read_email(id)
    create_term_buf("himalaya message read " .. id, "Himalaya Read " .. id)
end

function M.list_envelopes(args)
    state.last_list_args = args or ""
    create_term_buf("himalaya envelope list " .. state.last_list_args, "Himalaya List")
end

function M.setup()
    -- Commands
    vim.api.nvim_create_user_command(
        "RkHimalaya",
        function(opts)
            local cmd = "himalaya"
            if opts.args ~= "" then
                cmd = cmd .. " " .. opts.args
            end
            create_term_buf(cmd, "Himalaya")
        end,
        { nargs = "*", desc = "Run himalaya CLI command in floating terminal" }
    )

    vim.api.nvim_create_user_command("RkHimalayaList", function(opts)
        M.list_envelopes(opts.args)
    end, { nargs = "*", desc = "List himalaya envelopes" })

    vim.api.nvim_create_user_command("RkHimalayaRead", function(opts)
        if opts.args == "" then
            vim.notify("Please provide a message ID", vim.log.levels.WARN)
            return
        end
        M.read_email(opts.args)
    end, { nargs = 1, desc = "Read himalaya message" })

    vim.api.nvim_create_user_command("RkHimalayaWrite", function()
        create_term_buf("himalaya message write", "Himalaya Write")
    end, { desc = "Write himalaya message" })

    vim.api.nvim_create_user_command("RkHimalayaReply", function(opts)
        if opts.args == "" then
            vim.notify("Please provide a message ID", vim.log.levels.WARN)
            return
        end
        create_term_buf(
            "himalaya message reply " .. opts.args,
            "Himalaya Reply " .. opts.args
        )
    end, { nargs = 1, desc = "Reply to himalaya message" })

    vim.api.nvim_create_user_command("RkHimalayaForward", function(opts)
        if opts.args == "" then
            vim.notify("Please provide a message ID", vim.log.levels.WARN)
            return
        end
        create_term_buf(
            "himalaya message forward " .. opts.args,
            "Himalaya Forward " .. opts.args
        )
    end, { nargs = 1, desc = "Forward himalaya message" })

    vim.api.nvim_create_user_command("RkHimalayaDelete", function(opts)
        if opts.args == "" then
            vim.notify("Please provide a message ID", vim.log.levels.WARN)
            return
        end
        create_term_buf(
            "himalaya message delete " .. opts.args,
            "Himalaya Delete " .. opts.args
        )
    end, { nargs = 1, desc = "Delete himalaya message" })
end

return M
