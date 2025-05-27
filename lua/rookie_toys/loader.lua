local utils = require("rookie_clangd.utils")

local property = {
    active_preset_index = 0,
}

local function set_active_preset_index(i)
    property.active_preset_index = i
end

local function get_related_preset_index(working_dir)
    local presets = Rookie_clangd_config.preset
    if presets == {} then
        return {}
    end

    local index = {}
    for i, preset in ipairs(presets) do
        if utils.is_in_table(preset.project_dir, working_dir) then
            table.insert(index, i)
        end
    end
    return index
end

local function get_active_preset(working_dir)
    local related_preset_index = get_related_preset_index(working_dir)
    -- No related
    if related_preset_index == {} then
        return nil
    end
    -- Search the active one
    for _, v in ipairs(related_preset_index) do
        if v == property.active_preset_index then
            return Rookie_clangd_config.preset[v]
        end
    end
    -- The active not found, use the first
    set_active_preset_index(related_preset_index[1])
    return Rookie_clangd_config.preset[property.active_preset_index]
end

local function load_extra_flags(working_dir)
    local preset = get_active_preset(working_dir)
    if preset and preset.extra_flags then
        return preset.extra_flags
    else
        return Rookie_clangd_config.extra_flags
    end
end

local function load_exclude_dir(working_dir)
    local preset = get_active_preset(working_dir)
    if preset and preset.exclude_dir then
        return preset.exclude_dir
    else
        return Rookie_clangd_config.exclude_dir
    end
end

local function load_compiler(working_dir)
    local preset = get_active_preset(working_dir)
    if preset and preset.compiler then
        return preset.compiler
    else
        return Rookie_clangd_config.compiler
    end
end

local function load_source_pattern(working_dir)
    local preset = get_active_preset(working_dir)
    if preset and preset.source_pattern then
        return preset.source_pattern
    else
        return Rookie_clangd_config.source_pattern
    end
end

local function load_header_pattern(working_dir)
    local preset = get_active_preset(working_dir)
    if preset and preset.header_pattern then
        return preset.header_pattern
    else
        return Rookie_clangd_config.header_pattern
    end
end

local function load_define(working_dir)
    local preset = get_active_preset(working_dir)
    if preset and preset.define then
        return preset.define
    else
        return Rookie_clangd_config.define
    end
end

local function load_include(working_dir)
    local preset = get_active_preset(working_dir)
    if preset and preset.include then
        return preset.include
    else
        return Rookie_clangd_config.include
    end
end

local function load_hooks(working_dir)
    local preset = get_active_preset(working_dir)
    if preset and preset.hooks then
        return preset.hooks
    else
        return Rookie_clangd_config.hooks
    end
end

return {
    load_compiler = load_compiler,
    load_define = load_define,
    load_exclude_dir = load_exclude_dir,
    load_extra_flags = load_extra_flags,
    load_header_pattern = load_header_pattern,
    load_hooks = load_hooks,
    load_include = load_include,
    load_source_pattern = load_source_pattern,
    set_active_preset_index = set_active_preset_index,
}
