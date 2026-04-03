local M = {}

-- Function to get label for a specific tab
local function get_tab_label(tab)
    local winnr = vim.fn.tabpagewinnr(tab)
    local buflist = vim.fn.tabpagebuflist(tab)
    local bufnr = buflist[winnr]
    local bufname = vim.fn.bufname(bufnr)
    local bufmodified = vim.fn.getbufvar(bufnr, "&mod")

    local label = ""
    local ok, tabname =
        pcall(vim.api.nvim_tabpage_get_var, tab, "rookie_tab_name")
    if ok and tabname and tabname ~= "" then
        label = tabname
    elseif bufname == "" then
        label = "[No Name]"
    else
        label = vim.fn.fnamemodify(bufname, ":t")
    end

    if bufmodified == 1 then
        label = label .. " [+]"
    end
    return label
end

-- TabLine generator for console nvim
function M.tabline()
    local s = ""
    for i = 1, vim.fn.tabpagenr("$") do
        local tab = i
        -- Set the tab page number (for mouse clicks)
        s = s .. "%" .. tab .. "T"
        -- Highlight current tab
        if tab == vim.fn.tabpagenr() then
            s = s .. "%#TabLineSel#"
        else
            s = s .. "%#TabLine#"
        end
        -- Add tab index and label
        s = s .. " " .. tab .. ":" .. get_tab_label(tab) .. " "
    end
    -- Reset highlighting and add empty space at end
    s = s .. "%#TabLineFill#%T"
    return s
end

-- GuiTabLabel for GUI clients (gvim, neovide, etc.)
function M.gui_tab_label()
    return get_tab_label(vim.v.lnum)
end

-- Main function to rename the current tab
function M.rename(name)
    if name == nil or name == "" then
        name = vim.fn.input("New tab name: ")
    end

    -- Set tab-local variable
    vim.api.nvim_tabpage_set_var(0, "rookie_tab_name", name)

    -- Activate tabline/guitablabel if not already active
    if vim.g.rookie_tabrename_active ~= 1 then
        vim.opt.tabline = "%!v:lua.require'rookie_toys.rk_tabrename'.tabline()"
        if vim.fn.has("gui_running") == 1 then
            vim.opt.guitablabel =
                "%!v:lua.require'rookie_toys.rk_tabrename'.gui_tab_label()"
        end
        vim.g.rookie_tabrename_active = 1
    end

    -- Force redraw
    vim.cmd("redrawtabline")
end

-- Setup function for the module
function M.setup()
    -- Create user command for tab renaming
    vim.api.nvim_create_user_command("RkTabrenameRename", function(opts)
        M.rename(opts.args)
    end, { nargs = "?", desc = "Rename the current tab" })

    -- Map <leader>rrr to rename the current tab
    vim.keymap.set("n", "<leader>rrr", function()
        M.rename()
    end, { desc = "Rename current tab", silent = true })
end

return M
