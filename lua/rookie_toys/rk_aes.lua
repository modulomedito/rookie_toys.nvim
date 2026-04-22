local M = {}

-- Store the AES key
local aes_key = nil

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

function M.set_aes_key(opts)
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

    if #hex ~= 32 and #hex ~= 64 then
        vim.api.nvim_err_writeln("AES key must be 128-bit (32 hex chars) or 256-bit (64 hex chars). Current length: " .. #hex)
        return
    end

    aes_key = hex
    vim.api.nvim_echo({{"AES key set to: " .. aes_key, "Normal"}}, true, {})
end

function M.do_aes(opts, cipher, is_encrypt)
    if not aes_key then
        vim.api.nvim_err_writeln("AES key not set. Use RkAesKeyHex first.")
        return
    end

    local expected_key_len = (cipher == "aes-128-ecb") and 32 or 64
    if #aes_key ~= expected_key_len then
        vim.api.nvim_err_writeln("AES key length mismatch. Expected " .. expected_key_len .. " hex chars for " .. cipher)
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

    -- Embedded systems usually do not use PKCS#7 padding for raw hex blocks
    local nopad_arg = "-nopad"

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

    local enc_dec_arg = is_encrypt and "-e" or "-d"

    -- Command: openssl enc -aes-128-ecb -e -K <key> -in <in> -out <out> -nopad
    local cmd = string.format('openssl enc -%s %s -K %s -in "%s" -out "%s" %s',
        cipher, enc_dec_arg, aes_key, tmp_in, tmp_out, nopad_arg)

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
        vim.fn.setreg("+", out_hex)
        vim.api.nvim_echo({{"AES result copied to clipboard: " .. out_hex, "Normal"}}, true, {})
    else
        vim.api.nvim_err_writeln("AES operation produced no output.")
    end
end

function M.setup()
    vim.api.nvim_create_user_command("RkAesKeyHex", function(opts)
        M.set_aes_key(opts)
    end, { range = true, desc = "Set AES key from selected hex content" })

    vim.api.nvim_create_user_command("RkAes128EcbEncHex", function(opts)
        M.do_aes(opts, "aes-128-ecb", true)
    end, { range = true, desc = "AES-128 ECB Encrypt selected hex content" })

    vim.api.nvim_create_user_command("RkAes128EcbDecHex", function(opts)
        M.do_aes(opts, "aes-128-ecb", false)
    end, { range = true, desc = "AES-128 ECB Decrypt selected hex content" })

    vim.api.nvim_create_user_command("RkAes256EcbEncHex", function(opts)
        M.do_aes(opts, "aes-256-ecb", true)
    end, { range = true, desc = "AES-256 ECB Encrypt selected hex content" })

    vim.api.nvim_create_user_command("RkAes256EcbDecHex", function(opts)
        M.do_aes(opts, "aes-256-ecb", false)
    end, { range = true, desc = "AES-256 ECB Decrypt selected hex content" })
end

return M