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
            lines[i] =
                string.sub(lines[i], column_start, column_end - end_offset)
        end
    end

    return table.concat(lines, "\n")
end

local function clean_hex(text)
    return string.gsub(text, "[^0-9A-Fa-f]", "")
end

local function parse_intel_hex_line(line, silent)
    if #line < 1 or string.sub(line, 1, 1) ~= ":" then
        if not silent then
            vim.api.nvim_echo({
                {
                    "Current line is not a valid Intel HEX record (must start with ':')",
                    "ErrorMsg",
                },
            }, true, {})
        end
        return ""
    end

    -- Parse Byte Count (chars 2-3 in lua, 1-based index)
    local byte_count_hex = string.sub(line, 2, 3)
    local byte_count = tonumber(byte_count_hex, 16)
    if not byte_count then
        return ""
    end

    -- Parse Record Type (chars 8-9)
    local record_type = string.sub(line, 8, 9)

    -- Check if it is a Data Record ("00")
    if record_type ~= "00" then
        if not silent then
            vim.api.nvim_echo({
                {
                    "Record type is "
                        .. record_type
                        .. " (not Data), skipping ASCII conversion.",
                    "None",
                },
            }, true, {})
        end
        return ""
    end

    -- Extract Data (starts at index 10, length is byte_count * 2)
    return string.sub(line, 10, 9 + byte_count * 2)
end

local function parse_intel_hex_block(text)
    local lines = vim.split(text, "\n", { plain = true })
    local raw_hex = ""
    for _, line in ipairs(lines) do
        local clean_line = string.gsub(line, "^%s*", "")
        if string.match(clean_line, "^:") then
            raw_hex = raw_hex .. parse_intel_hex_line(clean_line, true)
        end
    end
    return raw_hex
end

local function hex_to_ascii_string(hex)
    local res = ""
    local i = 1
    while i <= #hex do
        local byte_hex = string.sub(hex, i, i + 1)
        if #byte_hex < 2 then
            break
        end
        local char_code = tonumber(byte_hex, 16)
        if char_code then
            res = res .. string.char(char_code)
        end
        i = i + 2
    end
    return res
end

local function update_line_checksum(lnum)
    local line = vim.fn.getline(lnum)
    -- Remove whitespace
    local clean_line = string.gsub(line, "^%s*", "")
    clean_line = string.gsub(clean_line, "%s*$", "")

    if not string.match(clean_line, "^:") then
        return false
    end

    local content = string.sub(clean_line, 2)
    -- Min length: LL (2) + AAAA (4) + TT (2) + CC (2) = 10 chars
    if #content < 10 then
        return false
    end

    -- Check if the length is even (hex pairs)
    if #content % 2 ~= 0 then
        return false
    end

    -- The data to sum is everything excluding the last byte (2 chars) which is the old checksum
    local data_hex = string.sub(content, 1, -3)

    local sum = 0
    local i = 1
    while i <= #data_hex do
        local byte_hex = string.sub(data_hex, i, i + 1)
        local val = tonumber(byte_hex, 16)
        if not val then
            return false
        end
        sum = sum + val
        i = i + 2
    end

    local checksum = (0x100 - (sum % 0x100)) % 0x100
    local new_checksum_hex = string.format("%02X", checksum)

    -- Reconstruct the line: Original indentation + : + data + new checksum
    local indent = string.match(line, "^%s*") or ""
    local new_line = indent .. ":" .. data_hex .. new_checksum_hex

    if new_line ~= line then
        vim.fn.setline(lnum, new_line)
        return true
    end
    return false
end

function M.HexToAscii(is_visual)
    local hex_data = ""

    if is_visual then
        local text = get_visual_selection()
        -- Check if it looks like Intel Hex (contains lines starting with :)
        if string.match(text, "^%s*:") or string.match(text, "\n%s*:") then
            hex_data = parse_intel_hex_block(text)
        else
            hex_data = clean_hex(text)
        end
    else
        -- Normal mode: Current line
        local line = vim.fn.getline(".")
        if string.match(line, "^%s*:") then
            local clean_line = string.gsub(line, "^%s*", "")
            hex_data = parse_intel_hex_line(clean_line, false)
        else
            vim.api.nvim_echo({
                {
                    "Current line is not a valid Intel HEX record (must start with ':')",
                    "ErrorMsg",
                },
            }, true, {})
            return
        end
    end

    if hex_data == "" then
        print("No valid hex data found.")
        return
    end

    -- Convert hex_data (raw hex string) to ASCII
    local result = hex_to_ascii_string(hex_data)

    -- Echo result
    print("Decoded: " .. result)

    -- Copy to clipboard
    vim.fn.setreg('"', result)
    if vim.fn.has("clipboard") == 1 then
        vim.fn.setreg("+", result)
        vim.api.nvim_out_write(" (Copied to clipboard)\n")
    else
        vim.api.nvim_out_write(' (Copied to register ")\n')
    end
end

function M.AsciiToHex()
    local text = get_visual_selection()
    if text == "" then
        print("No selection found")
        return
    end

    local hex_values = {}
    -- Use vim.fn.str2list to handle multi-byte characters correctly
    local codes = vim.fn.str2list(text)
    for _, code in ipairs(codes) do
        table.insert(hex_values, string.format("%02X", code))
    end

    local result = table.concat(hex_values, " ")

    -- Copy to system clipboard if available
    if vim.fn.has("clipboard") == 1 then
        vim.fn.setreg("+", result)
        vim.fn.setreg("*", result)
    end

    -- Also copy to unnamed register for convenience
    vim.fn.setreg('"', result)

    print("Copied ASCII Hex: " .. result)
end

function M.UpdateIntelHexChecksum()
    local start_line = 1
    local end_line = vim.fn.line("$")

    local count = 0
    for lnum = start_line, end_line do
        if update_line_checksum(lnum) then
            count = count + 1
        end
    end

    if count > 0 then
        print("Updated checksum for " .. count .. " line(s).")
    else
        print("No checksums updated.")
    end
end

function M.setup(_)
    vim.api.nvim_create_user_command("RkHexToAscii", function(opts)
        M.HexToAscii(opts.range ~= 0)
    end, { range = true, bar = true })

    vim.api.nvim_create_user_command("RkHexChecksum", function(_)
        M.UpdateIntelHexChecksum()
    end, { range = "%", bar = true })

    vim.api.nvim_create_user_command("RkHexFromAscii", function(_)
        M.AsciiToHex()
    end, { range = true, bar = true })
end

return M
