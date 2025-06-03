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
        vim.fn.setqflist({}, 'a', { lines = lines })
        vim.cmd('copen')
        -- Scroll to bottom of quickfix window
        vim.cmd('normal! G')
    end
end

local function handle_cargo_exit(job_id, data, event)
    vim.notify("Cargo run completed with exit code: " .. data, vim.log.levels.INFO)
    vim.cmd('call setqflist([])')
    vim.cmd('cclose')
end

local function cargo_run()
    vim.fn.jobstart('cargo run', {
        on_stdout = require("rookie_toys.run").handle_cargo_output,
        on_stderr = require("rookie_toys.run").handle_cargo_output,
        on_exit = require("rookie_toys.run").handle_cargo_exit
    })
end

return {
    handle_cargo_output = handle_cargo_output,
    handle_cargo_exit = handle_cargo_exit,
    cargo_run = cargo_run,
}
