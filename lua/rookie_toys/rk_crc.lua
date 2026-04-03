local bit = require("bit")
local band, bor, lshift, rshift, bxor =
    bit.band, bit.bor, bit.lshift, bit.rshift, bit.bxor

local M = {}

local function format_hex(val, bits)
    if bits == 32 then
        return "0x" .. string.upper(bit.tohex(val, 8))
    elseif bits == 16 then
        return "0x" .. string.upper(bit.tohex(val, 4))
    else
        return "0x" .. string.upper(bit.tohex(val, 2))
    end
end

function M.Reflect(val, bits)
    local res = 0
    local v = val
    for i = 1, bits do
        res = bor(lshift(res, 1), band(v, 1))
        v = rshift(v, 1)
    end
    return res
end

local tables_normal = {}
local tables_reflected = {}

local function GetTableNormal(poly, bits)
    local key = string.format("%d_%x", bits, poly)
    if tables_normal[key] then
        return tables_normal[key]
    end
    local table_data = {}
    local mask = bits == 32 and 0x80000000 or (bits == 16 and 0x8000 or 0x80)
    local full_mask = bits == 32 and 0xFFFFFFFF
        or (bits == 16 and 0xFFFF or 0xFF)
    for i = 0, 255 do
        local crc = lshift(i, bits - 8)
        for _ = 1, 8 do
            if band(crc, mask) ~= 0 then
                crc = bxor(lshift(crc, 1), poly)
            else
                crc = lshift(crc, 1)
            end
            if bits ~= 32 then
                crc = band(crc, full_mask)
            end
        end
        table_data[i] = crc
    end
    tables_normal[key] = table_data
    return table_data
end

local function GetTableReflected(poly, bits)
    local key = string.format("%d_%x", bits, poly)
    if tables_reflected[key] then
        return tables_reflected[key]
    end
    local ref_poly = M.Reflect(poly, bits)
    local table_data = {}
    local full_mask = bits == 32 and 0xFFFFFFFF
        or (bits == 16 and 0xFFFF or 0xFF)
    for i = 0, 255 do
        local crc = i
        for _ = 1, 8 do
            if band(crc, 1) ~= 0 then
                crc = bxor(rshift(crc, 1), ref_poly)
            else
                crc = rshift(crc, 1)
            end
            if bits ~= 32 then
                crc = band(crc, full_mask)
            end
        end
        table_data[i] = crc
    end
    tables_reflected[key] = table_data
    return table_data
end

function M.ComputeCrc(data, bits, poly, init, ref_in, ref_out, xor_out)
    local crc = init
    local full_mask = bits == 32 and 0xFFFFFFFF
        or (bits == 16 and 0xFFFF or 0xFF)
    if not ref_in then
        local table_data = GetTableNormal(poly, bits)
        for i = 1, #data do
            local byte = string.byte(data, i)
            if bits >= 8 then
                local idx = band(bxor(rshift(crc, bits - 8), byte), 0xFF)
                crc = bxor(lshift(crc, 8), table_data[idx])
            else
                local idx = band(bxor(crc, byte), 0xFF)
                crc = bxor(lshift(crc, 8), table_data[idx])
            end
            if bits ~= 32 then
                crc = band(crc, full_mask)
            end
        end
    else
        local table_data = GetTableReflected(poly, bits)
        for i = 1, #data do
            local byte = string.byte(data, i)
            local idx = band(bxor(crc, byte), 0xFF)
            crc = bxor(rshift(crc, 8), table_data[idx])
            if bits ~= 32 then
                crc = band(crc, full_mask)
            end
        end
    end
    if ref_in ~= ref_out then
        crc = M.Reflect(crc, bits)
    end
    if bits == 32 then
        return bxor(crc, xor_out)
    else
        return band(bxor(crc, xor_out), full_mask)
    end
end

function M.ComputeCrc32(data, poly, init, ref_in, ref_out, xor_out)
    return M.ComputeCrc(data, 32, poly, init, ref_in, ref_out, xor_out)
end

function M.ComputeCrc16(data, poly, init, ref_in, ref_out, xor_out)
    return M.ComputeCrc(data, 16, poly, init, ref_in, ref_out, xor_out)
end

function M.ComputeCrc8(data, poly, init, ref_in, ref_out, xor_out)
    return M.ComputeCrc(data, 8, poly, init, ref_in, ref_out, xor_out)
end

local crc16_algorithms = {
    {
        name = "CRC-16/ARC",
        check = "0xBB3D",
        poly = 0x8005,
        init = 0x0000,
        refin = true,
        refout = true,
        xorout = 0x0000,
    },
    {
        name = "CRC-16/CDMA2000",
        check = "0x4C06",
        poly = 0xC867,
        init = 0xFFFF,
        refin = false,
        refout = false,
        xorout = 0x0000,
    },
    {
        name = "CRC-16/CMS",
        check = "0xAEE7",
        poly = 0x8005,
        init = 0xFFFF,
        refin = false,
        refout = false,
        xorout = 0x0000,
    },
    {
        name = "CRC-16/DDS-110",
        check = "0x9ECF",
        poly = 0x8005,
        init = 0x800D,
        refin = false,
        refout = false,
        xorout = 0x0000,
    },
    {
        name = "CRC-16/DECT-R",
        check = "0x007E",
        poly = 0x0589,
        init = 0x0000,
        refin = false,
        refout = false,
        xorout = 0x0001,
    },
    {
        name = "CRC-16/DECT-X",
        check = "0x007F",
        poly = 0x0589,
        init = 0x0000,
        refin = false,
        refout = false,
        xorout = 0x0000,
    },
    {
        name = "CRC-16/DNP",
        check = "0xEA82",
        poly = 0x3D65,
        init = 0x0000,
        refin = true,
        refout = true,
        xorout = 0xFFFF,
    },
    {
        name = "CRC-16/EN-13757",
        check = "0xC2B7",
        poly = 0x3D65,
        init = 0x0000,
        refin = false,
        refout = false,
        xorout = 0xFFFF,
    },
    {
        name = "CRC-16/GENIBUS",
        check = "0xD64E",
        poly = 0x1021,
        init = 0xFFFF,
        refin = false,
        refout = false,
        xorout = 0xFFFF,
    },
    {
        name = "CRC-16/GSM",
        check = "0xCE3C",
        poly = 0x1021,
        init = 0x0000,
        refin = false,
        refout = false,
        xorout = 0xFFFF,
    },
    {
        name = "CRC-16/IBM-3740",
        check = "0x29B1",
        poly = 0x1021,
        init = 0xFFFF,
        refin = false,
        refout = false,
        xorout = 0x0000,
    },
    {
        name = "CRC-16/IBM-SDLC",
        check = "0x906E",
        poly = 0x1021,
        init = 0xFFFF,
        refin = true,
        refout = true,
        xorout = 0xFFFF,
    },
    {
        name = "CRC-16/ISO-IEC-14443-3-A",
        check = "0xBF05",
        poly = 0x1021,
        init = 0xC6C6,
        refin = true,
        refout = true,
        xorout = 0x0000,
    },
    {
        name = "CRC-16/KERMIT",
        check = "0x2189",
        poly = 0x1021,
        init = 0x0000,
        refin = true,
        refout = true,
        xorout = 0x0000,
    },
    {
        name = "CRC-16/LJ1200",
        check = "0xBDF4",
        poly = 0x6F63,
        init = 0x0000,
        refin = false,
        refout = false,
        xorout = 0x0000,
    },
    {
        name = "CRC-16/M17",
        check = "0x772B",
        poly = 0x5935,
        init = 0xFFFF,
        refin = false,
        refout = false,
        xorout = 0x0000,
    },
    {
        name = "CRC-16/MAXIM-DOW",
        check = "0x44C2",
        poly = 0x8005,
        init = 0x0000,
        refin = true,
        refout = true,
        xorout = 0xFFFF,
    },
    {
        name = "CRC-16/MCRF4XX",
        check = "0x6F91",
        poly = 0x1021,
        init = 0xFFFF,
        refin = true,
        refout = true,
        xorout = 0x0000,
    },
    {
        name = "CRC-16/MODBUS",
        check = "0x4B37",
        poly = 0x8005,
        init = 0xFFFF,
        refin = true,
        refout = true,
        xorout = 0x0000,
    },
    {
        name = "CRC-16/NRSC-5",
        check = "0xA066",
        poly = 0x080B,
        init = 0xFFFF,
        refin = true,
        refout = true,
        xorout = 0x0000,
    },
    {
        name = "CRC-16/OPENSAFETY-A",
        check = "0x5D38",
        poly = 0x5935,
        init = 0x0000,
        refin = false,
        refout = false,
        xorout = 0x0000,
    },
    {
        name = "CRC-16/OPENSAFETY-B",
        check = "0x20FE",
        poly = 0x755B,
        init = 0x0000,
        refin = false,
        refout = false,
        xorout = 0x0000,
    },
    {
        name = "CRC-16/PROFIBUS",
        check = "0xA819",
        poly = 0x1DCF,
        init = 0xFFFF,
        refin = false,
        refout = false,
        xorout = 0xFFFF,
    },
    {
        name = "CRC-16/RIELLO",
        check = "0x63D0",
        poly = 0x1021,
        init = 0xB2AA,
        refin = true,
        refout = true,
        xorout = 0x0000,
    },
    {
        name = "CRC-16/SPI-FUJITSU",
        check = "0xE5CC",
        poly = 0x1021,
        init = 0x1D0F,
        refin = false,
        refout = false,
        xorout = 0x0000,
    },
    {
        name = "CRC-16/T10-DIF",
        check = "0xD0DB",
        poly = 0x8BB7,
        init = 0x0000,
        refin = false,
        refout = false,
        xorout = 0x0000,
    },
    {
        name = "CRC-16/TELEDISK",
        check = "0x0FB3",
        poly = 0xA097,
        init = 0x0000,
        refin = false,
        refout = false,
        xorout = 0x0000,
    },
    {
        name = "CRC-16/TMS37157",
        check = "0x26B1",
        poly = 0x1021,
        init = 0x89EC,
        refin = true,
        refout = true,
        xorout = 0x0000,
    },
    {
        name = "CRC-16/UMTS",
        check = "0xFEE8",
        poly = 0x8005,
        init = 0x0000,
        refin = false,
        refout = false,
        xorout = 0x0000,
    },
    {
        name = "CRC-16/USB",
        check = "0xB4C8",
        poly = 0x8005,
        init = 0xFFFF,
        refin = true,
        refout = true,
        xorout = 0xFFFF,
    },
    {
        name = "CRC-16/XMODEM",
        check = "0x31C3",
        poly = 0x1021,
        init = 0x0000,
        refin = false,
        refout = false,
        xorout = 0x0000,
    },
}

local crc32_algorithms = {
    {
        name = "CRC-32/AIXM",
        check = "0x3010BF7F",
        poly = 0x814141AB,
        init = 0x00000000,
        refin = false,
        refout = false,
        xorout = 0x00000000,
    },
    {
        name = "CRC-32/AUTOSAR",
        check = "0x1697D06A",
        poly = 0xF4ACFB13,
        init = 0xFFFFFFFF,
        refin = true,
        refout = true,
        xorout = 0xFFFFFFFF,
    },
    {
        name = "CRC-32/BASE91-D",
        check = "0x87315576",
        poly = 0xA833982B,
        init = 0xFFFFFFFF,
        refin = true,
        refout = true,
        xorout = 0xFFFFFFFF,
    },
    {
        name = "CRC-32/BZIP2",
        check = "0xFC891918",
        poly = 0x04C11DB7,
        init = 0xFFFFFFFF,
        refin = false,
        refout = false,
        xorout = 0xFFFFFFFF,
    },
    {
        name = "CRC-32/CD-ROM-EDC",
        check = "0x6EC2EDC4",
        poly = 0x8001801B,
        init = 0x00000000,
        refin = true,
        refout = true,
        xorout = 0x00000000,
    },
    {
        name = "CRC-32/CKSUM",
        check = "0x765E7680",
        poly = 0x04C11DB7,
        init = 0x00000000,
        refin = false,
        refout = false,
        xorout = 0xFFFFFFFF,
    },
    {
        name = "CRC-32/ISCSI",
        check = "0xE3069283",
        poly = 0x1EDC6F41,
        init = 0xFFFFFFFF,
        refin = true,
        refout = true,
        xorout = 0xFFFFFFFF,
    },
    {
        name = "CRC-32/ISO-HDLC",
        check = "0xCBF43926",
        poly = 0x04C11DB7,
        init = 0xFFFFFFFF,
        refin = true,
        refout = true,
        xorout = 0xFFFFFFFF,
    },
    {
        name = "CRC-32/JAMCRC",
        check = "0x340BC6D9",
        poly = 0x04C11DB7,
        init = 0xFFFFFFFF,
        refin = true,
        refout = true,
        xorout = 0x00000000,
    },
    {
        name = "CRC-32/MEF",
        check = "0xD2C22F51",
        poly = 0x741B8CD7,
        init = 0xFFFFFFFF,
        refin = true,
        refout = true,
        xorout = 0x00000000,
    },
    {
        name = "CRC-32/MPEG-2",
        check = "0x0376E6E7",
        poly = 0x04C11DB7,
        init = 0xFFFFFFFF,
        refin = false,
        refout = false,
        xorout = 0x00000000,
    },
    {
        name = "CRC-32/XFER",
        check = "0xBD0BE338",
        poly = 0x000000AF,
        init = 0x00000000,
        refin = false,
        refout = false,
        xorout = 0x00000000,
    },
}

local crc8_algorithms = {
    {
        name = "CRC-8/AUTOSAR",
        check = "0xDF",
        poly = 0x2F,
        init = 0xFF,
        refin = false,
        refout = false,
        xorout = 0xFF,
    },
    {
        name = "CRC-8/BLUETOOTH",
        check = "0x26",
        poly = 0xA7,
        init = 0x00,
        refin = true,
        refout = true,
        xorout = 0x00,
    },
    {
        name = "CRC-8/CDMA2000",
        check = "0xDA",
        poly = 0x9B,
        init = 0xFF,
        refin = false,
        refout = false,
        xorout = 0x00,
    },
    {
        name = "CRC-8/DARC",
        check = "0x15",
        poly = 0x39,
        init = 0x00,
        refin = true,
        refout = true,
        xorout = 0x00,
    },
    {
        name = "CRC-8/DVB-S2",
        check = "0xBC",
        poly = 0xD5,
        init = 0x00,
        refin = false,
        refout = false,
        xorout = 0x00,
    },
    {
        name = "CRC-8/GSM-A",
        check = "0x37",
        poly = 0x1D,
        init = 0x00,
        refin = false,
        refout = false,
        xorout = 0x00,
    },
    {
        name = "CRC-8/GSM-B",
        check = "0x94",
        poly = 0x49,
        init = 0x00,
        refin = false,
        refout = false,
        xorout = 0xFF,
    },
    {
        name = "CRC-8/HITAG",
        check = "0xB4",
        poly = 0x1D,
        init = 0xFF,
        refin = false,
        refout = false,
        xorout = 0x00,
    },
    {
        name = "CRC-8/I-432-1",
        check = "0xA1",
        poly = 0x07,
        init = 0x00,
        refin = false,
        refout = false,
        xorout = 0x55,
    },
    {
        name = "CRC-8/I-CODE",
        check = "0x7E",
        poly = 0x1D,
        init = 0xFD,
        refin = false,
        refout = false,
        xorout = 0x00,
    },
    {
        name = "CRC-8/LTE",
        check = "0xEA",
        poly = 0x9B,
        init = 0x00,
        refin = false,
        refout = false,
        xorout = 0x00,
    },
    {
        name = "CRC-8/MAXIM-DOW",
        check = "0xA1",
        poly = 0x31,
        init = 0x00,
        refin = true,
        refout = true,
        xorout = 0x00,
    },
    {
        name = "CRC-8/MIFARE-MAD",
        check = "0x99",
        poly = 0x1D,
        init = 0xC7,
        refin = false,
        refout = false,
        xorout = 0x00,
    },
    {
        name = "CRC-8/NRSC-5",
        check = "0xF7",
        poly = 0x31,
        init = 0xFF,
        refin = false,
        refout = false,
        xorout = 0x00,
    },
    {
        name = "CRC-8/OPENSAFETY",
        check = "0x3E",
        poly = 0x2F,
        init = 0x00,
        refin = false,
        refout = false,
        xorout = 0x00,
    },
    {
        name = "CRC-8/ROHC",
        check = "0xD0",
        poly = 0x07,
        init = 0xFF,
        refin = true,
        refout = true,
        xorout = 0x00,
    },
    {
        name = "CRC-8/SAE-J1850",
        check = "0x4B",
        poly = 0x1D,
        init = 0xFF,
        refin = false,
        refout = false,
        xorout = 0xFF,
    },
    {
        name = "CRC-8/SMBUS",
        check = "0xF4",
        poly = 0x07,
        init = 0x00,
        refin = false,
        refout = false,
        xorout = 0x00,
    },
    {
        name = "CRC-8/TECH-3250",
        check = "0x97",
        poly = 0x1D,
        init = 0xFF,
        refin = true,
        refout = true,
        xorout = 0x00,
    },
    {
        name = "CRC-8/WCDMA",
        check = "0x25",
        poly = 0x9B,
        init = 0x00,
        refin = true,
        refout = true,
        xorout = 0x00,
    },
}

local function UpdateOutputBuffer(lines)
    local bufname = "__Rookie_CRC__"
    local winid = vim.fn.bufwinid(bufname)
    if winid ~= -1 then
        vim.fn.win_gotoid(winid)
    else
        vim.cmd("belowright 32split " .. bufname)
    end

    local bufnr = vim.api.nvim_get_current_buf()
    vim.bo[bufnr].modifiable = true
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

    vim.bo[bufnr].buftype = "nofile"
    vim.bo[bufnr].bufhidden = "hide"
    vim.bo[bufnr].swapfile = false
    vim.bo[bufnr].filetype = "csv"
    vim.bo[bufnr].modifiable = false
end

function M.ShowCrc32(data)
    local lines = {}
    table.insert(
        lines,
        string.format(
            "%-17s, %-10s, %-10s, %-10s, %-10s, %-5s, %-6s, %s,",
            "CRC-32",
            "Result",
            "Check",
            "Poly",
            "Init",
            "RefIn",
            "RefOut",
            "XorOut"
        )
    )

    for _, alg in ipairs(crc32_algorithms) do
        local res = M.ComputeCrc32(
            data,
            alg.poly,
            alg.init,
            alg.refin,
            alg.refout,
            alg.xorout
        )
        local result_str = format_hex(res, 32)
        table.insert(
            lines,
            string.format(
                "%-17s, %-10s, %-10s, %-10s, %-10s, %-5s, %-6s, %s,",
                alg.name,
                result_str,
                alg.check,
                format_hex(alg.poly, 32),
                format_hex(alg.init, 32),
                alg.refin and "true" or "false",
                alg.refout and "true" or "false",
                format_hex(alg.xorout, 32)
            )
        )
    end

    UpdateOutputBuffer(lines)
end

function M.ShowCrc16(data)
    local lines = {}
    table.insert(
        lines,
        string.format(
            "%-25s, %-10s, %-10s, %-10s, %-10s, %-5s, %-6s, %s,",
            "CRC-16",
            "Result",
            "Check",
            "Poly",
            "Init",
            "RefIn",
            "RefOut",
            "XorOut"
        )
    )

    for _, alg in ipairs(crc16_algorithms) do
        local res = M.ComputeCrc16(
            data,
            alg.poly,
            alg.init,
            alg.refin,
            alg.refout,
            alg.xorout
        )
        local result_str = format_hex(res, 16)
        table.insert(
            lines,
            string.format(
                "%-25s, %-10s, %-10s, %-10s, %-10s, %-5s, %-6s, %s,",
                alg.name,
                result_str,
                alg.check,
                format_hex(alg.poly, 16),
                format_hex(alg.init, 16),
                alg.refin and "true" or "false",
                alg.refout and "true" or "false",
                format_hex(alg.xorout, 16)
            )
        )
    end

    UpdateOutputBuffer(lines)
end

function M.ShowCrc8(data)
    local lines = {}
    table.insert(
        lines,
        string.format(
            "%-17s, %-10s, %-10s, %-10s, %-10s, %-5s, %-6s, %s,",
            "CRC-8",
            "Result",
            "Check",
            "Poly",
            "Init",
            "RefIn",
            "RefOut",
            "XorOut"
        )
    )

    for _, alg in ipairs(crc8_algorithms) do
        local res = M.ComputeCrc8(
            data,
            alg.poly,
            alg.init,
            alg.refin,
            alg.refout,
            alg.xorout
        )
        local result_str = format_hex(res, 8)
        table.insert(
            lines,
            string.format(
                "%-17s, %-10s, %-10s, %-10s, %-10s, %-5s, %-6s, %s,",
                alg.name,
                result_str,
                alg.check,
                format_hex(alg.poly, 8),
                format_hex(alg.init, 8),
                alg.refin and "true" or "false",
                alg.refout and "true" or "false",
                format_hex(alg.xorout, 8)
            )
        )
    end

    UpdateOutputBuffer(lines)
end

local function get_lines()
    local mode = vim.fn.mode()
    local line_start, line_end

    if mode == "v" or mode == "V" or mode == "\22" then
        line_start = vim.fn.line("'<")
        line_end = vim.fn.line("'>")
    else
        line_start = 1
        line_end = vim.fn.line("$")
    end

    return vim.fn.getline(line_start, line_end)
end

function M.Crc16Hex()
    local ok, err = pcall(function()
        local lines = get_lines()
        if type(lines) == "string" then
            lines = { lines }
        end
        if not lines or #lines == 0 then
            return
        end

        local data = {}
        for _, line in ipairs(lines) do
            local clean_line = line:gsub("[^0-9a-fA-F]", "")
            if clean_line ~= "" then
                if #clean_line % 2 ~= 0 then
                    clean_line = clean_line .. "0"
                end
                for i = 1, #clean_line, 2 do
                    local byte_str = clean_line:sub(i, i + 1)
                    table.insert(data, string.char(tonumber(byte_str, 16)))
                end
            end
        end

        M.ShowCrc16(table.concat(data))
    end)
    if not ok then
        vim.api.nvim_err_writeln("RookieCrc16Hex Error: " .. tostring(err))
    end
end

function M.Crc16Ascii()
    local ok, err = pcall(function()
        local lines = get_lines()
        if type(lines) == "string" then
            lines = { lines }
        end
        if not lines or #lines == 0 then
            return
        end

        local data = table.concat(lines, "\n") .. "\n"
        M.ShowCrc16(data)
    end)
    if not ok then
        vim.api.nvim_err_writeln("RookieCrc16Ascii Error: " .. tostring(err))
    end
end

function M.Crc32Hex()
    local ok, err = pcall(function()
        local lines = get_lines()
        if type(lines) == "string" then
            lines = { lines }
        end
        if not lines or #lines == 0 then
            return
        end

        local data = {}
        for _, line in ipairs(lines) do
            local clean_line = line:gsub("[^0-9a-fA-F]", "")
            if clean_line ~= "" then
                if #clean_line % 2 ~= 0 then
                    clean_line = clean_line .. "0"
                end
                for i = 1, #clean_line, 2 do
                    local byte_str = clean_line:sub(i, i + 1)
                    table.insert(data, string.char(tonumber(byte_str, 16)))
                end
            end
        end

        M.ShowCrc32(table.concat(data))
    end)
    if not ok then
        vim.api.nvim_err_writeln("RookieCrc32Hex Error: " .. tostring(err))
    end
end

function M.Crc32Ascii()
    local ok, err = pcall(function()
        local lines = get_lines()
        if type(lines) == "string" then
            lines = { lines }
        end
        if not lines or #lines == 0 then
            return
        end

        local data = table.concat(lines, "\n") .. "\n"
        M.ShowCrc32(data)
    end)
    if not ok then
        vim.api.nvim_err_writeln("RookieCrc32Ascii Error: " .. tostring(err))
    end
end

function M.Crc8Hex()
    local ok, err = pcall(function()
        local lines = get_lines()
        if type(lines) == "string" then
            lines = { lines }
        end
        if not lines or #lines == 0 then
            return
        end

        local data = {}
        for _, line in ipairs(lines) do
            local clean_line = line:gsub("[^0-9a-fA-F]", "")
            if clean_line ~= "" then
                if #clean_line % 2 ~= 0 then
                    clean_line = clean_line .. "0"
                end
                for i = 1, #clean_line, 2 do
                    local byte_str = clean_line:sub(i, i + 1)
                    table.insert(data, string.char(tonumber(byte_str, 16)))
                end
            end
        end

        M.ShowCrc8(table.concat(data))
    end)
    if not ok then
        vim.api.nvim_err_writeln("RookieCrc8Hex Error: " .. tostring(err))
    end
end

function M.Crc8Ascii()
    local ok, err = pcall(function()
        local lines = get_lines()
        if type(lines) == "string" then
            lines = { lines }
        end
        if not lines or #lines == 0 then
            return
        end

        local data = table.concat(lines, "\n") .. "\n"
        M.ShowCrc8(data)
    end)
    if not ok then
        vim.api.nvim_err_writeln("RookieCrc8Ascii Error: " .. tostring(err))
    end
end

function M.setup()
    vim.api.nvim_create_user_command("RkCrc32Hex", function()
        M.Crc32Hex()
    end, { range = true, desc = "Calculate CRC32 for hex data" })

    vim.api.nvim_create_user_command("RkCrc32Ascii", function()
        M.Crc32Ascii()
    end, { range = true, desc = "Calculate CRC32 for ASCII data" })

    vim.api.nvim_create_user_command("RkCrc16Hex", function()
        M.Crc16Hex()
    end, { range = true, desc = "Calculate CRC16 for hex data" })

    vim.api.nvim_create_user_command("RkCrc16Ascii", function()
        M.Crc16Ascii()
    end, { range = true, desc = "Calculate CRC16 for ASCII data" })

    vim.api.nvim_create_user_command("RkCrc8Hex", function()
        M.Crc8Hex()
    end, { range = true, desc = "Calculate CRC8 for hex data" })

    vim.api.nvim_create_user_command("RkCrc8Ascii", function()
        M.Crc8Ascii()
    end, { range = true, desc = "Calculate CRC8 for ASCII data" })
end

return M
