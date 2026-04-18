local M = {}

function M.update_tags()
    local line = vim.api.nvim_get_current_line()
    local current_tags = {}

    for word in line:gmatch("%S+") do
        if word:match("^#%w+") then
            local tag = word:gsub("#", "")
            if tag ~= "" then
                table.insert(current_tags, tag)
            end
        end
    end

    local user_input = vim.fn.input('Enter tags (space separated): ')
    if user_input == '' then
        return
    end

    local input_tags = {}
    for tag in user_input:gmatch("%S+") do
        table.insert(input_tags, tag)
    end

    local all_tags = {}
    for _, tag in ipairs(current_tags) do
        table.insert(all_tags, tag)
    end
    for _, tag in ipairs(input_tags) do
        table.insert(all_tags, tag)
    end

    local uniq_tags = {}
    local seen = {}
    for _, tag in ipairs(all_tags) do
        if not seen[tag] then
            seen[tag] = true
            table.insert(uniq_tags, tag)
        end
    end

    table.sort(uniq_tags)

    local result = {}
    for _, tag in ipairs(uniq_tags) do
        table.insert(result, "#" .. tag)
    end

    vim.api.nvim_set_current_line(table.concat(result, " "))
end

function M.search_tags()
    local tags = vim.fn.input('Enter tags (space separated): ')
    if tags == '' then
        vim.api.nvim_echo({{'No tags entered.', 'WarningMsg'}}, false, {})
        return
    end

    local taglist = {}
    for tag in tags:gmatch("%S+") do
        table.insert(taglist, tag)
    end
    table.sort(taglist)

    local qf = {}
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local filename = vim.fn.expand('%')

    for lnum, line in ipairs(lines) do
        if line:match("^#%w+") then
            local found = true
            for _, tag in ipairs(taglist) do
                if not string.find(line, "#" .. tag, 1, true) then
                    found = false
                    break
                end
            end
            if found then
                table.insert(qf, {filename = filename, lnum = lnum, col = 1, text = line})
            end
        end
    end

    if #qf > 0 then
        if #qf == 1 then
            vim.fn.cursor(qf[1].lnum, 1)
        else
            vim.fn.setqflist(qf, 'r')
            vim.api.nvim_echo({{'Results sent to quickfix. Opening quickfix window...', 'Normal'}}, false, {})
            vim.cmd('copen')
        end
    else
        vim.api.nvim_echo({{' -------> No matching lines found.', 'Normal'}}, false, {})
    end
end

function M.search_global_tags()
    local tags = vim.fn.input('Enter global search tags (space separated): ')
    if tags == '' then
        vim.api.nvim_echo({{'No tags entered.', 'WarningMsg'}}, false, {})
        return
    end

    local taglist = {}
    for tag in tags:gmatch("%S+") do
        table.insert(taglist, tag)
    end
    table.sort(taglist)

    local pattern = "^#" .. table.concat(taglist, ".*#")
    vim.api.nvim_echo({{'Searching tags: ' .. pattern, 'Normal'}}, false, {})

    local cmd = { "rg", "--vimgrep", "--color=never", pattern }
    local output = vim.fn.systemlist(cmd)

    if vim.v.shell_error > 1 then
        vim.api.nvim_echo({{'Error running rg (is ripgrep installed?).', 'ErrorMsg'}}, false, {})
        return
    end

    if #output == 0 then
        vim.api.nvim_echo({{' -------> No matching lines found.', 'Normal'}}, false, {})
        return
    end

    vim.fn.setqflist({}, 'r', { title = 'Tag Search: ' .. tags, lines = output, efm = '%f:%l:%c:%m' })

    local qf = vim.fn.getqflist()
    local seen = {}
    local merged = {}
    for _, entry in ipairs(qf) do
        local key = entry.bufnr .. ':' .. entry.lnum
        if not seen[key] then
            seen[key] = true
            table.insert(merged, entry)
        end
    end

    if #merged == 1 then
        vim.fn.setqflist(merged, 'r')
        vim.cmd('cfirst')
        vim.cmd('cclose')
    else
        vim.fn.setqflist(merged, 'r')
        vim.cmd('copen')
        vim.cmd('redraw!')
        vim.api.nvim_echo({{'Results sent to quickfix (deduped rows).', 'Normal'}}, false, {})
    end
end

function M.add_file_name_tags()
    local input_tags = vim.fn.input('Enter file name tags (space separated): ')
    if input_tags == '' then
        vim.api.nvim_echo({{'No tags entered.', 'WarningMsg'}}, false, {})
        return
    end

    local tags_list = {}
    for tag in input_tags:gmatch("%S+") do
        table.insert(tags_list, tag)
    end

    local cur_file_name = vim.fn.expand('%:t:r')
    local cur_file_ext = vim.fn.expand('%:e')

    local all_tags = {}
    for tag in cur_file_name:gmatch("[^-]+") do
        table.insert(all_tags, tag)
    end
    for _, tag in ipairs(tags_list) do
        table.insert(all_tags, tag)
    end

    local uniq_tags = {}
    local seen = {}
    for _, tag in ipairs(all_tags) do
        if not seen[tag] then
            seen[tag] = true
            table.insert(uniq_tags, tag)
        end
    end
    table.sort(uniq_tags)

    local sorted_tags = table.concat(uniq_tags, "-")
    vim.cmd('Rename ' .. sorted_tags .. '.' .. cur_file_ext)
end

local function search_files_with_tags(tags)
    local cwd = vim.fn.getcwd()
    local matching_files = {}
    local files = vim.fn.globpath(cwd, '**/*', 0, 1)

    for _, file in ipairs(files) do
        if file ~= '' and vim.fn.filereadable(file) == 1 then
            local filename = vim.fn.fnamemodify(file, ':t')
            local all_tags_match = true
            for _, tag in ipairs(tags) do
                if not string.find(string.lower(filename), string.lower(tag), 1, true) then
                    all_tags_match = false
                    break
                end
            end
            if all_tags_match then
                table.insert(matching_files, file)
            end
        end
    end

    if #matching_files == 0 then
        print("\nNo files found containing all tags: [" .. table.concat(tags, ', ') .. "]")
    elseif #matching_files == 1 then
        vim.cmd('edit ' .. vim.fn.fnameescape(matching_files[1]))
    else
        local qf_list = {}
        for _, file in ipairs(matching_files) do
            table.insert(qf_list, {
                filename = file,
                text = 'File containing all tags: ' .. table.concat(tags, ', ')
            })
        end
        vim.fn.setqflist(qf_list)
        vim.cmd('copen')
    end
end

function M.search_file_name_tags()
    local input_tags = vim.fn.input('Search file name tags (space separated): ')
    if input_tags == '' then
        vim.api.nvim_echo({{'No tags entered.', 'WarningMsg'}}, false, {})
        return
    end

    local tags_list = {}
    for tag in input_tags:gmatch("%S+") do
        table.insert(tags_list, tag)
    end

    search_files_with_tags(tags_list)
end

function M.setup()
    vim.keymap.set('n', '<leader>FF', M.search_global_tags, { desc = 'Search global tags' })
    vim.keymap.set('n', '<leader>Ff', M.search_file_name_tags, { desc = 'Search file name tags' })
    vim.keymap.set('n', '<leader>ff', M.search_tags, { desc = 'Search tags' })
    vim.keymap.set('n', '<leader>fa', M.update_tags, { desc = 'Update tags' })
    vim.keymap.set('n', '<leader>Fa', M.add_file_name_tags, { desc = 'Add file name tags' })
end

return M
