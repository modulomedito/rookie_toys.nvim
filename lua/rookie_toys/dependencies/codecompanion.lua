local M = {}

local function get_ai_adapter()
    local adapter = vim.g.rookie_toys_ai_adapter
    if adapter == "gemini" then
        return "gemini"
    end
    return "ollama"
end

local function get_default_model(adapter)
    if adapter == "gemini" then
        return "gemini-3-flash-preview"
    end
    return "gemma2:9b"
end

local function get_config_value(var_name, env_name)
    return vim.g[var_name] or os.getenv(env_name)
end

function M.setup()
    local has_codecompanion, codecompanion = pcall(require, "codecompanion")
    if not has_codecompanion then
        return
    end

    if vim.g.rookie_toys_ai_adapter == nil then
        vim.g.rookie_toys_ai_adapter = "ollama"
    end

    if vim.g.rookie_toys_ai_model == nil then
        vim.g.rookie_toys_ai_model = get_default_model(get_ai_adapter())
    end

    codecompanion.setup({
        strategies = {
            chat = {
                adapter = get_ai_adapter(),
                slash_commands = {
                    ["fetch"] = {
                        callback = "codecompanion.sources.slash_commands.fetch",
                        description = "Fetch web content",
                        opts = {
                            adapter = get_ai_adapter(),
                        },
                    },
                },
                tools = {
                    ["files"] = {
                        description = "Update the codebase",
                    },
                    ["editor"] = {
                        description = "Update the editor",
                    },
                    ["web_search"] = {
                        description = "Search the internet",
                    },
                    ["cmd_runner"] = {
                        description = "Run terminal commands",
                    },
                },
                groups = {
                    ["expert"] = {
                        description = "An expert developer who can modify code and search the web",
                        system_prompt = "You are an expert developer with access to tools that allow you to modify the codebase and search the internet. Use these tools to help the user with their requests.",
                        tools = {
                            "files",
                            "editor",
                            "web_search",
                            "cmd_runner",
                        },
                    },
                },
            },
            inline = {
                adapter = get_ai_adapter(),
            },
            agent = {
                adapter = get_ai_adapter(),
                tools = {
                    ["files"] = {
                        description = "Update the codebase",
                    },
                    ["editor"] = {
                        description = "Update the editor",
                    },
                    ["web_search"] = {
                        description = "Search the internet",
                    },
                    ["cmd_runner"] = {
                        description = "Run terminal commands",
                    },
                },
            },
        },
        adapters = {
            http = {
                opts = {
                    -- Global timeout for all adapters (30s)
                    timeout = vim.g.rookie_toys_ai_timeout or 30000,
                    -- Global proxy support
                    proxy = vim.g.rookie_toys_ai_proxy,
                },
                ollama = function()
                    return require("codecompanion.adapters").extend("ollama", {
                        schema = {
                            model = {
                                default = function()
                                    return vim.g.rookie_toys_ai_model or get_default_model("ollama")
                                end,
                            },
                            num_ctx = {
                                default = 16384,
                            },
                        },
                    })
                end,
                gemini = function()
                    return require("codecompanion.adapters").extend("gemini", {
                        env = {
                            api_key = function()
                                return get_config_value("rookie_toys_ai_api_key", "GEMINI_API_KEY")
                            end,
                        },
                        schema = {
                            model = {
                                default = vim.g.rookie_toys_ai_model or get_default_model("gemini"),
                            },
                        },
                        opts = {
                            -- Use IPv4 to avoid common Windows connection hangs
                            extra_args = { "-4" },
                        },
                    })
                end,
                tavily = function()
                    return require("codecompanion.adapters").extend("tavily", {
                        env = {
                            api_key = function()
                                return get_config_value("rookie_toys_ai_websearch_api", "TAVILY_API_KEY")
                            end,
                        },
                    })
                end,
            },
        },
        prompt_library = {
            ["Generate commit messages"] = {
                strategy = "chat",
                description = "Generate a git commit message",
                opts = {
                    alias = "mycommit",
                    auto_submit = true,
                    placement = "new",
                    is_slash_cmd = true,
                    stop_context_insertion = true,
                },
                prompts = {
                    {
                        role = "system",
                        content = [[
请作为一名资深工程师生成 Git 提交信息

格式（空格敏感）：

```git-commit-message
<emoji> <type>(boot.<scope>):[#]<subject>

<body>
```

其中使用 `<>` 包裹的为生成项

## emoji 和 type 列表

`<emoji> <type>`:

- 🎉 init
- ✨ feat
- 🐞 fix
- 📃 docs
- 🌈 style
- 🦄 refactor
- 🎈 perf
- 🧪 test
- 🔧 build
- 🐎 ci
- 🐳 chore
- ↩ revert

## 注意

1. 当引用此文件时立刻出发生成提交信息，无需其余回答，不保留任何中间结果和上下文记忆
2. `[#]` 为保留项，用于关联 issue 号，格式为 `[#issue]`，其中 `issue` 为 issue 号，留空由用户手动填写
3. `<subject>` 应尽可能详细，但不要超过 120 字
4. `<body>` 中符合 markdown 语法，且优先使用列表格式分条详细描述变更内容
5. 换行后提供详细的 Body，解释 "为什么改" 而非 "改了什么"
6. 每次生成时，清除上下文记忆并重新扫描 stage 区的文件变更点
7. 语言：中文
]],
                    },
                    {
                        role = "user",
                        content = function()
                            local diff = vim.fn.system("git diff --cached")
                            if diff == "" then
                                return "No staged changes found. Please stage some changes before running this command."
                            end
                            return "Here is the diff of the changes:\n\n```diff\n"
                                .. diff
                                .. "\n```"
                        end,
                        opts = {
                            contains_code = true,
                        },
                    },
                },
            },
        },
    })

    -- Keymaps
    vim.keymap.set({ "n", "v" }, "<leader>ca", "<cmd>CodeCompanionActions<cr>", {
        noremap = true,
        silent = true,
    })
    vim.keymap.set("n", "<leader>ci", "<cmd>CodeCompanion<cr>", {
        noremap = true,
        silent = true,
    })
    vim.keymap.set("n", "<leader><leader>cc", "<cmd>CodeCompanionChat<cr>", {
        noremap = true,
        silent = true,
    })
    vim.keymap.set("n", "<leader>cc", "<cmd>CodeCompanionChat Toggle<cr>", {
        noremap = true,
        silent = true,
    })
    vim.keymap.set("v", "<leader>cc", "<cmd>CodeCompanionChat Add<cr>", {
        noremap = true,
        silent = true,
    })
end

return M
