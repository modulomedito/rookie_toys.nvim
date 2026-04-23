local M = {}

function M.toggle_header_source()
    local filename = vim.fn.expand('%:t:r')
    local extension = vim.fn.expand('%:e')
    local pattern = '**/' .. filename .. '.h'
    if extension == 'h' then
        pattern = '**/' .. filename .. '.c'
    end
    local matches = vim.fn.glob(pattern, 0, 1)
    if #matches == 0 then
        vim.notify('Corresponding header/source not exists', vim.log.levels.INFO)
        return
    end
    vim.cmd('edit ' .. vim.fn.fnameescape(matches[1]))
end

function M.setup()
    -- Create the user command for toggling header/source
    vim.api.nvim_create_user_command('RkToggleHeaderSource', function()
        M.toggle_header_source()
    end, {
        desc = 'Toggle between C/C++ header and source file'
    })

    vim.api.nvim_create_user_command('RkCCommentToSlash', function()
        vim.cmd('%:s/\\/\\*\\+\\s\\+\\(.*\\)\\*\\//\\/\\/ \\1/g')
    end, {
        desc = 'Convert C/C++ comment to slash comment'
    })

    -- Set up the default keymapping
    vim.keymap.set('n', '<leader>hh', ':RkToggleHeaderSource<CR>', {
        silent = true,
        desc = 'Toggle header/source (RookieToys)'
    })
end

return M
