local M = {}

local function info_file_path()
    local base
    if vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
        base = vim.fn.expand("$HOME/vimfiles")
    else
        base = vim.fn.expand("$HOME/.vim")
    end
    if base == "" then
        base = vim.fn.expand("~")
    end
    return base .. "/.rookie_toys_project.csv"
end

local function ensure_info_file()
    local f = info_file_path()
    if vim.fn.filereadable(f) == 0 then
        local dir = vim.fn.fnamemodify(f, ":h")
        if vim.fn.isdirectory(dir) == 0 then
            vim.fn.mkdir(dir, "p")
        end
        vim.fn.writefile({}, f)
        vim.api.nvim_echo(
            { { "Projects does not exist, please add one.", "WarningMsg" } },
            true,
            {}
        )
    end
end

local function read_projects()
    local f = info_file_path()
    if vim.fn.filereadable(f) == 0 then
        return {}
    end
    local lines = vim.fn.readfile(f)
    local res = {}
    for _, l in ipairs(lines) do
        if l ~= "" then
            local parts = vim.split(l, ",")
            if #parts >= 2 then
                local name = parts[1]
                local path = table.concat(parts, ",", 2)
                table.insert(res, { name = name, path = path })
            end
        end
    end
    return res
end

local function write_projects(projects)
    local lines = {}
    for _, p in ipairs(projects) do
        table.insert(lines, p.name .. "," .. p.path)
    end
    vim.fn.writefile(lines, info_file_path())
end

local function name_width(projects)
    local w = 0
    for _, p in ipairs(projects) do
        w = math.max(w, vim.fn.strdisplaywidth(p.name))
    end
    return w
end

local function set_quickfix(projects)
    local w = name_width(projects)
    local qf = {}
    for idx, p in ipairs(projects) do
        local text = string.format("%-" .. w .. "s | %s", p.name, p.path)
        table.insert(qf, { lnum = idx, text = text })
    end
    vim.fn.setqflist(qf, "r")
    vim.cmd("copen")

    vim.b.rookie_project_qf_name_width = w
    vim.b.rookie_project_items = projects

    vim.keymap.set("n", "<CR>", function()
        require("rookie_toys.rk_project").open_selected_project()
    end, { buffer = true, noremap = true, silent = true })
end

function M.project_list()
    ensure_info_file()
    local projects = read_projects()
    set_quickfix(projects)
end

function M.open_selected_project()
    if vim.bo.buftype ~= "quickfix" then
        return
    end
    if not vim.b.rookie_project_items then
        return
    end

    local idx = vim.fn.line(".")
    local items = vim.b.rookie_project_items
    if idx < 1 or idx > #items then
        return
    end
    local prj = items[idx]

    local has_tree = false
    if vim.fn.exists(":NvimTreeToggle") == 2 then
        for _, b in ipairs(vim.fn.getbufinfo({ bufloaded = 1 })) do
            if vim.bo[b.bufnr].filetype == "NvimTree" then
                has_tree = true
                break
            end
        end
    end

    pcall(vim.keymap.del, "n", "<CR>", { buffer = true })
    vim.cmd("cclose")
    vim.cmd("silent! %bd!")

    if vim.fn.isdirectory(prj.path) == 1 then
        vim.cmd("cd " .. vim.fn.fnameescape(prj.path))

        -- assuming rooter is configured globally or through a different lua module if necessary.
        -- If we needed to call rookie_rooter#Lock we could use vim.fn['rookie_rooter#Lock'](time)

        if has_tree then
            local status, api = pcall(require, "nvim-tree.api")
            if status then
                api.tree.open({ path = prj.path })
            end
        end
    end

    vim.api.nvim_echo(
        { { "Opened [" .. prj.name .. "] at [" .. prj.path .. "]", "None" } },
        true,
        {}
    )

    local all = read_projects()
    local filtered = {}
    for _, p in ipairs(all) do
        if not (p.name == prj.name and p.path == prj.path) then
            table.insert(filtered, p)
        end
    end

    local newlist = { prj }
    for _, p in ipairs(filtered) do
        table.insert(newlist, p)
    end
    write_projects(newlist)
end

function M.project_add()
    ensure_info_file()
    local path = vim.fn.getcwd()
    local name = vim.fn.input("Enter project name: ")
    if name == "" then
        name = vim.fn.fnamemodify(path, ":t")
    end

    local projects = read_projects()
    local exists = false
    for _, p in ipairs(projects) do
        if p.name == name then
            exists = true
            break
        end
    end

    if exists then
        local ans = vim.fn.input(
            "Project '"
                .. name
                .. "' exists. Overwrite with current path? (y/N): "
        )
        if ans:lower() ~= "y" then
            vim.api.nvim_echo(
                { { "Project add canceled.", "WarningMsg" } },
                true,
                {}
            )
            return
        end
        local out = {}
        for _, p in ipairs(projects) do
            if p.name == name then
                table.insert(out, { name = name, path = path })
            else
                table.insert(out, p)
            end
        end
        write_projects(out)
        vim.api.nvim_echo(
            { { "Project " .. name .. " updated to " .. path, "None" } },
            true,
            {}
        )
        return
    end

    table.insert(projects, { name = name, path = path })
    write_projects(projects)
    vim.api.nvim_echo(
        { { "Project " .. name .. " added at " .. path, "None" } },
        true,
        {}
    )
end

function M.project_remove()
    if vim.bo.buftype ~= "quickfix" then
        return
    end
    if not vim.b.rookie_project_items then
        return
    end

    local idx = vim.fn.line(".")
    local items = vim.b.rookie_project_items
    if idx < 1 or idx > #items then
        return
    end

    local prj = items[idx]
    local all = read_projects()
    local out = {}
    for _, p in ipairs(all) do
        if not (p.name == prj.name and p.path == prj.path) then
            table.insert(out, p)
        end
    end

    write_projects(out)
    vim.api.nvim_echo(
        { { "Project " .. prj.name .. " removed.", "None" } },
        true,
        {}
    )
    set_quickfix(out)
end

function M.project_rename()
    if vim.bo.buftype ~= "quickfix" then
        return
    end
    if not vim.b.rookie_project_items then
        return
    end

    local idx = vim.fn.line(".")
    local items = vim.b.rookie_project_items
    if idx < 1 or idx > #items then
        return
    end

    local prj = items[idx]
    local newname = vim.fn.input("Enter new project name: ")
    if newname == "" then
        newname = prj.name
    end

    local all = read_projects()
    local out = {}
    for _, p in ipairs(all) do
        if p.name == prj.name and p.path == prj.path then
            table.insert(out, { name = newname, path = p.path })
        else
            table.insert(out, p)
        end
    end

    write_projects(out)
    set_quickfix(out)
end

function M.setup()
    -- Commands
    vim.api.nvim_create_user_command("RkProjectAdd", function()
        M.project_add()
    end, { desc = "Add current directory as a project" })

    vim.api.nvim_create_user_command("RkProjectRemove", function()
        M.project_remove()
    end, { desc = "Remove selected project from list" })

    vim.api.nvim_create_user_command("RkProjectList", function()
        M.project_list()
    end, { desc = "List and manage projects" })

    vim.api.nvim_create_user_command("RkProjectRename", function()
        M.project_rename()
    end, { desc = "Rename selected project" })

    -- Keymaps
    vim.keymap.set(
        "n",
        "<leader>pa",
        "<cmd>RkProjectAdd<CR>",
        { desc = "Rookie Project: Add" }
    )
    vim.keymap.set(
        "n",
        "<leader>pdel",
        "<cmd>RkProjectRemove<CR>",
        { desc = "Rookie Project: Remove" }
    )
    vim.keymap.set(
        "n",
        "<leader>pj",
        "<cmd>RkProjectList<CR>",
        { desc = "Rookie Project: List" }
    )
    vim.keymap.set(
        "n",
        "<leader>prn",
        "<cmd>RkProjectRename<CR>",
        { desc = "Rookie Project: Rename" }
    )
end

return M
