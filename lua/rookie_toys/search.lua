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

local function do_grep_word(word)
    vim.cmd("silent! grep " .. word .. " .")
    vim.cmd("copen")
    vim.cmd("redraw!")
end

local function live_grep()
    if check_rg() == 0 then return end

    local user_input = vim.fn.input("Enter your searching pattern: ")
    if user_input then
        do_grep_word(user_input)
    end
end

local function grep_word_under_cursor()
    if check_rg() == 0 then return end

    local word = vim.fn.expand("<cword>")
    do_grep_word(word)
end


return {
    live_grep = live_grep,
    grep_word_under_cursor = grep_word_under_cursor,
}
