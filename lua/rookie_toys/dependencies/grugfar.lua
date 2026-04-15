local M = {}

local function get_visual_selection()
    local saved_reg = vim.fn.getreg("v")
    vim.cmd('noau normal! "vy')
    local text = vim.fn.getreg("v")
    vim.fn.setreg("v", saved_reg)
    text = text:gsub("\n", "")
    return text
end

local function open_grugfar(opts)
    local ok, grugfar = pcall(require, "grug-far")
    if not ok then
        vim.notify("grug-far is not installed", vim.log.levels.WARN)
        return
    end

    local base = {
        prefills = {
            paths = vim.fn.getcwd(),
        },
    }
    local final_opts = vim.tbl_deep_extend("force", base, opts or {})
    grugfar.open(final_opts)
end

function M.setup()
    -- -- Match telescope.lua keymaps for search/replace workflow.
    -- vim.keymap.set("n", "<leader>sg", function()
    --     open_grugfar()
    -- end, { desc = "Rookie Live Grep (grug-far)" })

    -- vim.keymap.set("v", "<leader>sg", function()
    --     local text = get_visual_selection()
    --     open_grugfar({ prefills = { search = text } })
    -- end, { desc = "Rookie Live Grep (grug-far) from selection" })

    vim.keymap.set("n", "<leader><F2>", function()
        local search_text = vim.fn.expand("<cword>")
        open_grugfar({ prefills = { search = search_text } })
    end, { desc = "Rookie Global Replace (grug-far)" })

    vim.keymap.set("v", "<leader><F2>", function()
        local text = get_visual_selection()
        open_grugfar({ prefills = { search = text } })
    end, { desc = "Global Replace Selection (Rookie Toys, grug-far)" })

    vim.keymap.set("n", "<leader><leader><F2>", function()
        if vim.fn.exists(":RkGlobalReplaceUndo") == 2 then
            vim.cmd("RkGlobalReplaceUndo")
            return
        end
        vim.notify(
            "Global replace undo is only available in Telescope flow",
            vim.log.levels.INFO
        )
    end, { desc = "Rookie Global Replace Undo" })
end

return M
