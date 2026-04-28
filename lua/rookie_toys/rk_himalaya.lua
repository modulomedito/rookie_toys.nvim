local M = {}

-- State management for the Himalaya UI
local state = {
    folders_buf = nil,
    folders_win = nil,
    envelopes_buf = nil,
    envelopes_win = nil,
    message_buf = nil,
    message_win = nil,
    help_buf = nil,
    help_win = nil,
    current_folder = "INBOX",
    current_page = 1, -- Start at 1, as most CLIs use 1-based indexing
    page_size = 10,
    envelopes = {}, -- Store full envelope objects for reference
}

local envelope_table_header_lines = 2

local function strip_ansi_escape_codes(output)
    if type(output) ~= "string" or output == "" then return output end
    return output:gsub("\27%[[%d;?]*[%a]", "")
end

local function decode_himalaya_json(output)
    if type(output) ~= "string" or output == "" then return nil end

    local trimmed = vim.trim(strip_ansi_escape_codes(output))
    local json_start = trimmed:find("[%[%{%\"]")
    if not json_start then return nil end

    local json_payload = trimmed:sub(json_start)
    local ok, decoded = pcall(vim.fn.json_decode, json_payload)
    if not ok then return nil end

    if type(decoded) == "table" and not vim.islist(decoded) then
        if decoded.envelopes then return decoded.envelopes end
        if decoded.folders then return decoded.folders end
        if decoded.messages then return decoded.messages end
        if decoded.message then return decoded.message end
    end

    return decoded
end

local function format_contact_name(contact, full)
    if not contact then return "Unknown" end
    if type(contact) == "string" and contact ~= "" then return contact end

    -- Handle list of contacts (common in To/Cc/From)
    if type(contact) == "table" and vim.islist(contact) then
        if #contact == 0 then return "Unknown" end
        if full then
            -- For full format in a list context, we usually handle items individually,
            -- but if called on the list itself, we'll just take the first one.
            contact = contact[1]
        else
            -- For short format, just take the first one
            contact = contact[1]
        end
    end

    if type(contact) ~= "table" then return tostring(contact) end

    local name = contact.name or ""
    local addr = contact.addr or contact.address or contact.email or ""

    if full then
        if name ~= "" and addr ~= "" then
            return string.format("%s<%s>", name, addr)
        elseif name ~= "" then
            return name
        elseif addr ~= "" then
            return addr
        end
    else
        if name ~= "" then return name end
        if addr ~= "" then return addr end
    end

    return "Unknown"
end

local function split_contact_list(contacts)
    if not contacts then return {} end
    if type(contacts) == "string" then
        local parts = vim.split(contacts, ", ", { plain = true, trimempty = true })
        if #parts == 0 then return { contacts } end
        return parts
    end
    if type(contacts) == "table" then
        if vim.islist(contacts) then return contacts end
        return { contacts }
    end
    return { tostring(contacts) }
end

local function append_contact_list(lines, label, contacts)
    local list = split_contact_list(contacts)
    if #list == 0 then return end

    table.insert(lines, "- " .. label .. ":")
    for _, contact in ipairs(list) do
        table.insert(lines, "  - " .. format_contact_name(contact, true))
    end
end

local function format_message_lines(message)
    if type(message) == "table" then
        local lines = {}

        if message.subject and message.subject ~= "" then
            table.insert(lines, "# " .. message.subject)
            table.insert(lines, "")
        end

        if message.from then
            table.insert(lines, "- From: " .. format_contact_name(message.from, true))
        end
        append_contact_list(lines, "To", message.to)
        append_contact_list(lines, "Cc", message.cc)
        append_contact_list(lines, "Bcc", message.bcc)
        if message.date and message.date ~= "" then
            table.insert(lines, "- Date: " .. message.date)
        end

        if #lines > 0 then
            table.insert(lines, "")
            table.insert(lines, "---")
            table.insert(lines, "")
        end

        local body = message.content or message.body or vim.inspect(message)
        vim.list_extend(lines, vim.split(body, "\n", { plain = true }))
        return lines
    end

    if type(message) ~= "string" then
        return vim.split(vim.inspect(message), "\n", { plain = true })
    end

    local raw_lines = vim.split(message, "\n", { plain = true })
    local headers = {}
    local body_start = #raw_lines + 1
    local current_header = nil

    for index, line in ipairs(raw_lines) do
        if line == "" then
            body_start = index + 1
            break
        end

        if current_header and line:match("^%s+") then
            headers[current_header] = (headers[current_header] or "") .. " " .. vim.trim(line)
        else
            local key, value = line:match("^([%w%-]+):%s*(.*)$")
            if not key then
                return raw_lines
            end
            current_header = key:lower()
            headers[current_header] = value
        end
    end

    if next(headers) == nil then return raw_lines end

    local lines = {}
    if headers.subject and headers.subject ~= "" then
        table.insert(lines, "# " .. headers.subject)
        table.insert(lines, "")
    end
    if headers.from and headers.from ~= "" then
        table.insert(lines, "- From: " .. headers.from)
    end
    append_contact_list(lines, "To", headers.to)
    append_contact_list(lines, "Cc", headers.cc)
    append_contact_list(lines, "Bcc", headers.bcc)
    if headers.date and headers.date ~= "" then
        table.insert(lines, "- Date: " .. headers.date)
    end

    if #lines > 0 then
        table.insert(lines, "")
        table.insert(lines, "---")
        table.insert(lines, "")
    end

    for index = body_start, #raw_lines do
        table.insert(lines, raw_lines[index])
    end

    return lines
end

local function truncate_display(text, max_width)
    text = tostring(text or "")
    if max_width <= 0 then return "" end
    if vim.fn.strdisplaywidth(text) <= max_width then return text end
    if max_width == 1 then return "." end

    local target_width = max_width - 1
    local result = ""
    local width = 0
    local char_count = vim.fn.strchars(text)
    for index = 0, char_count - 1 do
        local s = vim.fn.strcharpart(text, index, 1)
        local char_width = vim.fn.strdisplaywidth(s)
        if width + char_width > target_width then break end
        result = result .. s
        width = width + char_width
    end

    return result .. "…"
end

local function pad_display(text, width, align_right)
    text = truncate_display(text, width)
    local padding = math.max(0, width - vim.fn.strdisplaywidth(text))
    if align_right then
        return string.rep(" ", padding) .. text
    end
    return text .. string.rep(" ", padding)
end

local function format_flags(env)
    local flags = {}
    if env.has_attachment then table.insert(flags, "@") end

    local env_flags = env.flags or {}
    local has = {}
    for _, flag in ipairs(env_flags) do
        has[flag] = true
    end

    if has.Answered then table.insert(flags, "R") end
    if has.Flagged then table.insert(flags, "!") end
    if has.Draft then table.insert(flags, "D") end
    if not has.Seen then table.insert(flags, "N") end

    return table.concat(flags)
end

local function render_envelope_lines(envelopes, total_width)
    local id_width = 4
    local flags_width = 5
    local date_width = 24

    local from_width = 8
    for _, env in ipairs(envelopes) do
        local sender = format_contact_name(env.sender or env.from)
        from_width = math.max(from_width, vim.fn.strdisplaywidth(sender))
    end
    from_width = math.min(from_width, 18)

    local separator_width = 16
    local min_subject_width = 20
    local subject_width = total_width - (id_width + flags_width + from_width + date_width + separator_width)
    if subject_width < min_subject_width then
        local overflow = min_subject_width - subject_width
        local shrink_from = math.min(overflow, math.max(0, from_width - 8))
        from_width = from_width - shrink_from
        overflow = overflow - shrink_from
        local shrink_date = math.min(overflow, math.max(0, date_width - 16))
        date_width = date_width - shrink_date
        subject_width = total_width - (id_width + flags_width + from_width + date_width + separator_width)
    end
    subject_width = math.max(min_subject_width, subject_width)

    local header = string.format(
        "| %s | %s | %s | %s | %s |",
        pad_display("ID", id_width, true),
        pad_display("FLAGS", flags_width, false),
        pad_display("SUBJECT", subject_width, false),
        pad_display("FROM", from_width, false),
        pad_display("DATE", date_width, false)
    )

    local divider = string.format(
        "|-%s-|-%s-|-%s-|-%s-|-%s-|",
        string.rep("-", id_width),
        string.rep("-", flags_width),
        string.rep("-", subject_width),
        string.rep("-", from_width),
        string.rep("-", date_width)
    )

    local lines = { header, divider }
    for _, env in ipairs(envelopes) do
        local line = string.format(
            "| %s | %s | %s | %s | %s |",
            pad_display(env.id or env.number or "?", id_width, true),
            pad_display(format_flags(env), flags_width, true),
            pad_display(env.subject or "(No Subject)", subject_width, false),
            pad_display(format_contact_name(env.sender or env.from), from_width, false),
            pad_display(env.date or "", date_width, false)
        )
        table.insert(lines, line)
    end

    return lines
end

-- Utility: Run himalaya CLI and return JSON
local function run_himalaya(args)
    if vim.fn.executable("himalaya") == 0 then
        vim.notify("himalaya CLI not found. Please install it first.", vim.log.levels.ERROR)
        return nil
    end

    -- Try both global and subcommand output flag (v1 vs v2)
    local cmds = {
        "himalaya --quiet --output json " .. args,
        "himalaya --quiet -o json " .. args,
        "himalaya " .. args .. " --quiet --output json",
    }

    local last_result = ""
    for _, cmd in ipairs(cmds) do
        local result = vim.fn.system(cmd)
        if vim.v.shell_error == 0 and result ~= "" then
            local decoded = decode_himalaya_json(result)
            if decoded ~= nil then return decoded end
        end
        last_result = result
    end

    -- If we reach here, either it's not JSON or all commands failed
    if last_result ~= "" and not last_result:find("no envelopes found") then
        -- If it's not JSON but successful, it might be raw text
        if vim.v.shell_error == 0 then return last_result end
    end

    return nil
end

-- UI Helpers: Create a buffer with specific settings
local function create_buffer(name, filetype)
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(buf, name)
    vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
    vim.api.nvim_buf_set_option(buf, "swapfile", false)
    vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
    vim.api.nvim_buf_set_option(buf, "filetype", filetype)
    return buf
end

local function create_floating_win(buf, opts)
    local width = opts.width or math.floor(vim.o.columns * 0.8)
    local height = opts.height or math.floor(vim.o.lines * 0.8)
    local col = opts.col or math.floor((vim.o.columns - width) / 2)
    local row = opts.row or math.floor((vim.o.lines - height) / 2)

    local win_opts = {
        relative = "editor",
        width = width,
        height = height,
        col = col,
        row = row,
        style = "minimal",
        border = "rounded",
        title = opts.title and (" " .. opts.title .. " ") or nil,
        title_pos = "center",
    }

    return vim.api.nvim_open_win(buf, true, win_opts)
end

local function set_buffer_keymaps(buf, mappings)
    if not buf or not vim.api.nvim_buf_is_valid(buf) then return end
    for lhs, rhs in pairs(mappings) do
        vim.keymap.set("n", lhs, rhs, { buffer = buf, silent = true, nowait = true })
    end
end

-- Fetch and render folders in the sidebar
function M.fetch_folders()
    if not state.folders_buf or not vim.api.nvim_buf_is_valid(state.folders_buf) then return end

    local folders = run_himalaya("folder list")
    if not folders then return end

    -- Ensure folders is a list
    if type(folders) == "table" and not vim.islist(folders) then
        folders = { folders }
    end

    local lines = {}
    for _, folder in ipairs(folders) do
        local name = folder.name or folder.id or tostring(folder)
        local prefix = (name == state.current_folder) and "→ " or "  "
        table.insert(lines, prefix .. name)
    end

    vim.api.nvim_buf_set_option(state.folders_buf, "modifiable", true)
    vim.api.nvim_buf_set_lines(state.folders_buf, 0, -1, false, lines)
    vim.api.nvim_buf_set_option(state.folders_buf, "modifiable", false)
end

-- Fetch and render envelopes for the current folder
function M.fetch_envelopes(folder, page)
    if not state.envelopes_buf or not vim.api.nvim_buf_is_valid(state.envelopes_buf) then return end

    if folder then
        state.current_folder = folder
        state.current_page = 1
    end

    if page then
        state.current_page = math.max(1, page)
    end

    -- Try multiple command variations for envelopes
    local escaped_folder = vim.fn.shellescape(state.current_folder)
    local variations = {
        string.format("envelope list --folder %s --page %d", escaped_folder, state.current_page),
        string.format("list --folder %s --page %d", escaped_folder, state.current_page),
        string.format("envelope list --folder %s", escaped_folder), -- Fallback without page
        "envelope list", -- Ultimate fallback
    }

    local envelopes = nil
    for _, args in ipairs(variations) do
        envelopes = run_himalaya(args)
        if envelopes and type(envelopes) == "table" and #envelopes > 0 then
            break
        end
    end

    if not envelopes or type(envelopes) ~= "table" or #envelopes == 0 then
        if state.current_page > 1 then
            state.current_page = state.current_page - 1
            vim.notify("No more pages", vim.log.levels.INFO)
        else
            vim.api.nvim_buf_set_option(state.envelopes_buf, "modifiable", true)
            vim.api.nvim_buf_set_lines(state.envelopes_buf, 0, -1, false, { "  (No envelopes found in " .. state.current_folder .. ")" })
            vim.api.nvim_buf_set_option(state.envelopes_buf, "modifiable", false)
        end
        return
    end

    state.envelopes = envelopes
    local width = 100
    if state.envelopes_win and vim.api.nvim_win_is_valid(state.envelopes_win) then
        width = vim.api.nvim_win_get_width(state.envelopes_win)
    end
    local lines = render_envelope_lines(envelopes, width)

    vim.api.nvim_buf_set_option(state.envelopes_buf, "modifiable", true)
    vim.api.nvim_buf_set_lines(state.envelopes_buf, 0, -1, false, lines)
    vim.api.nvim_buf_set_option(state.envelopes_buf, "modifiable", false)

    -- Update folder highlights
    M.fetch_folders()
end

function M.next_page()
    M.fetch_envelopes(nil, state.current_page + 1)
end

function M.prev_page()
    if state.current_page > 1 then
        M.fetch_envelopes(nil, state.current_page - 1)
    else
        vim.notify("Already on the first page", vim.log.levels.INFO)
    end
end

-- Read a specific message
function M.read_message(id)
    if not id then
        local cursor = vim.api.nvim_win_get_cursor(state.envelopes_win)
        local idx = cursor[1] - envelope_table_header_lines
        if state.envelopes[idx] then
            id = state.envelopes[idx].id
        end
    end

    if not id then return end

    -- Ensure message window exists
    if not state.message_win or not vim.api.nvim_win_is_valid(state.message_win) then
        state.message_buf = create_buffer("HimalayaMessage", "markdown")
        state.message_win = create_floating_win(state.message_buf, {
            width = math.floor(vim.o.columns * 0.8),
            height = math.floor(vim.o.lines * 0.8),
            title = "Message",
        })
        set_buffer_keymaps(state.message_buf, {
            ["g?"] = function()
                M.show_help()
            end,
        })
    end

    local message = run_himalaya("message read " .. id)
    if not message then return end

    local lines = format_message_lines(message)
    vim.api.nvim_buf_set_option(state.message_buf, "modifiable", true)
    vim.api.nvim_buf_set_lines(state.message_buf, 0, -1, false, lines)
    vim.api.nvim_buf_set_option(state.message_buf, "modifiable", false)
end

function M.show_help()
    local help_lines = {
        "# Himalaya Keymaps",
        "",
        "| Key | Action |",
        "| --- | ------ |",
        "| `<CR>` | Open selected folder or envelope |",
        "| `g?` | Show this help window |",
        "| `:RkHimalaya` | Open the Himalaya UI |",
        "| `:RkHimalayaClose` | Close the Himalaya UI |",
        "| `:RkHimalayaWrite` | Compose a new mail |",
        "| `:RkHimalayaReply {id}` | Reply in terminal mode |",
        "",
        "Press `q` or `<Esc>` to close this help.",
    }

    if state.help_win and vim.api.nvim_win_is_valid(state.help_win) then
        vim.api.nvim_set_current_win(state.help_win)
        return
    end

    state.help_buf = create_buffer("HimalayaHelp", "markdown")
    vim.api.nvim_buf_set_option(state.help_buf, "modifiable", true)
    vim.api.nvim_buf_set_lines(state.help_buf, 0, -1, false, help_lines)
    vim.api.nvim_buf_set_option(state.help_buf, "modifiable", false)

    state.help_win = create_floating_win(state.help_buf, {
        width = math.min(72, math.floor(vim.o.columns * 0.7)),
        height = math.min(16, math.floor(vim.o.lines * 0.6)),
        title = "Himalaya Help",
    })

    set_buffer_keymaps(state.help_buf, {
        q = function()
            if state.help_win and vim.api.nvim_win_is_valid(state.help_win) then
                vim.api.nvim_win_close(state.help_win, true)
            end
            state.help_win = nil
            state.help_buf = nil
        end,
        ["<Esc>"] = function()
            if state.help_win and vim.api.nvim_win_is_valid(state.help_win) then
                vim.api.nvim_win_close(state.help_win, true)
            end
            state.help_win = nil
            state.help_buf = nil
        end,
    })
end

function M.reload()
    M.fetch_folders()
    M.fetch_envelopes()
end

-- Open the main Himalaya UI
function M.open()
    -- Create buffers if they don't exist
    state.folders_buf = create_buffer("HimalayaFolders", "himalaya-folders")
    state.envelopes_buf = create_buffer("HimalayaEnvelopes", "markdown")

    local total_width = math.floor(vim.o.columns * 0.9)
    local total_height = math.floor(vim.o.lines * 0.85)
    local start_col = math.floor((vim.o.columns - total_width) / 2)
    local start_row = math.floor((vim.o.lines - total_height) / 2)

    local folders_width = 25

    -- 1. Folders Sidebar (Floating)
    state.folders_win = create_floating_win(state.folders_buf, {
        width = folders_width,
        height = total_height,
        col = start_col,
        row = start_row,
        title = "Folders",
    })
    vim.api.nvim_win_set_option(state.folders_win, "number", false)
    vim.api.nvim_win_set_option(state.folders_win, "relativenumber", false)

    -- 2. Envelopes List (Floating)
    state.envelopes_win = create_floating_win(state.envelopes_buf, {
        width = total_width - folders_width - 2,
        height = total_height,
        col = start_col + folders_width + 2,
        row = start_row,
        title = "Envelopes",
    })
    vim.api.nvim_win_set_option(state.envelopes_win, "number", false)

    set_buffer_keymaps(state.folders_buf, {
        ["<CR>"] = function()
            M.select_item()
        end,
        ["g?"] = function()
            M.show_help()
        end,
    })

    set_buffer_keymaps(state.envelopes_buf, {
        ["<CR>"] = function()
            M.select_item()
        end,
        ["g?"] = function()
            M.show_help()
        end,
    })

    -- Initial data fetch
    M.fetch_folders()
    M.fetch_envelopes(state.current_folder)
end

-- Close the Himalaya UI
function M.close()
    if state.folders_win and vim.api.nvim_win_is_valid(state.folders_win) then
        vim.api.nvim_win_close(state.folders_win, true)
    end
    if state.envelopes_win and vim.api.nvim_win_is_valid(state.envelopes_win) then
        vim.api.nvim_win_close(state.envelopes_win, true)
    end
    if state.message_win and vim.api.nvim_win_is_valid(state.message_win) then
        vim.api.nvim_win_close(state.message_win, true)
    end
    if state.help_win and vim.api.nvim_win_is_valid(state.help_win) then
        vim.api.nvim_win_close(state.help_win, true)
    end
    state.folders_win = nil
    state.envelopes_win = nil
    state.message_win = nil
    state.help_win = nil
    state.folders_buf = nil
    state.envelopes_buf = nil
    state.message_buf = nil
    state.help_buf = nil
end

function M.close_message()
    if state.message_win and vim.api.nvim_win_is_valid(state.message_win) then
        vim.api.nvim_win_close(state.message_win, true)
        state.message_win = nil
        state.message_buf = nil
    end
end

-- Select item under cursor (folder or envelope)
function M.select_item()
    local curr_win = vim.api.nvim_get_current_win()
    if curr_win == state.folders_win then
        local cursor = vim.api.nvim_win_get_cursor(state.folders_win)
        local line = vim.api.nvim_buf_get_lines(state.folders_buf, cursor[1]-1, cursor[1], false)[1]
        local folder = line:gsub("^%s*→%s*", ""):gsub("^%s*", "")
        M.fetch_envelopes(folder)
        -- Move focus to envelopes window after selecting folder
        if state.envelopes_win and vim.api.nvim_win_is_valid(state.envelopes_win) then
            vim.api.nvim_set_current_win(state.envelopes_win)
        end
    elseif curr_win == state.envelopes_win then
        M.read_message()
    end
end

function M.setup()
    -- Main command to open the UI
    vim.api.nvim_create_user_command("RkHimalaya", function()
        M.open()
    end, { desc = "Open Himalaya Email Client" })

    -- Legacy/Additional commands (keeping them but they now use the UI or terminal as fallback)
    vim.api.nvim_create_user_command("RkHimalayaList", function(opts)
        if opts.args ~= "" then
            M.fetch_envelopes(opts.args)
        else
            M.open()
        end
    end, { nargs = "*", desc = "List himalaya envelopes" })

    -- For composing/replying, we might still want the terminal for interactive editing
    local function run_in_term(cmd, title)
        local buf = vim.api.nvim_create_buf(false, true)
        local width = math.floor(vim.o.columns * 0.8)
        local height = math.floor(vim.o.lines * 0.8)
        local win_opts = {
            relative = "editor",
            width = width, height = height,
            col = math.floor((vim.o.columns - width) / 2),
            row = math.floor((vim.o.lines - height) / 2),
            style = "minimal", border = "rounded",
            title = " " .. title .. " ", title_pos = "center",
        }
        vim.api.nvim_open_win(buf, true, win_opts)
        vim.fn.termopen(cmd)
        vim.cmd("startinsert")
    end

    vim.api.nvim_create_user_command("RkHimalayaWrite", function()
        run_in_term("himalaya message write", "Himalaya Write")
    end, { desc = "Write himalaya message" })

    vim.api.nvim_create_user_command("RkHimalayaReply", function(opts)
        run_in_term("himalaya message reply " .. opts.args, "Himalaya Reply")
    end, { nargs = 1, desc = "Reply to himalaya message" })

    vim.api.nvim_create_user_command("RkHimalayaClose", function()
        M.close()
    end, { desc = "Close Himalaya UI" })
end

return M
