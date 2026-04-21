local M = {}

local function get_path(args)
    if args and args[1] and args[1] ~= "" then
        return args[1]
    end

    if vim.bo.filetype == "nerdtree" and vim.g.NERDTreeFileNode then
        local node = vim.fn["g:NERDTreeFileNode.GetSelected"]()
        if node and node.path then
            return node.path:str()
        end
    end

    -- Support nvim-tree as well since it's common in modern setups
    if vim.bo.filetype == "NvimTree" then
        local status_ok, api = pcall(require, "nvim-tree.api")
        if status_ok then
            local node = api.tree.get_node_under_cursor()
            if node and node.absolute_path then
                return node.absolute_path
            end
        end
    end

    -- Support oil.nvim (since it's the default file browser)
    if vim.bo.filetype == "oil" then
        local status_ok, oil = pcall(require, "oil")
        if status_ok then
            local dir = oil.get_current_dir()
            local entry = oil.get_cursor_entry()
            if dir and entry then
                return dir .. entry.name
            elseif dir then
                return dir
            end
        end
    end

    return vim.fn.expand("%:p")
end

function M.zip(...)
    local path = get_path({ ... })
    if not path or path == "" then
        vim.api.nvim_err_writeln("No path provided")
        return
    end

    path = vim.fn.fnamemodify(path, ":p")
    -- remove trailing slash
    path = path:gsub("[/\\]$", "")

    local dir = vim.fn.fnamemodify(path, ":h")
    local name = vim.fn.fnamemodify(path, ":t")
    local sep = (vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1) and "\\"
        or "/"
    local zip_file = dir .. sep .. name .. ".zip"

    local cmd = string.format('7z a "%s" "%s"', zip_file, path)
    if vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
        vim.cmd('silent !start cmd /c "' .. cmd .. '"')
    else
        vim.cmd("silent !" .. cmd .. " &")
    end
    print(string.format("Zipping %s to %s...", path, zip_file))
end

function M.unzip(...)
    local path = get_path({ ... })
    if not path or path == "" then
        vim.api.nvim_err_writeln("No path provided")
        return
    end

    path = vim.fn.fnamemodify(path, ":p")

    local dir = vim.fn.fnamemodify(path, ":h")
    local name_no_ext = vim.fn.fnamemodify(path, ":t:r")
    local sep = (vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1) and "\\"
        or "/"
    local out_dir = dir .. sep .. name_no_ext

    local cmd = string.format('7z x "%s" -o"%s"', path, out_dir)
    if vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
        vim.cmd('silent !start cmd /c "' .. cmd .. '"')
    else
        vim.cmd("silent !" .. cmd .. " &")
    end
    print(string.format("Unzipping %s to %s...", path, out_dir))
end

function M.setup()
    vim.api.nvim_create_user_command(
        "RkZip",
        function(opts)
            M.zip(opts.args)
        end,
        {
            nargs = "?",
            complete = "file",
            desc = "Zip file or directory using 7z",
        }
    )

    vim.api.nvim_create_user_command("RkUnzip", function(opts)
        M.unzip(opts.args)
    end, { nargs = "?", complete = "file", desc = "Unzip file using 7z" })

    -- Keymaps
    vim.keymap.set(
        "n",
        "<leader>mZ",
        "<cmd>RkZip<CR>",
        { desc = "7z: Zip current file/dir" }
    )
    vim.keymap.set(
        "n",
        "<leader>mz",
        "<cmd>RkUnzip<CR>",
        { desc = "7z: Unzip current file" }
    )
end

return M
