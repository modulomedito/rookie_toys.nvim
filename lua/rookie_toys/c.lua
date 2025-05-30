local utils = require("rookie_toys.utils")

local function toggle_source_header()
    local current_dir = vim.fn.getcwd()
    local current_file_ext = vim.fn.expand("%:t")
    local current_ext = vim.fn.expand("%:e")
    local target_file = ""
    local exclude_folders = { ".git", ".cache", ".vscode", "build" }

    if current_ext ~= "c" and current_ext ~= "h" then
        return
    end

    if current_ext == "c" then
        target_file = current_file_ext:gsub("%.c$", ".h")
    elseif current_ext == "h" then
        target_file = current_file_ext:gsub("%.h$", ".c")
    end

    local found_path = utils.find_file_in_dir_recursive(current_dir, exclude_folders, target_file)
    if found_path == "" then
        print("Source/Header not found.")
        return
    end
    vim.cmd("edit " .. found_path)
end


-- Prevent Clangd stop when too many errors emitted
vim.g.rookie_toys_c_clangd_extra_flags = { "-ferror-limit=3000" }
vim.g.rookie_toys_c_clangd_include_exclude_dirs = { ".git", ".cache", ".vscode" }
vim.g.rookie_toys_c_clangd_defines = {}

local function set_ccj_exclude_dirs(exclude_dirs)
    vim.g.rookie_toys_c_clangd_include_exclude_dirs = exclude_dirs
end

local function set_ccj_extra_flags(extra_flags)
    vim.g.rookie_toys_c_clangd_extra_flags = extra_flags
end

local function add_ccj_define_symbol()
    local current_word = vim.fn.expand("<cword>")
    local define_table = vim.g.rookie_toys_c_clangd_defines
    if utils.is_in_table(define_table, current_word) == false then
        table.insert(define_table, current_word)
    end
end

local function remove_ccj_define_symbol()
    local current_word = vim.fn.expand("<cword>")
    local define_table = vim.g.rookie_toys_c_clangd_defines
    if utils.is_in_table(define_table, current_word) == true then
        local index = utils.get_element_index(define_table, current_word)
        table.remove(define_table, index)
    end
end

local function generate_compile_commands_json()
    local current_dir = vim.fn.getcwd()
    current_dir = current_dir:gsub("\\", "/")

    local ccj_file_handler = io.open(current_dir .. "/compile_commands.json", "w")
    if not ccj_file_handler then
        print("Could not open or create [compile_commands.json] for writing")
        return false
    end

    -- File handler manipulation
    local function writeln(content)
        ccj_file_handler:write(content .. "\n")
    end
    local function write_directory_section(build_dir)
        ccj_file_handler:write('    "directory": "' .. build_dir .. '",')
    end
    local function write_command_section(compiler)
        ccj_file_handler:write('    "command": "\\"' .. compiler .. '\\" ')
    end
    local function append_extra_flags(extflags)
        for _, flag in ipairs(extflags) do
            ccj_file_handler:write('\\"' .. flag .. '\\" ')
        end
    end
    local function append_includes(includes)
        for _, dir in ipairs(includes) do
            dir = dir:gsub("\\", "/")
            ccj_file_handler:write('\\"-I' .. dir .. '\\" ')
        end
    end
    local function append_defines(defines)
        for _, define in ipairs(defines) do
            ccj_file_handler:write('\\"-D' .. define .. '\\" ')
        end
    end
    local function append_source(source)
        ccj_file_handler:write(source .. '",')
    end
    local function write_file_section(source)
        ccj_file_handler:write('    "file": "' .. source .. '",')
    end
    local function write_output_section(source)
        ccj_file_handler:write('    "output": "' .. source .. '.o"')
    end

    -- Set inputs
    local sources = {}
    local source_pattern = { "c" }
    for _, pattern in ipairs(source_pattern) do
        for _, v in ipairs(utils.get_filepath_recursive(current_dir, pattern)) do
            v = v:gsub("\\", "/")
            table.insert(sources, v)
        end
    end

    local includes = {}
    local excludes = vim.g.rookie_toys_c_clangd_include_exclude_dirs
    local header_pattern = { "h", "h.in" }
    for _, pattern in ipairs(header_pattern) do
        for _, v in ipairs(utils.get_container_dirs(current_dir, excludes, pattern)) do
            v = v:gsub("\\", "/")
            table.insert(includes, v)
        end
    end

    local defines = vim.g.rookie_toys_c_clangd_defines
    local extra_flags = vim.g.rookie_toys_c_clangd_extra_flags
    local compiler = "clang"
    local build_dir = current_dir

    -- Generate the json file
    writeln("[")
    for index, source in ipairs(sources) do
        writeln("  {")
        write_directory_section(build_dir)
        writeln("")
        write_command_section(compiler)
        append_extra_flags(extra_flags)
        append_includes(includes)
        append_defines(defines)
        append_source(source)
        writeln("")
        write_file_section(source)
        writeln("")
        write_output_section(source)
        writeln("")
        if index == #sources then
            writeln("  }")
        else
            writeln("  },")
        end
    end
    writeln("]")

    ccj_file_handler:close()
end

return {
    toggle_source_header = toggle_source_header,
    set_ccj_exclude_dirs = set_ccj_exclude_dirs,
    add_ccj_define_symbol = add_ccj_define_symbol,
    set_ccj_extra_flags = set_ccj_extra_flags,
    remove_ccj_define_symbol = remove_ccj_define_symbol,
    generate_compile_commands_json = generate_compile_commands_json,
}
