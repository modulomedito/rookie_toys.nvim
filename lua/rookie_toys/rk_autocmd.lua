local M = {}

function M.setup()
    local group = vim.api.nvim_create_augroup("RkGitCommit", { clear = true })

    vim.api.nvim_create_autocmd("FileType", {
        group = group,
        pattern = "gitcommit",
        callback = function()
            -- setlocal textwidth=100
            vim.opt_local.textwidth = 100

            -- nnoremap <silent><buffer> <leader>f :PanguAll<CR>
            vim.keymap.set("n", "<leader>f", ":PanguAll<CR>", {
                silent = true,
                buffer = true,
                desc = "GitCommit: PanguAll",
            })

            -- nnoremap <silent><buffer> <C-q> :q<Bar>call timer_start(1000, {-> execute('RkGitGraph')})<CR>
            vim.keymap.set("n", "<C-q>", function()
                vim.cmd("q")
                vim.defer_fn(function()
                    vim.cmd("RkGitGraph")
                end, 200)
            end, {
                silent = true,
                buffer = true,
                desc = "GitCommit: Close and show GitGraph",
            })
        end,
    })

    vim.api.nvim_create_autocmd("FileType", {
        group = group,
        pattern = "gitgraph",
        callback = function()
            -- setlocal iskeyword+=- iskeyword+=/
            vim.opt_local.iskeyword:append("-")
            vim.opt_local.iskeyword:append("/")

            -- nnoremap <silent><buffer> gl f)b
            vim.keymap.set("n", "gl", "f)b", {
                silent = true,
                buffer = true,
                desc = "Git: Jump to closing paren and back to beginning of word",
            })
        end,
    })
end

return M
