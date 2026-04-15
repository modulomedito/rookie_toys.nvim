local M = {}

function M.setup()
    local group_gitcommit =
        vim.api.nvim_create_augroup("RkGitCommit", { clear = true })

    -- Disable undo for git commit messages BEFORE reading the buffer
    -- to prevent "E824: Incompatible undo file"
    vim.api.nvim_create_autocmd({ "BufReadPre", "BufNewFile" }, {
        group = group_gitcommit,
        pattern = {
            "COMMIT_EDITMSG",
            "MERGE_MSG",
            "TAG_EDITMSG",
            "NOTES_EDITMSG",
        },
        callback = function(args)
            -- Use silent! to suppress the E824 error if it triggers during the setlocal
            vim.cmd("silent! setlocal noundofile")
            -- Proactively delete the undo file if it exists to clear the conflict
            local undofile = vim.fn.undofile(args.file)
            if vim.fn.filereadable(undofile) == 1 then
                vim.fn.delete(undofile)
            end
        end,
    })

    vim.api.nvim_create_autocmd("FileType", {
        group = group_gitcommit,
        pattern = "gitcommit",
        callback = function()
            -- setlocal textwidth=100
            vim.opt_local.textwidth = 100
            vim.cmd("silent! setlocal noundofile")

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

    local group_gitgraph =
        vim.api.nvim_create_augroup("RkGitGraph", { clear = true })
    vim.api.nvim_create_autocmd("FileType", {
        group = group_gitgraph,
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

    -- C/C++ Indentation
    local group_c = vim.api.nvim_create_augroup("RkC", { clear = true })
    vim.api.nvim_create_autocmd("FileType", {
        group = group_c,
        pattern = { "c", "cpp" },
        callback = function()
            vim.opt_local.tabstop = 4
            vim.opt_local.shiftwidth = 4
            vim.opt_local.expandtab = true
            vim.opt_local.cindent = true -- Explicitly use standard C indentation
            vim.opt_local.indentexpr = "" -- Disable Treesitter's indent engine for C
        end,
    })

    local group_markdown =
        vim.api.nvim_create_augroup("RkMarkdown", { clear = true })
    vim.api.nvim_create_autocmd("FileType", {
        group = group_markdown,
        pattern = "markdown",
        callback = function()
            vim.opt_local.textwidth = 80
        end,
    })
end

return M
