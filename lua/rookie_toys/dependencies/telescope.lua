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

local function apply_global_replace(search_text, replace_text)
    if search_text == "" then
        print("Search text cannot be empty")
        return
    end

    -- Build rg command to populate quickfix
    local args = get_vimgrep_args()
    -- Add --vimgrep to get proper output for quickfix
    local rg_cmd_parts = { "rg", "--vimgrep" }
    -- Copy flags from get_vimgrep_args
    for i = 2, #args do
        table.insert(rg_cmd_parts, args[i])
    end
    table.insert(rg_cmd_parts, "--")
    table.insert(rg_cmd_parts, search_text)

    local rg_cmd = table.concat(rg_cmd_parts, " ")

    -- Populate quickfix list
    vim.fn.setqflist({}, "r")
    local output = vim.fn.systemlist(rg_cmd)
    if vim.v.shell_error ~= 0 and #output == 0 then
        print("No matches found for: " .. search_text)
        return
    end

    vim.fn.setqflist({}, "a", {
        title = "Replace: " .. search_text .. " -> " .. replace_text,
        lines = output,
    })

    -- Build neovim substitute command
    -- We need to escape the search and replace strings for Neovim's %s command
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

    local nv_replace = vim.fn.escape(replace_text, "\\/&")

    -- Use cfdo to replace in all files in quickfix
    -- 'update' saves the file after replacement
    local cmd =
        string.format("cfdo %%s/%s/%s/gj | update", nv_search, nv_replace)

    -- Confirm with user
    local count = #output
    local confirm = vim.fn.input(
        string.format(
            "Found %d matches. Replace '%s' with '%s' in all files? (y/n): ",
            count,
            search_text,
            replace_text
        )
    )
    if confirm:lower() == "y" then
        vim.cmd(cmd)
        print(string.format("Replaced %d occurrences.", count))
    else
        print("Replace canceled.")
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
                local replace_text = vim.fn.input("Replace with: ")
                apply_global_replace(current_input, replace_text)
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
    local telescope = require("telescope")

    -- Global config
    telescope.setup({
        defaults = {
            vimgrep_arguments = get_vimgrep_args(),
        },
    })

    -- Create user command for easier access
    vim.api.nvim_create_user_command("RkLiveGrep", function()
        live_grep_with_flags(nil, false)
    end, { desc = "Live Grep with togglable VS Code like flags" })

    vim.api.nvim_create_user_command("RkGlobalReplace", function()
        live_grep_with_flags(nil, true)
    end, { desc = "Global Replace with togglable VS Code like flags" })

    -- Map <leader>sg to RkLiveGrep
    vim.keymap.set(
        "n",
        "<leader>sg",
        "<cmd>RkLiveGrep<CR>",
        { desc = "Rookie Live Grep (enhance telescope)" }
    )

    -- Map <leader><F2> to RkGlobalReplace
    vim.keymap.set(
        "n",
        "<leader><F2>",
        "<cmd>RkGlobalReplace<CR>",
        { desc = "Rookie Global Replace (enhance telescope)" }
    )
end

return M
