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

return {
    toggle_source_header = toggle_source_header,
}
