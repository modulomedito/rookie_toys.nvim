-- Global variables definition
Rookie_clangd_config = {}
Rookie_clangd_param = {}

return {
    setup = require("rookie_clangd.config").setup,
    api = require("rookie_clangd.api"),
}
