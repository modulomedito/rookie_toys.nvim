local M = {}

function M.setup()
    -- Setup default config flags
    require("rookie_toys.rk_default")

    -- Setup options
    require("rookie_toys.rk_option").setup()

    -- Setup keymaps
    require("rookie_toys.rk_keymap").setup()

    -- Setup dependencies
    require("rookie_toys.rk_dependencies").setup()

    -- Features setups
    require("rookie_toys.rk_lsp").setup()
    require("rookie_toys.rk_clangd").setup()
    require("rookie_toys.rk_project").setup()
    require("rookie_toys.rk_smooth").setup()
    require("rookie_toys.rk_crc").setup()
    require("rookie_toys.rk_hex").setup()
    require("rookie_toys.rk_retab").setup()
    require("rookie_toys.rk_gitdiff").setup()
    require("rookie_toys.rk_tabrename").setup()
    require("rookie_toys.rk_c").setup()
    require("rookie_toys.rk_abbr").setup()
    require("rookie_toys.rk_autocmd").setup()
    require("rookie_toys.rk_7zip").setup()
    require("rookie_toys.rk_far").setup()
    require("rookie_toys.rk_textmanip").setup()
    require("rookie_toys.rk_cmac").setup()
    require("rookie_toys.rk_aes").setup()
    require("rookie_toys.rk_tag").setup()
    require("rookie_toys.rk_gitlab").setup()
end

return M
