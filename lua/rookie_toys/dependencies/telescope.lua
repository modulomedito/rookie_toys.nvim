local M = {}

-- Search state
local search_opts = {
    case_sensitive = false,
    whole_word = false,
    is_regex = false,
}

local function get_vimgrep_args()
    local args = {
        "rg",
        "--color=never",
        "--no-heading",
        "--with-filename",
        "--line-number",
        "--column",
    }

    -- Case sensitive
    if search_opts.case_sensitive then
        table.insert(args, "--case-sensitive")
    else
        table.insert(args, "--smart-case")
    end

    -- Whole word
    if search_opts.whole_word then
        table.insert(args, "--word-regexp")
    end

    -- Regex (Enabled by default in rg, but can be disabled via --fixed-strings)
    if not search_opts.is_regex then
        table.insert(args, "--fixed-strings")
    end

    return args
end

local function apply_global_replace(search_text)
    if search_text == "" then
        print("Search text cannot be empty")
        return
    end

    -- Build rg command to get matches
    local args = get_vimgrep_args()
    local rg_cmd_parts = { "rg", "--vimgrep" }
    for i = 2, #args do
        table.insert(rg_cmd_parts, args[i])
    end
    table.insert(rg_cmd_parts, "--")
    table.insert(rg_cmd_parts, search_text)
    table.insert(rg_cmd_parts, ".")

    local output = vim.fn.systemlist(rg_cmd_parts)
    if vim.v.shell_error ~= 0 and #output == 0 then
        print("No matches found for: " .. search_text)
        return
    end

    local pickers = require("telescope.pickers")
    local finders = require("telescope.finders")
    local conf = require("telescope.config").values
    local previewers = require("telescope.previewers")
    local actions = require("telescope.actions")
    local action_state = require("telescope.actions.state")
    local putils = require("telescope.previewers.utils")

    local function build_substitute_search(text)
        if search_opts.is_regex then
            return text
        end
        -- Regex OFF: escape Vim pattern metacharacters + Ex command delimiters.
        return vim.fn.escape(text, [[\/.*$^~[]|"]])
    end

    local function build_substitute_replace(text)
        if search_opts.is_regex then
            -- Keep regex replacement features (e.g. \1) in regex mode.
            return vim.fn.escape(text, [[/&|"]])
        end
        -- Regex OFF: treat replacement as plain text.
        return vim.fn.escape(text, [[\/&~|"]])
    end

    local preview_ns_id = vim.api.nvim_create_namespace("rookie_toys_replace")
    local preview_info_ns_id =
        vim.api.nvim_create_namespace("rookie_toys_replace_info")
    local file_cache = {}
    local preview_state = {}
    local nv_search

    local function get_file_lines(filename)
        if file_cache[filename] then
            return file_cache[filename]
        end
        local ok, lines = pcall(vim.fn.readfile, filename)
        if not ok then
            return {}
        end
        file_cache[filename] = lines
        return lines
    end

    local function sanitize_preview_text(text)
        return tostring(text):gsub("\n", "\\n"):gsub("\r", "\\r"):gsub("\t", "\\t")
    end

    local function build_regex_group_preview(line_text, replace_text)
        if not search_opts.is_regex then
            return nil
        end

        local referenced_groups = {}
        for ref in replace_text:gmatch("\\(%d)") do
            referenced_groups[tonumber(ref)] = true
        end
        if vim.tbl_isempty(referenced_groups) then
            return nil
        end

        local ok_match, matchlist = pcall(vim.fn.matchlist, line_text, nv_search)
        if not ok_match then
            return "Regex preview: invalid pattern for this line."
        end
        if type(matchlist) ~= "table" or #matchlist == 0 then
            return "Regex preview: no match on the selected line."
        end

        local group_parts = {}
        local missing_groups = {}
        local ordered_refs = {}
        for idx, _ in pairs(referenced_groups) do
            table.insert(ordered_refs, idx)
        end
        table.sort(ordered_refs)

        for _, ref in ipairs(ordered_refs) do
            local value = matchlist[ref + 1]
            if value == nil then
                value = ""
                table.insert(missing_groups, "\\" .. ref)
            end
            table.insert(
                group_parts,
                string.format("\\%d='%s'", ref, sanitize_preview_text(value))
            )
        end

        -- Preserve escaped backslashes, then resolve backrefs.
        local marker = "\1"
        local rendered = replace_text:gsub("\\\\", marker):gsub(
            "\\(%d)",
            function(digit)
                local value = matchlist[tonumber(digit) + 1]
                if value == nil then
                    return ""
                end
                return value
            end
        ):gsub(marker, "\\")

        local message = "Regex groups: "
            .. table.concat(group_parts, ", ")
            .. " -> '"
            .. sanitize_preview_text(rendered)
            .. "'"

        if #missing_groups > 0 then
            message = message
                .. " (missing "
                .. table.concat(missing_groups, ", ")
                .. " => '')"
        end

        return message
    end

    local function render_replace_preview(bufnr, entry, replace_text, winid)
        if not vim.api.nvim_buf_is_valid(bufnr) then
            return
        end

        if type(entry) ~= "table" then
            return
        end
        if type(entry.filename) ~= "string" or entry.filename == "" then
            return
        end
        if type(entry.lnum) ~= "number" or entry.lnum < 1 then
            return
        end

        local source_lines = get_file_lines(entry.filename)
        if #source_lines == 0 then
            return
        end
        local target_lnum = math.min(entry.lnum, #source_lines)
        local original_line = source_lines[target_lnum] or ""
        local nv_replace = build_substitute_replace(replace_text)
        local substituted_line = original_line
        local regex_preview_msg = nil
        local substitution_error = nil

        if replace_text ~= "" then
            local ok_sub, result =
                pcall(vim.fn.substitute, original_line, nv_search, nv_replace, "g")
            if ok_sub then
                substituted_line = result
            else
                substitution_error = tostring(result)
            end
            regex_preview_msg =
                build_regex_group_preview(original_line, replace_text)
        end

        local state = preview_state[bufnr]
        local reload_buffer = not state or state.filename ~= entry.filename

        vim.bo[bufnr].modifiable = true
        if reload_buffer then
            vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, source_lines)
            preview_state[bufnr] = { filename = entry.filename, last_lnum = nil }
            state = preview_state[bufnr]

            local ft = require("plenary.filetype").detect(entry.filename) or "text"
            putils.highlighter(bufnr, ft, {})
        end

        if state.last_lnum and state.last_lnum ~= entry.lnum then
            local restore_idx = math.min(state.last_lnum, #source_lines)
            local restore_line = source_lines[restore_idx] or ""
            vim.api.nvim_buf_set_lines(
                bufnr,
                restore_idx - 1,
                restore_idx,
                false,
                { restore_line }
            )
        end

        vim.api.nvim_buf_set_lines(
            bufnr,
            target_lnum - 1,
            target_lnum,
            false,
            { substituted_line }
        )
        state.last_lnum = target_lnum
        vim.bo[bufnr].modifiable = false

        if winid and vim.api.nvim_win_is_valid(winid) then
            pcall(vim.api.nvim_win_set_cursor, winid, { target_lnum, 0 })
            pcall(vim.api.nvim_win_call, winid, function()
                vim.cmd("normal! zz")
            end)
        end

        vim.api.nvim_buf_clear_namespace(bufnr, preview_ns_id, 0, -1)
        vim.api.nvim_buf_clear_namespace(bufnr, preview_info_ns_id, 0, -1)
        vim.api.nvim_buf_add_highlight(
            bufnr,
            preview_ns_id,
            "CursorLine",
            target_lnum - 1,
            0,
            -1
        )

        if not search_opts.is_regex and replace_text ~= "" and substituted_line ~= "" then
            local start_idx = 1
            while true do
                local i, j =
                    string.find(substituted_line, replace_text, start_idx, true)
                if not i then
                    break
                end
                vim.api.nvim_buf_add_highlight(
                    bufnr,
                    preview_ns_id,
                    "Search",
                    target_lnum - 1,
                    i - 1,
                    j
                )
                start_idx = j + 1
            end
        end

        if substitution_error then
            vim.api.nvim_buf_set_extmark(
                bufnr,
                preview_info_ns_id,
                target_lnum - 1,
                0,
                {
                    virt_text = {
                        {
                            "Regex preview error: " .. substitution_error,
                            "DiagnosticError",
                        },
                    },
                    virt_text_pos = "eol",
                }
            )
            return
        end

        if regex_preview_msg then
            vim.api.nvim_buf_set_extmark(
                bufnr,
                preview_info_ns_id,
                target_lnum - 1,
                0,
                {
                    virt_text = { { regex_preview_msg, "Comment" } },
                    virt_text_pos = "eol",
                }
            )
        end
    end

    -- Build neovim substitute command pattern
    nv_search = build_substitute_search(search_text)
    if search_opts.whole_word then
        nv_search = "\\<" .. nv_search .. "\\>"
    end
    if search_opts.case_sensitive then
        nv_search = "\\C" .. nv_search
    else
        nv_search = "\\c" .. nv_search
    end

    local replace_previewer = previewers.new_buffer_previewer({
        title = "Replace Preview",
        define_preview = function(self, entry, status)
            if not self or not self.state or not self.state.bufnr then
                return
            end
            if type(entry) ~= "table" then
                return
            end
            local current_replace = action_state.get_current_line()
            render_replace_preview(
                self.state.bufnr,
                entry,
                current_replace,
                (status and status.preview_win) or self.state.winid
            )
        end,
    })

    local prompt_title = string.format(
        "Replace: %s (ca[S]e:%s, [W]ord:%s, [R]egex:%s)",
        search_text,
        search_opts.case_sensitive and "On" or "Off",
        search_opts.whole_word and "On" or "Off",
        search_opts.is_regex and "On" or "Off"
    )

    pickers
        .new({}, {
            prompt_title = prompt_title,
            default_text = search_text,
            finder = finders.new_table({
                results = output,
                entry_maker = function(line)
                    local file, lnum, col, text =
                        string.match(line, "^([^:]+):(%d+):(%d+):(.*)$")
                    if not file then
                        return nil
                    end
                    return {
                        value = line,
                        display = file
                            .. ":"
                            .. lnum
                            .. ":"
                            .. col
                            .. " "
                            .. text,
                        ordinal = line,
                        filename = file,
                        lnum = tonumber(lnum),
                        col = tonumber(col),
                        text = text,
                    }
                end,
            }),
            sorter = require("telescope.sorters").empty(),
            previewer = replace_previewer,
            attach_mappings = function(prompt_bufnr, map)
                -- Update preview on text change
                vim.api.nvim_create_autocmd("TextChangedI", {
                    buffer = prompt_bufnr,
                    callback = function()
                        local picker =
                            action_state.get_current_picker(prompt_bufnr)
                        if picker and picker.previewer then
                            local entry = action_state.get_selected_entry()
                            if
                                entry
                                and picker.previewer.state
                                and picker.previewer.state.bufnr
                            then
                                -- Schedule the preview update so we don't interfere with Telescope's internal state machine
                                vim.schedule(function()
                                    local picker_bufnr =
                                        picker.previewer.state.bufnr
                                    local current_replace =
                                        action_state.get_current_line()
                                    render_replace_preview(
                                        picker_bufnr,
                                        entry,
                                        current_replace,
                                        picker.preview_win
                                    )
                                end)
                            end
                        end
                    end,
                })

                actions.select_default:replace(function()
                    local replace_text = action_state.get_current_line()
                    actions.close(prompt_bufnr)

                    -- Populate quickfix list
                    vim.fn.setqflist({}, "r")
                    vim.fn.setqflist({}, "a", {
                        title = "Replace: "
                            .. search_text
                            .. " -> "
                            .. replace_text,
                        lines = output,
                    })

                    local nv_replace_final =
                        build_substitute_replace(replace_text)
                    local cmd = string.format(
                        "cfdo %%s/%s/%s/ge | update",
                        nv_search,
                        nv_replace_final
                    )

                    -- Save current window, buffer, and cursor position
                    local original_win = vim.api.nvim_get_current_win()
                    local original_buf = vim.api.nvim_get_current_buf()
                    local original_cursor =
                        vim.api.nvim_win_get_cursor(original_win)

                    vim.cmd("silent! " .. cmd)

                    -- Restore cursor to original window/buffer if they still exist
                    if
                        vim.api.nvim_win_is_valid(original_win)
                        and vim.api.nvim_buf_is_valid(original_buf)
                    then
                        vim.api.nvim_set_current_win(original_win)
                        vim.api.nvim_set_current_buf(original_buf)
                        pcall(
                            vim.api.nvim_win_set_cursor,
                            original_win,
                            original_cursor
                        )
                    end

                    print(
                        string.format(
                            "Replaced occurrences with '%s'.",
                            replace_text
                        )
                    )
                end)
                return true
            end,
        })
        :find()
end

local function global_replace_undo()
    local qf = vim.fn.getqflist({ title = 1, size = 1 })
    local qf_title = qf.title
    local qf_size = qf.size

    if
        type(qf_title) ~= "string" or not string.match(qf_title, "^Replace:")
    then
        print(
            "The current quickfix list does not contain a Global Replace result."
        )
        return
    end

    if qf_size == 0 then
        print("No files in the replace quickfix list to undo.")
        return
    end

    local confirm = vim.fn.input(
        "Undo '" .. qf_title .. "' across " .. qf_size .. " matches? (y/n): "
    )
    if confirm:lower() == "y" then
        vim.cmd("cfdo silent! undo | update")
        print("Global replace undone.")
    else
        print("Undo canceled.")
    end
end

local function live_grep_with_flags(default_text, is_replace)
    local builtin = require("telescope.builtin")
    local actions = require("telescope.actions")
    local action_state = require("telescope.actions.state")

    -- Format prompt title with current status
    local prefix = is_replace and "Global Replace" or "Live Grep"
    local title = string.format(
        "%s (ca[S]e:%s, [W]ord:%s, [R]egex:%s)",
        prefix,
        search_opts.case_sensitive and "On" or "Off",
        search_opts.whole_word and "On" or "Off",
        search_opts.is_regex and "On" or "Off"
    )

    builtin.live_grep({
        cwd = vim.fn.getcwd(),
        prompt_title = title,
        default_text = default_text,
        vimgrep_arguments = get_vimgrep_args(),
        attach_mappings = function(prompt_bufnr, map)
            local function refresh_with_toggle(toggle_key)
                local current_input = action_state.get_current_line()
                if toggle_key == "case" then
                    search_opts.case_sensitive = not search_opts.case_sensitive
                elseif toggle_key == "word" then
                    search_opts.whole_word = not search_opts.whole_word
                elseif toggle_key == "regex" then
                    search_opts.is_regex = not search_opts.is_regex
                end

                actions.close(prompt_bufnr)
                live_grep_with_flags(current_input, is_replace)
            end

            local function start_replace()
                local current_input = action_state.get_current_line()
                actions.close(prompt_bufnr)
                if current_input == "" then
                    print("Search text cannot be empty")
                    return
                end
                apply_global_replace(current_input)
            end

            -- Shortcuts like VS Code:
            -- <C-s>: Case Sensitive
            -- <C-w>: Whole Word
            -- <C-r>: Regex
            map("i", "<C-s>", function()
                refresh_with_toggle("case")
            end)
            map("i", "<C-w>", function()
                refresh_with_toggle("word")
            end)
            map("i", "<C-r>", function()
                refresh_with_toggle("regex")
            end)

            if is_replace then
                -- In replace mode, Enter starts the replace workflow
                map("i", "<CR>", start_replace)
            end

            return true
        end,
    })
end

function M.setup()
    local has_telescope, telescope = pcall(require, "telescope")

    if not has_telescope then
        -- Fallback if telescope not enabled
        vim.keymap.set("n", "<C-p>", ":find *")
        return
    end

    local actions = require("telescope.actions")
    local action_state = require("telescope.actions.state")

    -- Global config
    telescope.setup({
        defaults = {
            vimgrep_arguments = get_vimgrep_args(),
            mappings = {
                i = {
                    ["<C-v>"] = function()
                        local clipboard = vim.fn.getreg("+")
                        -- Remove newlines as telescope input is single line
                        clipboard = clipboard:gsub("\n", ""):gsub("\r", "")
                        vim.api.nvim_put({ clipboard }, "c", true, true)
                    end,
                },
            },
        },
    })

    -- Create user command for easier access
    vim.api.nvim_create_user_command("RkLiveGrep", function()
        live_grep_with_flags("", false)
    end, { desc = "Live Grep with togglable VS Code like flags" })

    vim.api.nvim_create_user_command("RkGlobalReplace", function()
        -- Use preferred defaults (Case On, Regex Off, Word Off)
        search_opts.case_sensitive = true
        search_opts.is_regex = false
        search_opts.whole_word = false

        local search_text = vim.fn.expand("<cword>")
        -- Show search picker first to let user choose parameters
        live_grep_with_flags(search_text, true)
    end, { desc = "Global Replace with togglable VS Code like flags" })

    vim.api.nvim_create_user_command("RkGlobalReplaceUndo", function()
        global_replace_undo()
    end, { desc = "Undo the last Global Replace operation" })

    -- Map <leader>sg to RkLiveGrep
    vim.keymap.set(
        "n",
        "<leader>sg",
        "<cmd>RkLiveGrep<CR>",
        { desc = "Rookie Live Grep (enhance telescope)" }
    )

    vim.keymap.set("v", "<leader>sg", function()
        local saved_reg = vim.fn.getreg("v")
        vim.cmd('noau normal! "vy')
        local text = vim.fn.getreg("v")
        vim.fn.setreg("v", saved_reg)
        text = string.gsub(text, "\n", "")
        live_grep_with_flags(text, false)
    end, { desc = "Rookie Live Grep (enhance telescope) from selection" })

    -- -- Map <leader><F2> to RkGlobalReplace
    -- vim.keymap.set(
    --     "n",
    --     "<leader><F2>",
    --     "<cmd>RkGlobalReplace<CR>",
    --     { desc = "Rookie Global Replace (enhance telescope)" }
    -- )

    -- vim.keymap.set("v", "<leader><F2>", function()
    --     -- Use preferred defaults (Case On, Regex Off, Word Off)
    --     search_opts.case_sensitive = true
    --     search_opts.is_regex = false
    --     search_opts.whole_word = false

    --     local saved_reg = vim.fn.getreg("v")
    --     vim.cmd('noau normal! "vy')
    --     local text = vim.fn.getreg("v")
    --     vim.fn.setreg("v", saved_reg)
    --     text = string.gsub(text, "\n", "")

    --     -- Show search picker first to let user choose parameters
    --     live_grep_with_flags(text, true)
    -- end, {
    --     desc = "Global Replace Selection (Rookie Toys)",
    -- })

    -- -- Map <leader><leader><F2> to RkGlobalReplaceUndo
    -- vim.keymap.set(
    --     "n",
    --     "<leader><leader><F2>",
    --     "<cmd>RkGlobalReplaceUndo<CR>",
    --     { desc = "Rookie Global Replace Undo" }
    -- )

    vim.keymap.set("n", "<C-p>", function()
        require("telescope.builtin").find_files({ cwd = vim.fn.getcwd() })
    end, { desc = "Search Files" })

    -- Add grep_string mapping restricted to CWD
    vim.keymap.set("n", "<leader>sw", function()
        require("telescope.builtin").grep_string({ cwd = vim.fn.getcwd() })
    end, { desc = "Search Word under cursor in CWD" })
end

return M
