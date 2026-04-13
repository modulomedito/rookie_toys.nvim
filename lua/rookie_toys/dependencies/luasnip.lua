local M = {}

function M.setup()
    local ls = require("luasnip")
    local s = ls.snippet
    local t = ls.text_node
    local i = ls.insert_node
    local f = ls.function_node

    -- Helper to get filename without extension
    local function get_filename_no_ext()
        return vim.fn.expand("%:t:r")
    end

    -- Helper to get filename for include guard (e.g., FILE_H)
    local function get_guard()
        local fname = vim.fn.expand("%:t")
        return fname:upper():gsub("%.", "_")
    end

    local doxy = s("doxy", {
        t({
            "/// @brief",
            "/// @details",
            "/// @param[in] None",
            "/// @param[in,out] None",
            "/// @param[out] None",
            "/// @return void",
        }),
    })

    local c80 = s("c80", {
        t(
            "//=============================================================================="
        ),
        t({ "", "/// @file " }),
        f(get_filename_no_ext),
        t(".c"),
        t({ "", "/// @author " }),
        i(1, "User"),
        t(" ("),
        i(2, "user@email.com"),
        t({
            ")",
            "/// @brief",
            "/// @copyright Copyright (C) 2026. All rights reserved.",
            "/// @details",
            "//==============================================================================",
            "//==============================================================================",
            "// INCLUDE",
            "//==============================================================================",
            '#include "',
        }),
        f(get_filename_no_ext),
        t('.h"'),
        t({
            "",
            "",
            "//==============================================================================",
            "// IMPORTED SWITCH CHECK",
            "//==============================================================================",
            "",
            "//==============================================================================",
            "// PRIVATE DEFINE",
            "//==============================================================================",
            "",
            "//==============================================================================",
            "// PRIVATE TYPEDEF",
            "//==============================================================================",
            "",
            "//==============================================================================",
            "// PRIVATE ENUM",
            "//==============================================================================",
            "",
            "//==============================================================================",
            "// PRIVATE STRUCT",
            "//==============================================================================",
            "",
            "//==============================================================================",
            "// PRIVATE UNION",
            "//==============================================================================",
            "",
            "//==============================================================================",
            "// PRIVATE FUNCTION DECLARATION",
            "//==============================================================================",
            "",
            "//==============================================================================",
            "// PRIVATE VARIABLE DEFINITION",
            "//==============================================================================",
            "",
            "//==============================================================================",
            "// PUBLIC VARIABLE DEFINITION",
            "//==============================================================================",
            "",
            "//==============================================================================",
            "// PUBLIC FUNCTION DEFINITION",
            "//==============================================================================",
            "",
            "//==============================================================================",
            "// PRIVATE FUNCTION DEFINITION",
            "//==============================================================================",
            "",
            "//==============================================================================",
            "// TEST",
            "//==============================================================================",
        }),
    })

    local h80 = s("h80", {
        t(
            "//=============================================================================="
        ),
        t({ "", "/// @file " }),
        f(get_filename_no_ext),
        t(".h"),
        t({ "", "/// @author " }),
        i(1, "User"),
        t(" ("),
        i(2, "user@email.com"),
        t({
            ")",
            "/// @brief",
            "/// @copyright Copyright (C) 2026. All rights reserved.",
            "/// @details",
            "//==============================================================================",
            "#ifndef ",
        }),
        f(get_guard),
        t({ "", "#define " }),
        f(get_guard),
        t({
            "",
            "#ifdef __cplusplus",
            'extern "C"',
            "{",
            "#endif",
            "//==============================================================================",
            "// INCLUDE",
            "//==============================================================================",
            "",
            "//==============================================================================",
            "// PUBLIC TYPEDEF",
            "//==============================================================================",
            "",
            "//==============================================================================",
            "// PUBLIC MACRO",
            "//==============================================================================",
            "",
            "//==============================================================================",
            "// PUBLIC ENUM",
            "//==============================================================================",
            "",
            "//==============================================================================",
            "// PUBLIC STRUCT",
            "//==============================================================================",
            "",
            "//==============================================================================",
            "// PUBLIC UNION",
            "//==============================================================================",
            "",
            "//==============================================================================",
            "// PUBLIC VARIABLE DECLARATION",
            "//==============================================================================",
            "",
            "//==============================================================================",
            "// PUBLIC FUNCTION DECLARATION",
            "//==============================================================================",
            "",
            "//==============================================================================",
            "// EOF",
            "//==============================================================================",
            "#ifdef __cplusplus",
            "}",
            "#endif",
            "#endif // #ifndef ",
        }),
        f(get_guard),
    })

    local c0 = s("c0", {
        t("/// @file "),
        f(get_filename_no_ext),
        t(".c"),
        t({ "", "/// @author " }),
        i(1, "User"),
        t(" ("),
        i(2, "user@email.com"),
        t({
            ")",
            "/// @brief",
            "/// @copyright Copyright (C) 2026. All rights reserved.",
            "/// @details",
            "",
            "// INCLUDE",
            '#include "',
        }),
        f(get_filename_no_ext),
        t('.h"'),
        t({
            "",
            "",
            "// IMPORTED SWITCH CHECK",
            "",
            "// PRIVATE DEFINE",
            "",
            "// PRIVATE TYPEDEF",
            "",
            "// PRIVATE ENUM",
            "",
            "// PRIVATE STRUCT",
            "",
            "// PRIVATE UNION",
            "",
            "// PRIVATE FUNCTION DECLARATION",
            "",
            "// PRIVATE VARIABLE DEFINITION",
            "",
            "// PUBLIC VARIABLE DEFINITION",
            "",
            "// PUBLIC FUNCTION DEFINITION",
            "",
            "// PRIVATE FUNCTION DEFINITION",
            "",
            "// TEST",
        }),
    })

    local h0 = s("h0", {
        t("/// @file "),
        f(get_filename_no_ext),
        t(".h"),
        t({ "", "/// @author " }),
        i(1, "User"),
        t(" ("),
        i(2, "user@email.com"),
        t({
            ")",
            "/// @brief",
            "/// @copyright Copyright (C) 2026. All rights reserved.",
            "/// @details",
            "",
            "// GUARD START",
            "",
            "#ifndef ",
        }),
        f(get_guard),
        t({ "", "#define " }),
        f(get_guard),
        t({
            "",
            "#ifdef __cplusplus",
            'extern "C" {',
            "#endif",
            "",
            "// INCLUDE",
            "",
            "// PUBLIC TYPEDEF",
            "",
            "// PUBLIC DEFINE",
            "",
            "// PUBLIC ENUM",
            "",
            "// PUBLIC STRUCT",
            "",
            "// PUBLIC UNION",
            "",
            "// PUBLIC VARIABLE DECLARATION",
            "",
            "// PUBLIC FUNCTION DECLARATION",
            "",
            "// GUARD END",
            "",
            "#ifdef __cplusplus",
            "}",
            "#endif",
            "#endif // #ifndef ",
        }),
        f(get_guard),
    })

    ls.add_snippets("c", { doxy, c80, h80, c0, h0 })
    ls.add_snippets("cpp", { doxy, c80, h80, c0, h0 })

    M.keymap_setup()
end

function M.keymap_setup()
    local ls = require("luasnip")

    -- Trigger and Jump keymaps
    vim.keymap.set({ "i", "s" }, "<Tab>", function()
        if ls.expand_or_jumpable() then
            ls.expand_or_jump()
        else
            vim.api.nvim_feedkeys(
                vim.api.nvim_replace_termcodes("<Tab>", true, false, true),
                "n",
                false
            )
        end
    end, { silent = true, desc = "LuaSnip: Expand or jump forward" })

    vim.keymap.set({ "i", "s" }, "<S-Tab>", function()
        if ls.jumpable(-1) then
            ls.jump(-1)
        else
            vim.api.nvim_feedkeys(
                vim.api.nvim_replace_termcodes("<S-Tab>", true, false, true),
                "n",
                false
            )
        end
    end, { silent = true, desc = "LuaSnip: Jump backward" })

    vim.keymap.set({ "i", "s" }, "<C-l>", function()
        if ls.choice_active() then
            ls.change_choice(1)
        end
    end, { silent = true, desc = "LuaSnip: Next choice" })
end

return M
