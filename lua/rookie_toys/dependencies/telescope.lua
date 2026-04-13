local M = {}

-- Search state
local search_opts = {
    case_sensitive = true,
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

    local rg_cmd = table.concat(rg_cmd_parts, " ")

    local output = vim.fn.systemlist(rg_cmd)
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

    -- Build neovim substitute command pattern
    local nv_search = search_text
    if not search_opts.is_regex then
        nv_search = vim.fn.escape(nv_search, "\\/.*$^~[]")
    end
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
            local current_replace = action_state.get_current_line()
            local nv_replace = vim.fn.escape(current_replace, "\\/&")

            local lines = vim.fn.readfile(entry.filename)
            vim.bo[self.state.bufnr].modifiable = true
            vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)

            vim.api.nvim_buf_call(self.state.bufnr, function()
                pcall(
                    vim.cmd,
                    string.format("silent! %%s/%s/%s/ge", nv_search, nv_replace)
                )
            end)
            vim.bo[self.state.bufnr].modifiable = false

            local ft = require("plenary.filetype").detect(entry.filename)
                or "text"
            putils.highlighter(self.state.bufnr, ft, {})

            local winid = status.preview_win or self.state.winid
            if winid and vim.api.nvim_win_is_valid(winid) then
                -- Move cursor to target line and center it
                vim.schedule(function()
                    pcall(vim.api.nvim_win_set_cursor, winid, { entry.lnum, 0 })
                    pcall(vim.api.nvim_win_call, winid, function()
                        vim.cmd("normal! zz")
                    end)
                end)
            end

            -- Highlight the line background slightly to indicate it's the target line
            local ns_id = vim.api.nvim_create_namespace("rookie_toys_replace")
            vim.api.nvim_buf_clear_namespace(self.state.bufnr, ns_id, 0, -1)
            vim.api.nvim_buf_add_highlight(
                self.state.bufnr,
                ns_id,
                "CursorLine",
                entry.lnum - 1,
                0,
                -1
            )

            -- Highlight the replaced text specifically
            if current_replace ~= "" then
                local replaced_line = vim.api.nvim_buf_get_lines(
                    self.state.bufnr,
                    entry.lnum - 1,
                    entry.lnum,
                    false
                )[1]
                if replaced_line then
                    local start_idx = 1
                    while true do
                        local i, j = string.find(
                            replaced_line,
                            current_replace,
                            start_idx,
                            true
                        )
                        if not i then
                            break
                        end
                        vim.api.nvim_buf_add_highlight(
                            self.state.bufnr,
                            ns_id,
                            "Search",
                            entry.lnum - 1,
                            i - 1,
                            j
                        )
                        start_idx = j + 1
                    end
                end
            end
        end,
    })

    pickers
        .new({}, {
            prompt_title = "Replace: " .. search_text,
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
                                    -- Fetch current replace string
                                    local current_replace =
                                        action_state.get_current_line()
                                    local nv_replace =
                                        vim.fn.escape(current_replace, "\\/&")

                                    -- Refresh preview buffer
                                    local lines =
                                        vim.fn.readfile(entry.filename)
                                    local picker_bufnr =
                                        picker.previewer.state.bufnr
                                    -- Ensure buffer is still valid before operating on it
                                    if
                                        not vim.api.nvim_buf_is_valid(
                                            picker_bufnr
                                        )
                                    then
                                        return
                                    end

                                    vim.bo[picker_bufnr].modifiable = true
                                    vim.api.nvim_buf_set_lines(
                                        picker_bufnr,
                                        0,
                                        -1,
                                        false,
                                        lines
                                    )

                                    -- Apply substitution to preview buffer
                                    vim.api.nvim_buf_call(
                                        picker_bufnr,
                                        function()
                                            pcall(
                                                vim.cmd,
                                                string.format(
                                                    "silent! %%s/%s/%s/ge",
                                                    nv_search,
                                                    nv_replace
                                                )
                                            )
                                        end
                                    )
                                    vim.bo[picker_bufnr].modifiable = false

                                    -- Ensure cursor stays at the right line
                                    local winid = picker.preview_win
                                    if
                                        winid
                                        and vim.api.nvim_win_is_valid(winid)
                                    then
                                        pcall(
                                            vim.api.nvim_win_set_cursor,
                                            winid,
                                            { entry.lnum, 0 }
                                        )
                                        pcall(
                                            vim.api.nvim_win_call,
                                            winid,
                                            function()
                                                vim.cmd("normal! zz")
                                            end
                                        )
                                    end

                                    -- Re-apply highlights
                                    local ft = require("plenary.filetype").detect(
                                        entry.filename
                                    ) or "text"
                                    putils.highlighter(picker_bufnr, ft, {})

                                    local ns_id = vim.api.nvim_create_namespace(
                                        "rookie_toys_replace"
                                    )
                                    vim.api.nvim_buf_clear_namespace(
                                        picker_bufnr,
                                        ns_id,
                                        0,
                                        -1
                                    )

                                    -- Highlight the line background slightly to indicate it's the target line
                                    vim.api.nvim_buf_add_highlight(
                                        picker_bufnr,
                                        ns_id,
                                        "CursorLine",
                                        entry.lnum - 1,
                                        0,
                                        -1
                                    )

                                    -- Highlight the replaced text specifically
                                    if current_replace ~= "" then
                                        local replaced_line =
                                            vim.api.nvim_buf_get_lines(
                                                picker_bufnr,
                                                entry.lnum - 1,
                                                entry.lnum,
                                                false
                                            )[1]
                                        if replaced_line then
                                            local start_idx = 1
                                            while true do
                                                local i, j = string.find(
                                                    replaced_line,
                                                    current_replace,
                                                    start_idx,
                                                    true
                                                )
                                                if not i then
                                                    break
                                                end
                                                vim.api.nvim_buf_add_highlight(
                                                    picker_bufnr,
                                                    ns_id,
                                                    "Search",
                                                    entry.lnum - 1,
                                                    i - 1,
                                                    j
                                                )
                                                start_idx = j + 1
                                            end
                                        end
                                    end
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

                    local nv_replace_final = vim.fn.escape(replace_text, "\\/&")
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

    -- Map <leader><F2> to RkGlobalReplace
    vim.keymap.set(
        "n",
        "<leader><F2>",
        "<cmd>RkGlobalReplace<CR>",
        { desc = "Rookie Global Replace (enhance telescope)" }
    )

    vim.keymap.set("v", "<leader><F2>", function()
        -- Use preferred defaults (Case On, Regex Off, Word Off)
        search_opts.case_sensitive = true
        search_opts.is_regex = false
        search_opts.whole_word = false

        local saved_reg = vim.fn.getreg("v")
        vim.cmd('noau normal! "vy')
        local text = vim.fn.getreg("v")
        vim.fn.setreg("v", saved_reg)
        text = string.gsub(text, "\n", "")

        -- Show search picker first to let user choose parameters
        live_grep_with_flags(text, true)
    end, {
        desc = "Global Replace Selection (Rookie Toys)",
    })

    -- Map <leader><leader><F2> to RkGlobalReplaceUndo
    vim.keymap.set(
        "n",
        "<leader><leader><F2>",
        "<cmd>RkGlobalReplaceUndo<CR>",
        { desc = "Rookie Global Replace Undo" }
    )

    vim.keymap.set("n", "<C-p>", function()
        require("telescope.builtin").find_files({ cwd = vim.fn.getcwd() })
    end, { desc = "Search Files" })

    -- Add grep_string mapping restricted to CWD
    vim.keymap.set("n", "<leader>sw", function()
        require("telescope.builtin").grep_string({ cwd = vim.fn.getcwd() })
    end, { desc = "Search Word under cursor in CWD" })
end

return M
