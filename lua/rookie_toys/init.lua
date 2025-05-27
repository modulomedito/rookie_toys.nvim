-- Global variables definition
Rookie_clangd_config = {}
Rookie_clangd_param = {}

local function setup()
    require("rookie_toys.setup").setup()
end

return {
    setup = setup,
    -- api = require("rookie_clangd.api"),
}
