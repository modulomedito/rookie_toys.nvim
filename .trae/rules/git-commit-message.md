---
alwaysApply: true
scene: git_message
---

# Please generate a Git commit message as a senior engineer

Format (space-sensitive):

```git-commit-message
<emoji> <type>(<scope1>.<scope2>):[#]<subject>

<body>
```

Items wrapped in `<>` are to be generated.

An example:

```git-commit-message
✨ feat(trae.rules):[#]add new feature

- Add rules for git commit message
```

## Emoji and Type List

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

## Notes

1. When referencing this file, trigger the generation of the commit message immediately without any other responses, intermediate results, or context memory.
2. `[#]` is a mandatory placeholder used to link to an issue number. The format is `[#issue]`, where `issue` is the issue number. Leave it empty to be filled in manually by the user.
3. `<subject>` should be as detailed as possible, but not exceed 120 characters.
4. `<body>` must follow markdown syntax, preferably using a list format to detail the changes item by item.
5. After a line break, provide a detailed Body explaining "why it was changed" rather than "what was changed".