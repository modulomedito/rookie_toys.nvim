local function handle_cargo_output(job_id, data, event)
    if not data or #data == 0 then
        return
    end

    local lines = {}
    for _, line in ipairs(data) do
        if line ~= "" then
            table.insert(lines, line)
        end
    end

    if #lines > 0 then
        vim.fn.setqflist({}, 'a', {lines = lines})
        vim.cmd('copen')
        -- Scroll to bottom of quickfix window
        vim.cmd('normal! G')
    end
end

local function handle_cargo_exit(job_id, data, event)
    vim.notify("Cargo run completed with exit code: " .. data, vim.log.levels.INFO)
end

return {
    handle_cargo_output = handle_cargo_output,
    handle_cargo_exit = handle_cargo_exit,
}

