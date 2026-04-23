local M = {}

local function get_visual_selection()
    local pos_start = vim.fn.getpos("'<")
    local line_start, column_start = pos_start[2], pos_start[3]
    local pos_end = vim.fn.getpos("'>")
    local line_end, column_end = pos_end[2], pos_end[3]

    local lines = vim.fn.getline(line_start, line_end)
    if type(lines) == "string" then
        lines = { lines }
    end
    if #lines == 0 then
        return ""
    end

    local selection_mode = vim.fn.visualmode()
    local is_inclusive = vim.o.selection == "inclusive"

    if selection_mode == "v" then
        -- Character-wise
        local end_offset = is_inclusive and 0 or 1
        lines[#lines] = string.sub(lines[#lines], 1, column_end - end_offset)
        lines[1] = string.sub(lines[1], column_start)
    elseif selection_mode == "V" then
        -- Line-wise: lines are already correct
    elseif selection_mode == "\22" then
        -- Block-wise (<C-V>)
        local end_offset = is_inclusive and 0 or 1
        for i = 1, #lines do
            lines[i] = string.sub(lines[i], column_start, column_end - end_offset)
        end
    end

    return table.concat(lines, "\n")
end

local function clean_hex(text)
    return string.gsub(text, "[^0-9A-Fa-f]", "")
end

local function hex_to_bin(hex)
    return (string.gsub(hex, "..", function(cc)
        return string.char(tonumber(cc, 16))
    end))
end

local function bin_to_hex(bin)
    return (string.gsub(bin, ".", function(c)
        return string.format("%02X", string.byte(c))
    end))
end

function M.do_sha256(opts)
    local text = ""
    if opts and opts.range == 0 then
        text = vim.fn.getline(".")
    else
        text = get_visual_selection()
    end

    local hex = clean_hex(text)

    if hex == "" or #hex % 2 ~= 0 then
        vim.api.nvim_err_writeln("Selected content cannot be parsed as a valid hex string.")
        return
    end

    local bin_data = hex_to_bin(hex)
    local tmp_in = vim.fn.tempname()
    local tmp_out = vim.fn.tempname()

    local f_in = io.open(tmp_in, "wb")
    if not f_in then
        vim.api.nvim_err_writeln("Failed to create temporary file.")
        return
    end
    f_in:write(bin_data)
    f_in:close()

    local cmd = string.format('openssl dgst -sha256 -binary -out "%s" "%s"', tmp_out, tmp_in)

    local handle = io.popen(cmd .. " 2>&1")
    if not handle then
        os.remove(tmp_in)
        vim.api.nvim_err_writeln("Failed to execute openssl command.")
        return
    end

    local err_output = handle:read("*a")
    local success = handle:close()

    if not success then
        vim.api.nvim_err_writeln("OpenSSL error: " .. (err_output or "unknown error"))
        os.remove(tmp_in)
        os.remove(tmp_out)
        return
    end

    local f_out = io.open(tmp_out, "rb")
    if not f_out then
        vim.api.nvim_err_writeln("Failed to read openssl output file.")
        os.remove(tmp_in)
        os.remove(tmp_out)
        return
    end

    local out_bin = f_out:read("*a")
    f_out:close()

    os.remove(tmp_in)
    os.remove(tmp_out)

    if out_bin and #out_bin > 0 then
        local out_hex = bin_to_hex(out_bin)
        out_hex = string.upper(out_hex)
        vim.fn.setreg("+", out_hex)
        vim.api.nvim_echo({{"SHA256 result copied to clipboard: " .. out_hex, "Normal"}}, true, {})
    else
        vim.api.nvim_err_writeln("SHA256 operation produced no output.")
    end
end

function M.setup()
    vim.api.nvim_create_user_command("RkSha256Hex", function(opts)
        M.do_sha256(opts)
    end, { range = true, desc = "Calculate SHA256 of selected hex content" })
end

return M
