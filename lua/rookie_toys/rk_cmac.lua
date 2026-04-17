local M = {}

-- Store the CMAC key
local cmac_key = nil

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

function M.set_cmac_key(opts)
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

    cmac_key = hex
    vim.api.nvim_echo({{"CMAC key set to: " .. cmac_key, "Normal"}}, true, {})
end

function M.calc_cmac(opts)
    if not cmac_key then
        vim.api.nvim_err_writeln("CMAC key not set. Use RkCmacKey first.")
        return
    end

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
    local tmp_file = vim.fn.tempname()
    local f = io.open(tmp_file, "wb")
    if not f then
        vim.api.nvim_err_writeln("Failed to create temporary file for CMAC calculation.")
        return
    end
    f:write(bin_data)
    f:close()

    local cipher = "aes-128-cbc"
    if #cmac_key == 64 then
        cipher = "aes-256-cbc"
    elseif #cmac_key == 48 then
        cipher = "aes-192-cbc"
    end

    -- Run openssl command
    local cmd = string.format('openssl dgst -mac cmac -macopt cipher:%s -macopt hexkey:%s "%s"', cipher, cmac_key, tmp_file)
    local handle = io.popen(cmd)
    if not handle then
        os.remove(tmp_file)
        vim.api.nvim_err_writeln("Failed to execute openssl command.")
        return
    end

    local result = handle:read("*a")
    handle:close()
    os.remove(tmp_file)

    -- Result format: HMAC-CMAC(file)= 1a2b3c... or CMAC-AES-128-CBC(file)= 1a2b3c...
    local mac = string.match(result, "= %s*([0-9a-fA-F]+)")
    if not mac then
        -- If pattern didn't match, try to find 32 consecutive hex characters
        mac = string.match(result, "([0-9a-fA-F]{32})")
    end

    if mac then
        mac = string.upper(mac)
        vim.fn.setreg("+", mac)
        vim.api.nvim_echo({{"CMAC calculated and copied to clipboard: " .. mac, "Normal"}}, true, {})
    else
        vim.api.nvim_err_writeln("Failed to parse CMAC from openssl output: " .. (result or "no output"))
    end
end

function M.setup()
    vim.api.nvim_create_user_command("RkCmacKey", function(opts)
        M.set_cmac_key(opts)
    end, { range = true, desc = "Set CMAC key from selected hex content" })

    vim.api.nvim_create_user_command("RkCmacCalc", function(opts)
        M.calc_cmac(opts)
    end, { range = true, desc = "Calculate CMAC from selected hex content" })
end

return M
