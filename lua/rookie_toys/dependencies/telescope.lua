local M = {}

-- Search state
local search_opts = {
    case_sensitive = false,
    whole_word = false,
    is_regex = true,
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

local function live_grep_with_flags(default_text)
    local builtin = require("telescope.builtin")
    local actions = require("telescope.actions")
    local action_state = require("telescope.actions.state")

    -- Format prompt title with current status
    local title = string.format(
        "Live Grep (ca[S]e:%s, [W]ord:%s, [R]egex:%s)",
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
                live_grep_with_flags(current_input)
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
        live_grep_with_flags()
    end, { desc = "Live Grep with togglable VS Code like flags" })

    -- Map <leader>sg to RkLiveGrep
    vim.keymap.set(
        "n",
        "<leader>sg",
        "<cmd>RkLiveGrep<CR>",
        { desc = "Rookie Live Grep (enhance telescope)" }
    )
end

return M
