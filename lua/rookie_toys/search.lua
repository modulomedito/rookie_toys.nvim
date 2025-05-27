local function check_rg()
    if vim.fn.executable("rg") == 0 then
        print("Cannot found rg")
        return 0
    end

    if vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
        vim.opt.shell = "cmd.exe"
        vim.opt.shellcmdflag = "/c"
        vim.opt.shellpipe = ">%s 2>&1"
        vim.opt.shellredir = ">%s 2>&1"
    end

    vim.opt.grepprg = "rg --vimgrep --no-heading --smart-case --hidden"
    vim.opt.grepformat = "%f:%l:%c:%m"
    return 1
end


local function live_grep()
    if check_rg() == 0 then return end

    local user_input = vim.fn.input("Enter your searching pattern: ")
    print("Searching: " .. user_input)
    vim.cmd("silent! grep " .. user_input .. " .")
    vim.cmd("copen")
    vim.cmd("redraw!")
end

local function grep_word_under_cursor()
    if check_rg() == 0 then return end

    vim.cmd("silent! grep <C-R><C-W> .")
    vim.cmd("copen")
    vim.cmd("redraw")
end


return {
    live_grep = live_grep,
    grep_word_under_cursor = grep_word_under_cursor,
}
