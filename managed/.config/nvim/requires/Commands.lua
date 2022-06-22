--- @author jarrin-p {{{
--- @description commands are set here. }}}

require 'Global'

-- adds a filter list to NERDTree.
-- TODO view the filter api instead.
Exec([[ command -nargs=1 NTI let NERDTreeIgnore=<args> ]], false) -- takes an array

-- runs `spotlessApply` at the top level of the git repository.
-- TODO install `spotlessApply` as a standalone.
Exec([[ command SA !cd $(git rev-parse --show-toplevel); gradle spotlessApply ]], false)

-- runs `terraform fmt` on the current file.
Exec([[ command TFF !terraform fmt % ]], false)

-- changes current directory to the root of the git repository.
Exec([[ command GT execute 'cd' fnameescape(FugitiveWorkTree())]], false)

-- vim: fdm=marker foldlevel=0
