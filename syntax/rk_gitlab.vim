if exists("b:current_syntax")
  finish
endif

" Matches Headers like === GitLab Projects ===
syntax match RkGitlabHeader /^===.*===$/

" Matches Project IDs like [123]
syntax match RkGitlabProjectId /^\[\d\+\]/

" Matches Issue IDs like #123
syntax match RkGitlabIssueId /^#\d\+/

" Matches tags like [opened@张三] and extracts state/assignee for specific coloring
syntax match RkGitlabTag /\[[^\]]\+@[^\]]\+\]/ contains=RkGitlabStateOpened,RkGitlabStateClosed,RkGitlabStateOther,RkGitlabAssignee,RkGitlabAt
syntax match RkGitlabStateOpened /\[\zsopened\ze@/ contained
syntax match RkGitlabStateClosed /\[\zsclosed\ze@/ contained
syntax match RkGitlabStateOther /\[\zs[^@\]]\+\ze@/ contained
syntax match RkGitlabAssignee /@\zs[^\]]\+\ze\]/ contained
syntax match RkGitlabAt /@/ contained

" Matches Filter texts
syntax match RkGitlabFilter /^Filter:.*/
syntax match RkGitlabQuickFilter /^Quick Filter:.*/

" Matches Help Menu keybindings
syntax match RkGitlabHelpKey /^\s\+\zs\S\+\ze\s*:/
syntax match RkGitlabHelpDesc /:\s*\zs.*$/

" ---------------------------------------------------------------------
" Link to standard Highlight Groups (Perfectly matching TokyoNight)
" ---------------------------------------------------------------------
" Keyword: usually purple/magenta in tokyonight
highlight default link RkGitlabHeader Keyword

" Number: usually orange
highlight default link RkGitlabProjectId Number
highlight default link RkGitlabIssueId Number

" String/Error: specifically coloring opened/closed states
highlight default link RkGitlabStateOpened ErrorMsg
highlight default link RkGitlabStateClosed String
highlight default link RkGitlabStateOther String

" Identifier: usually blue/cyan (for assignee names)
highlight default link RkGitlabAssignee Identifier

" Operator/Delimiter: cyan or subtle fg
highlight default link RkGitlabAt Operator
highlight default link RkGitlabTag Delimiter

" Comment: greyed out for subtle UI hints
highlight default link RkGitlabFilter Comment
highlight default link RkGitlabQuickFilter Comment
highlight default link RkGitlabHelpDesc Comment

" Type: usually cyan (for help menu keys)
highlight default link RkGitlabHelpKey Type

let b:current_syntax = "rk_gitlab"
