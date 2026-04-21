local M = {}

function M.setup()
    local has_codecompanion, codecompanion = pcall(require, "codecompanion")
    if not has_codecompanion then
        return
    end

    if vim.g.rookie_toys_ai_model == nil then
        vim.g.rookie_toys_ai_model = "gemma2:9b"
    end

    codecompanion.setup({
        strategies = {
            chat = {
                adapter = "ollama"
            },
            inline = {
                adapter = "ollama"
            },
            agent = {
                adapter = "ollama"
            }
        },
        adapters = {
            ollama = function()
                return require("codecompanion.adapters").extend("ollama", {
                    schema = {
                        model = {
                            default = function()
                                return vim.g.rookie_toys_ai_model
                            end
                        },
                        num_ctx = {
                            default = 16384
                        }
                    }
                })
            end
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
                    stop_context_insertion = true
                },
                prompts = {{
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
]]
                }, {
                    role = "user",
                    content = function()
                        local diff = vim.fn.system("git diff --cached")
                        if diff == "" then
                            return "No staged changes found. Please stage some changes before running this command."
                        end
                        return "Here is the diff of the changes:\n\n```diff\n" .. diff .. "\n```"
                    end,
                    opts = {
                        contains_code = true
                    }
                }}
            }
        }
    })

    -- Keymaps
    vim.keymap.set({"n", "v"}, "<leader>ca", "<cmd>CodeCompanionActions<cr>", {
        noremap = true,
        silent = true
    })
    vim.keymap.set("n", "<leader>cc", "<cmd>CodeCompanionChat Toggle<cr>", {
        noremap = true,
        silent = true
    })
    vim.keymap.set("v", "<leader>cc", "<cmd>CodeCompanionChat Add<cr>", {
        noremap = true,
        silent = true
    })
end

return M
