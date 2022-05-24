require 'Global'

-- TODO api native commands using `vim.api.nvim_add_user_command(...)`
Vim.g.sil_is_toggled = 0
Exec([[
function ToggleSil()
    if g:sil_is_toggled == 0
        noremap : :silent 
        let g:sil_is_toggled = 1
    else
        noremap : :
        let g:sil_is_toggled = 0
    endif
endfunction
]], false)

Exec([[ command -nargs=1 NTI let NERDTreeIgnore=<args> ]], false) -- takes an array
Exec([[ command SA !cd $(git rev-parse --show-toplevel); gradle spotlessApply ]], false)
Exec([[ command TFF !cd $(git rev-parse --show-toplevel); terraform fmt -recursive ]], false)
Exec([[ command GT execute 'cd' fnameescape(FugitiveWorkTree())]], false)
