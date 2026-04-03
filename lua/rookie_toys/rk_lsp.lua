local M = {}

function M.setup()
    -- Global variable to control enabling LSP keymaps
    if vim.g.rookie_toys_lsp_enable == false then
        return
    end

    -- Setup clangd
    if vim.lsp.config then
        -- Neovim 0.11+ style
        vim.lsp.config("clangd", {
            cmd = {
                "clangd",
                "--background-index",
                "--clang-tidy",
                "--header-insertion=iwyu",
                "--completion-style=detailed",
                "--function-arg-placeholders",
                "--fallback-style=llvm",
            },
            init_options = {
                usePlaceholders = true,
                completeUnimported = true,
                clangdFileStatus = true,
            },
        })
    else
        -- Fallback for older Neovim versions using nvim-lspconfig
        local ok, lspconfig = pcall(require, "lspconfig")
        if ok then
            lspconfig.clangd.setup({
                cmd = {
                    "clangd",
                    "--background-index",
                    "--clang-tidy",
                    "--header-insertion=iwyu",
                    "--completion-style=detailed",
                    "--function-arg-placeholders",
                    "--fallback-style=llvm",
                },
                init_options = {
                    usePlaceholders = true,
                    completeUnimported = true,
                    clangdFileStatus = true,
                },
            })
        end
    end

    -- Global mappings
    vim.keymap.set(
        "n",
        "<leader>e",
        vim.diagnostic.open_float,
        { desc = "LSP: Show diagnostic error" }
    )
    vim.keymap.set(
        "n",
        "[d",
        vim.diagnostic.goto_prev,
        { desc = "LSP: Goto previous diagnostic" }
    )
    vim.keymap.set(
        "n",
        "]d",
        vim.diagnostic.goto_next,
        { desc = "LSP: Goto next diagnostic" }
    )
    vim.keymap.set(
        "n",
        "<leader>q",
        vim.diagnostic.setloclist,
        { desc = "LSP: Set diagnostic location list" }
    )

    -- Use LspAttach autocommand to only map the following keys
    -- after the language server attaches to the current buffer
    vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("UserLspConfig", {}),
        callback = function(ev)
            -- Buffer local mappings.
            -- See `:help vim.lsp.*` for documentation on any of the below functions
            local opts = { buffer = ev.buf }
            vim.keymap.set(
                "n",
                "gD",
                vim.lsp.buf.declaration,
                { desc = "LSP: [G]oto [D]eclaration", buffer = ev.buf }
            )
            vim.keymap.set(
                "n",
                "gd",
                vim.lsp.buf.definition,
                { desc = "LSP: [G]oto [D]efinition", buffer = ev.buf }
            )
            -- vim.keymap.set("n", "K", vim.lsp.buf.hover, { desc = "LSP: Hover documentation", buffer = ev.buf })
            vim.keymap.set(
                "n",
                "gi",
                vim.lsp.buf.implementation,
                { desc = "LSP: [G]oto [I]mplementation", buffer = ev.buf }
            )
            vim.keymap.set(
                "n",
                "<C-k>",
                vim.lsp.buf.signature_help,
                { desc = "LSP: Signature help", buffer = ev.buf }
            )
            vim.keymap.set(
                "n",
                "<leader>wa",
                vim.lsp.buf.add_workspace_folder,
                { desc = "LSP: Workspace [A]dd folder", buffer = ev.buf }
            )
            vim.keymap.set(
                "n",
                "<leader>wr",
                vim.lsp.buf.remove_workspace_folder,
                { desc = "LSP: Workspace [R]emove folder", buffer = ev.buf }
            )
            vim.keymap.set("n", "<leader>wl", function()
                print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
            end, {
                desc = "LSP: Workspace [L]ist folders",
                buffer = ev.buf,
            })
            vim.keymap.set(
                "n",
                "<leader>D",
                vim.lsp.buf.type_definition,
                { desc = "LSP: Type [D]efinition", buffer = ev.buf }
            )
            vim.keymap.set(
                "n",
                "<leader>rn",
                vim.lsp.buf.rename,
                { desc = "LSP: [R]e[n]ame symbol", buffer = ev.buf }
            )
            vim.keymap.set(
                { "n", "v" },
                "<leader>ca",
                vim.lsp.buf.code_action,
                { desc = "LSP: [C]ode [A]ction", buffer = ev.buf }
            )
            vim.keymap.set(
                "n",
                "gr",
                vim.lsp.buf.references,
                { desc = "LSP: [G]oto [R]eferences", buffer = ev.buf }
            )
            vim.keymap.set("n", "<leader>f", function()
                vim.lsp.buf.format({ async = true })
            end, { desc = "LSP: [F]ormat buffer", buffer = ev.buf })
        end,
    })
end

return M
