local property = {
    handler = nil,
    build_dir = "",
    compiler = "",
    sources = {},
    includes = {},
    defines = {},
    extra_flags = {},
}

local function init(loc)
    property.handler = io.open(loc .. "/compile_commands.json", "w")
    if not property.handler then
        print(
            "rookie_clangd.generator.init: Could not open or create [compile_commands.json] for writing"
        )
        return false
    end
    return true
end

local function set_sources(sources)
    for _, v in ipairs(sources) do
        v = v:gsub("\\", "/")
        table.insert(property.sources, v)
    end
end

local function set_defines(defines)
    property.defines = defines
    -- for _, define in ipairs(defines) do
    --     table.insert(property.defines, define)
    -- end
end

local function set_includes(includes)
    for _, include in ipairs(includes) do
        table.insert(property.includes, include)
    end
end

local function set_extra_flags(extra_flags)
    for _, flag in ipairs(extra_flags) do
        table.insert(property.extra_flags, flag)
    end
end

local function set_build_dir(build_dir)
    build_dir = build_dir:gsub("\\", "/")
    property.build_dir = build_dir
end

local function set_compiler(compiler)
    property.compiler = compiler
end

local function writeln(content)
    property.handler:write(content .. "\n")
end

local function write_directory(build_dir)
    property.handler:write('    "directory": "' .. build_dir .. '",')
end

local function write_command(compiler)
    property.handler:write('    "command": "\\"' .. compiler .. '\\" ')
end

local function write_file(source)
    property.handler:write('    "file": "' .. source .. '",')
end

local function write_output(source)
    property.handler:write('    "output": "' .. source .. '.o"')
end

local function append_extra_flags(extflags)
    for _, flag in ipairs(extflags) do
        property.handler:write('\\"' .. flag .. '\\" ')
    end
end

local function append_includes(includes)
    for _, dir in ipairs(includes) do
        dir = dir:gsub("\\", "/")
        -- Add -I flag for clangd
        property.handler:write('\\"-I' .. dir .. '\\" ')
    end
end

local function append_source(source)
    property.handler:write(source .. '",')
end

local function append_defines(defines)
    for _, define in ipairs(defines) do
        -- Add -D flag for clangd
        property.handler:write('\\"-D' .. define .. '\\" ')
    end
end

local function finish()
    local extra_flags = property.extra_flags
    local compiler = property.compiler
    local sources = property.sources
    local includes = property.includes
    local defines = property.defines
    local build_dir = property.build_dir
    local file = property.handler

    if not file then
        return
    end

    writeln("[")
    for index, source in ipairs(sources) do
        writeln("  {")
        -- directory section
        write_directory(build_dir)
        writeln("")
        -- command section
        write_command(compiler)
        append_extra_flags(extra_flags)
        append_includes(includes)
        append_defines(defines)
        append_source(source)
        writeln("")
        -- file section
        write_file(source)
        writeln("")
        -- output section
        write_output(source)
        writeln("")
        -- final
        if index == #sources then
            writeln("  }")
        else
            writeln("  },")
        end
    end
    writeln("]")

    file:close() -- Close the file
end

return {
    init = init,
    finish = finish,
    set_sources = set_sources,
    set_defines = set_defines,
    set_includes = set_includes,
    set_extra_flags = set_extra_flags,
    set_build_dir = set_build_dir,
    set_compiler = set_compiler,
    property = property,
}
