local M = {}

function M.toggle_highlight_diagnostics()
    local bufnr = vim.api.nvim_get_current_buf()

    -- Toggle diagnostics
    local diagnostics_enabled = vim.diagnostic.is_enabled({ bufnr = bufnr })
    vim.diagnostic.enable(not diagnostics_enabled, { bufnr = bufnr })

    -- Toggle semantic tokens
    local semantic_enabled = false
    if vim.lsp.semantic_tokens and vim.lsp.semantic_tokens.is_enabled then
        semantic_enabled = vim.lsp.semantic_tokens.is_enabled({ bufnr = bufnr })
        vim.lsp.semantic_tokens.enable(not semantic_enabled, { bufnr = bufnr })
    else
        -- Fallback for older Neovim versions
        semantic_enabled = vim.b[bufnr].semantic_tokens_enabled == true
        local get_clients = vim.lsp.get_clients or vim.lsp.get_active_clients
        local clients = get_clients({ bufnr = bufnr })
        if semantic_enabled then
            for _, client in ipairs(clients) do
                if client.server_capabilities.semanticTokensProvider then
                    vim.lsp.semantic_tokens.stop(bufnr, client.id)
                end
            end
            vim.b[bufnr].semantic_tokens_enabled = false
        else
            for _, client in ipairs(clients) do
                if client.server_capabilities.semanticTokensProvider then
                    vim.lsp.semantic_tokens.start(bufnr, client.id)
                end
            end
            vim.b[bufnr].semantic_tokens_enabled = true
        end
    end

    local status = not diagnostics_enabled and "ON" or "OFF"
    print("LSP Highlights & Diagnostics: " .. status)
end

function M.stop_lsp(lsp_name)
    local clients = vim.lsp.get_clients({ name = lsp_name })
    for _, client in ipairs(clients) do
        client:stop()
    end
    print("Stopped " .. lsp_name)
end

function M.setup()
    -- Global variable to control enabling LSP keymaps
    if vim.g.rookie_toys_lsp_enable == false then
        return
    end

    -- LSP Server list pattern similar to kickstart.nvim
    local servers = {
        clangd = {
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
        },
        pyright = {},
        rust_analyzer = {},
        lua_ls = {},
        jsonls = {},
        marksman = {},
        -- Add more servers here
    }

    -- Setup servers
    if vim.lsp.config then
        -- Neovim 0.11+ style
        for server_name, config in pairs(servers) do
            vim.lsp.config(server_name, config)
            vim.lsp.enable(server_name)
        end
    else
        -- Fallback for older Neovim versions using nvim-lspconfig
        local ok, lspconfig = pcall(require, "lspconfig")
        if ok then
            for server_name, config in pairs(servers) do
                lspconfig[server_name].setup(config)
            end
        end
    end

    -- Diagnostic config
    vim.diagnostic.config({
        update_in_insert = false,
        severity_sort = true,
        float = { border = "rounded", source = "if_many" },
        underline = { severity = { min = vim.diagnostic.severity.WARN } },
        virtual_text = true,
        virtual_lines = false,
        jump = {
            on_jump = function(_, bufnr)
                vim.diagnostic.open_float({
                    bufnr = bufnr,
                    scope = "cursor",
                    focus = false,
                })
            end,
        },
    })

    -- Global mappings
    vim.keymap.set(
        "n",
        "<leader>e",
        vim.diagnostic.open_float,
        { desc = "LSP: Show diagnostic error" }
    )
    vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "LSP: Goto previous diagnostic" })
    vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "LSP: Goto next diagnostic" })
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
            -- Disable diagnostics by default for this buffer
            vim.diagnostic.enable(false, { bufnr = ev.buf })

            -- Disable semantic tokens by default for this buffer
            vim.schedule(function()
                if not vim.api.nvim_buf_is_valid(ev.buf) then
                    return
                end
                if vim.lsp.semantic_tokens and vim.lsp.semantic_tokens.enable then
                    vim.lsp.semantic_tokens.enable(false, { bufnr = ev.buf })
                else
                    local client = vim.lsp.get_client_by_id(ev.data.client_id)
                    if client and client.server_capabilities.semanticTokensProvider then
                        vim.lsp.semantic_tokens.stop(ev.buf, client.id)
                    end
                end
                vim.b[ev.buf].semantic_tokens_enabled = false
            end)

            -- Buffer local mappings.
            -- See `:help vim.lsp.*` for documentation on any of the below functions
            local opts = { buffer = ev.buf }
            vim.keymap.set(
                "n",
                "gD",
                vim.lsp.buf.declaration,
                { desc = "LSP: Goto [D]eclaration", buffer = ev.buf }
            )
            vim.keymap.set(
                "n",
                "gd",
                vim.lsp.buf.definition,
                { desc = "LSP: Goto [d]efinition", buffer = ev.buf }
            )
            vim.keymap.set(
                "n",
                "gh",
                vim.lsp.buf.hover,
                { desc = "LSP: [H]over documentation", buffer = ev.buf }
            )
            vim.keymap.set(
                "n",
                "gi",
                vim.lsp.buf.implementation,
                { desc = "LSP: Goto [i]mplementation", buffer = ev.buf }
            )
            vim.keymap.set(
                "n",
                "gS",
                vim.lsp.buf.signature_help,
                { desc = "LSP: [S]ignature help", buffer = ev.buf }
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
                local ok, conform = pcall(require, "conform")
                if ok then
                    conform.format({ lsp_fallback = true, async = true })
                else
                    vim.lsp.buf.format({ async = true })
                end
            end, {
                desc = "Format buffer (conform)",
                buffer = ev.buf,
            })

            local client = vim.lsp.get_client_by_id(ev.data.client_id)
            if client and client:supports_method("textDocument/documentHighlight", ev.buf) then
                local highlight_augroup = vim.api.nvim_create_augroup("kickstart-lsp-highlight", { clear = false })
                vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
                    buffer = ev.buf,
                    group = highlight_augroup,
                    callback = vim.lsp.buf.document_highlight,
                })
                vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
                    buffer = ev.buf,
                    group = highlight_augroup,
                    callback = vim.lsp.buf.clear_references,
                })
                vim.api.nvim_create_autocmd("LspDetach", {
                    group = vim.api.nvim_create_augroup("kickstart-lsp-detach", { clear = true }),
                    callback = function(event2)
                        vim.lsp.buf.clear_references()
                        vim.api.nvim_clear_autocmds({ group = "kickstart-lsp-highlight", buffer = event2.buf })
                    end,
                })
            end

            if client and client:supports_method("textDocument/inlayHint", ev.buf) then
                vim.keymap.set("n", "<leader>th", function()
                    vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = ev.buf }))
                end, { desc = "[T]oggle Inlay [H]ints", buffer = ev.buf })
            end
        end,
    })

    -- Toggle semantic highlight and diagnostics
    vim.keymap.set("n", "<leader>hld", M.toggle_highlight_diagnostics, {
        desc = "Toggle [h]igh[l]ighting semantic & [d]iagnostics",
        silent = true,
    })

    -- Stop specific lsp
    vim.api.nvim_create_user_command("RkLspStop", function(opts)
        M.stop_lsp(opts.args)
    end, {
        nargs = 1,
        complete = function()
            local clients = vim.lsp.get_clients()
            local names = {}
            for _, client in ipairs(clients) do
                table.insert(names, client.name)
            end
            return names
        end,
        desc = "Stop a specific LSP client",
    })
end

return M
