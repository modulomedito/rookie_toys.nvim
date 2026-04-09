local M = {}

-- State variables
local state = {
    last_pattern = "",
    last_replace = "",
    last_flags = {},
    last_changed_files = {},
}

-- Helper to build Vim regex from flags
local function construct_vim_pattern(pattern, flags)
    local vim_pattern = ""

    -- Regex vs Literal
    if flags.r then
        vim_pattern = vim_pattern .. "\\v"
    else
        vim_pattern = vim_pattern .. "\\V"
    end

    -- Whole Word
    if flags.w then
        vim_pattern = vim_pattern .. "\\<" .. pattern .. "\\>"
    else
        vim_pattern = vim_pattern .. pattern
    end

    -- Case Sensitivity
    if flags.c then
        vim_pattern = vim_pattern .. "\\C"
    else
        -- Smart case behavior mimic
        if pattern:find("[A-Z]") then
            vim_pattern = vim_pattern .. "\\C"
        else
            vim_pattern = vim_pattern .. "\\c"
        end
    end

    return vim_pattern
end

-- Parse arguments: handles -c, -w, -r flags
local function parse_args(args)
    local flags = { c = false, w = false, r = false }
    local positional = {}
    local stop_flags = false

    for _, arg in ipairs(args) do
        if stop_flags then
            table.insert(positional, arg)
        elseif arg == "--" then
            stop_flags = true
        elseif arg:sub(1, 1) == "-" and #arg > 1 then
            if arg:find("c") then
                flags.c = true
            end
            if arg:find("w") then
                flags.w = true
            end
            if arg:find("r") then
                flags.r = true
            end
        else
            table.insert(positional, arg)
        end
    end
    return { flags = flags, args = positional }
end

-- Compute file mapping for shorter quickfix display
local function compute_file_mapping(items)
    local path_to_name = {}
    local name_to_paths = {}

    -- Collect all paths
    for _, item in ipairs(items) do
        if item.bufnr and item.bufnr > 0 then
            local path = vim.api.nvim_buf_get_name(item.bufnr)
            if path ~= "" then
                path = vim.fn.fnamemodify(path, ":p")
                if not path_to_name[path] then
                    local name = vim.fn.fnamemodify(path, ":t")
                    if not name_to_paths[name] then
                        name_to_paths[name] = {}
                    end
                    table.insert(name_to_paths[name], path)
                    path_to_name[path] = ""
                end
            end
        end
    end

    -- Assign names
    for name, paths in pairs(name_to_paths) do
        if #paths == 1 then
            path_to_name[paths[1]] = name
        else
            table.sort(paths)
            for idx, path in ipairs(paths) do
                if idx == 1 then
                    path_to_name[path] = name
                else
                    path_to_name[path] = name .. "_" .. (idx - 1)
                end
            end
        end
    end

    return path_to_name
end

-- Custom quickfix text function
function M.quickfix_text_func(info)
    local qflist
    if info.quickfix == 1 then
        qflist = vim.fn.getqflist({ id = info.id, items = 1, context = 1 })
    else
        qflist = vim.fn.getloclist(
            info.winid,
            { id = info.id, items = 1, context = 1 }
        )
    end

    local ctx = qflist.context or {}
    local mapping = ctx.file_mapping or {}
    local pattern = ctx.pattern or ""
    local replace_with = ctx.replace_with or ""
    local is_find_only = ctx.is_find_only
    local items_list = qflist.items
    local res = {}

    for i = info.start_idx, info.end_idx do
        local item = items_list[i]
        if item.valid == 1 then
            local fname = ""
            if item.bufnr > 0 then
                local full_path = vim.fn.fnamemodify(
                    vim.api.nvim_buf_get_name(item.bufnr),
                    ":p"
                )
                fname = mapping[full_path]
                    or vim.fn.fnamemodify(full_path, ":t")
            end

            local suffix = ""
            if not is_find_only then
                if replace_with ~= "" then
                    suffix = " [NEW: " .. replace_with .. "]"
                else
                    suffix = " (old: " .. pattern .. ")"
                end
            end
            local text = string.format(
                "%s|%d col %d| %s%s",
                fname,
                item.lnum,
                item.col,
                item.text,
                suffix
            )
            table.insert(res, text)
        else
            table.insert(res, item.text)
        end
    end

    return res
end

-- Run search logic
local function run_search(pattern, file_mask, flags, replace_with, is_find_only)
    local rg_opts = "--vimgrep --no-heading --hidden"

    -- Case Sensitive
    if flags.c then
        rg_opts = rg_opts .. " -s"
    else
        rg_opts = rg_opts .. " --smart-case"
    end

    -- Whole Word
    if flags.w then
        rg_opts = rg_opts .. " -w"
    end

    -- Regex vs Fixed String
    if not flags.r then
        rg_opts = rg_opts .. " -F"
    end

    local cmd = "rg " .. rg_opts .. " -e " .. vim.fn.shellescape(pattern)

    if file_mask and file_mask ~= "" then
        if file_mask:find("[*?%[]") then
            cmd = cmd .. " -g " .. vim.fn.shellescape(file_mask)
        else
            cmd = cmd .. " " .. vim.fn.shellescape(file_mask)
        end
    end

    local grep_output = vim.fn.system(cmd)

    local old_efm = vim.o.efm
    vim.o.efm = "%f:%l:%c:%m"
    vim.fn.cgetexpr(grep_output)
    vim.o.efm = old_efm

    local qf_list = vim.fn.getqflist()
    if #qf_list > 0 then
        local mapping = compute_file_mapping(qf_list)
        local ctx = {
            file_mapping = mapping,
            pattern = pattern,
            replace_with = replace_with,
            is_find_only = is_find_only,
        }
        vim.fn.setqflist({}, "r", {
            context = ctx,
            quickfixtextfunc = "v:lua.require('rookie_toys.rk_far').quickfix_text_func",
        })
        vim.cmd("copen")
        vim.cmd("wincmd p")

        -- Set search register for highlighting
        if pattern ~= "" then
            local vim_pattern = construct_vim_pattern(pattern, flags)
            vim.fn.setreg("/", vim_pattern)
            vim.fn.histadd("search", vim_pattern)
            vim.v.searchforward = 1
            vim.o.hlsearch = true
            vim.cmd("redraw!")
            vim.api.nvim_feedkeys("nN", "n", false)
        end
    else
        vim.cmd("cclose")
        vim.cmd("redraw")
        print("RookieFar: No matches found.")
    end
end

-- Exported Find
function M.find(...)
    local parsed = parse_args({ ... })
    local pattern = parsed.args[1] or ""
    local file_mask = parsed.args[2] or ""
    run_search(pattern, file_mask, parsed.flags, "", true)
end

-- Exported Replace
function M.replace(...)
    local parsed = parse_args({ ... })
    local pattern = parsed.args[1] or ""
    local replace_with = parsed.args[2] or ""
    local file_mask = parsed.args[3] or ""

    state.last_pattern = pattern
    state.last_replace = replace_with
    state.last_flags = parsed.flags

    run_search(pattern, file_mask, parsed.flags, replace_with, false)

    if #vim.fn.getqflist() > 0 then
        print("RookieFar: Found matches. Run :RkFarDo to execute replacement.")
    end
end

-- Exported Do
function M.do_replace()
    if state.last_pattern == "" then
        vim.api.nvim_err_writeln("RookieFar: No search pattern defined.")
        return
    end

    local pattern = state.last_pattern
    local replace = state.last_replace
    local flags = state.last_flags

    -- Construct Vim pattern based on flags
    local vim_pattern = construct_vim_pattern(pattern, flags)

    -- Escape delimiter / for substitute command
    local safe_pattern = vim_pattern:gsub("/", "\\/")
    local safe_replace = replace:gsub("/", "\\/")

    local cmd = "cfdo %s/"
        .. safe_pattern
        .. "/"
        .. safe_replace
        .. "/ge | update"

    -- Save files for Undo
    state.last_changed_files = {}
    local qf_list = vim.fn.getqflist()
    local seen_buffers = {}
    for _, item in ipairs(qf_list) do
        if item.bufnr and item.bufnr > 0 and not seen_buffers[item.bufnr] then
            seen_buffers[item.bufnr] = true
            table.insert(
                state.last_changed_files,
                vim.fn.fnamemodify(vim.api.nvim_buf_get_name(item.bufnr), ":p")
            )
        end
    end

    local original_win = vim.api.nvim_get_current_win()
    local original_buf = vim.api.nvim_get_current_buf()
    local save_view = vim.fn.winsaveview()

    -- If we are in quickfix window, try to find the target window
    if vim.bo.buftype == "quickfix" then
        vim.cmd("wincmd p")
        original_win = vim.api.nvim_get_current_win()
        original_buf = vim.api.nvim_get_current_buf()
        save_view = vim.fn.winsaveview()
    end

    local status, err = pcall(function()
        vim.cmd(cmd)

        -- Ensure we are in the original window
        if vim.bo.buftype == "quickfix" then
            vim.cmd("wincmd p")
        end

        if vim.api.nvim_get_current_buf() ~= original_buf then
            if vim.api.nvim_buf_is_valid(original_buf) then
                vim.api.nvim_set_current_buf(original_buf)
            end
        end
        vim.fn.winrestview(save_view)

        vim.cmd("cclose")
        print("RookieFar: Replacement complete. Use :RkFarUndo to undo.")
    end)

    if not status then
        vim.api.nvim_err_writeln(
            "RookieFar: Replacement failed: " .. tostring(err)
        )
    end
end

-- Exported Undo
function M.undo()
    if #state.last_changed_files == 0 then
        print("RookieFar: Nothing to undo.")
        return
    end

    for _, file in ipairs(state.last_changed_files) do
        if vim.fn.filereadable(file) == 1 then
            vim.cmd("edit " .. vim.fn.fnameescape(file))
            local status, err = pcall(function()
                vim.cmd("undo")
                vim.cmd("update")
            end)
            if not status then
                vim.api.nvim_err_writeln(
                    "RookieFar: Failed to undo in "
                        .. file
                        .. ": "
                        .. tostring(err)
                )
            end
        end
    end

    print("RookieFar: Undo complete.")
    state.last_changed_files = {}
end

-- Visual search helper
function M.visual_find()
    local saved_reg = vim.fn.getreg("v")
    local saved_regtype = vim.fn.getregtype("v")
    vim.cmd('normal! gv"vy')
    local text = vim.fn.getreg("v"):gsub("[\r\n]+$", "")
    vim.fn.setreg("v", saved_reg, saved_regtype)
    M.find("-c", text)
end

-- Command completion
function M.command_complete(arg_lead, cmd_line, cursor_pos)
    return { "-c", "-w", "-r" }
end

-- Plugin Setup
function M.setup()
    -- Keybindings (matching original leader mappings)
    vim.keymap.set("n", "<leader>gg", function()
        M.find("-cw", vim.fn.expand("<cword>"))
    end, { desc = "RookieFar - Find Word" })

    vim.keymap.set("v", "<leader>gg", function()
        M.visual_find()
    end, { desc = "RookieFar - Find Visual" })

    vim.keymap.set(
        "n",
        "<leader>gf",
        ":RkFarFind ",
        { desc = "RookieFar - Find Pattern" }
    )

    -- User Commands
    vim.api.nvim_create_user_command("RkFarFind", function(opts)
        M.find(table.unpack(opts.fargs))
    end, {
        nargs = "*",
        complete = function(arg_lead, cmd_line, cursor_pos)
            return M.command_complete(arg_lead, cmd_line, cursor_pos)
        end,
        desc = "RookieFar - Find",
    })

    vim.api.nvim_create_user_command("RkFarReplace", function(opts)
        M.replace(table.unpack(opts.fargs))
    end, {
        nargs = "*",
        complete = function(arg_lead, cmd_line, cursor_pos)
            return M.command_complete(arg_lead, cmd_line, cursor_pos)
        end,
        desc = "RookieFar - Replace",
    })

    vim.api.nvim_create_user_command("RkFarDo", function()
        M.do_replace()
    end, { desc = "RookieFar - Execute Replacement" })

    vim.api.nvim_create_user_command("RkFarUndo", function()
        M.undo()
    end, { desc = "RookieFar - Undo Replacement" })
end

return M
