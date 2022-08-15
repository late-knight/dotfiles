-- settings {{{
nnoremap('<leader>t', ':NERDTreeFind<enter>:set rnu<enter>') -- at current working directory
nnoremap('<leader>T', ':NERDTreeToggleVCS<enter>:set rnu<enter>') -- at vcs toplevel
vim.g.NERDTreeWinSize = 50
vim.g.NERDTreeShowBookmarks = 1 -- }}}

-- open nerdtree as soon as vim opens. make it full screen if no other buffer is open {{{
function NERDTreeStartupBehavior()
    vim.api.nvim_command('NERDTreeToggleVCS') -- open nerdtree
    vim.api.nvim_command('wincmd p')
    if CurrentBufIsEmpty() then
        vim.api.nvim_command('q')
    end
end
vim.api.nvim_create_autocmd(
    { 'VimEnter' }, { callback = NERDTreeStartupBehavior }
) -- }}}

-- adds a filter list to NERDTree. {{{
-- TODO view the filter api instead.
Exec([[ command! -nargs=1 NTI let NERDTreeIgnore=<args> ]], false) -- takes an array }}}

--- opens new kitty tab at specified path or `current` directory. {{{
--- @param path string path to the location of the new tab.
function NewKittyTab(path)
    vim.fn.system(
        'kitty @ launch --cwd=' .. (path or 'current') .. ' --type=tab'
    )
end -- }}}

--- opens kitty tab at directory of current node. {{{
--- setting it globally to vim allows it to be used as a callback.
--- (it's registered as a global vim function this way)
vim.g.NERDTreeOpenKittyTabHere = function()
    local node_path_table = vim.api
                                .nvim_eval('g:NERDTreeFileNode.GetSelected()')
                                .path
    local file_name

    -- pop last entry in path segments if it's not a directory. stores file_name.
    if node_path_table.isDirectory == 0 then
        file_name = table.remove(node_path_table.pathSegments)
    end

    local path_str = table.concat(node_path_table.pathSegments, '/')
    NewKittyTab('/' .. path_str) -- need to enforce absolute path.
end -- }}}

--- create the menu items after everything has been loaded using an autocmd.{{{
vim.api.nvim_create_autocmd(
    { 'VimEnter' }, {
        callback = function()
            vim.fn.NERDTreeAddMenuItem {
                text = 'New kitty (t)erminal tab from this directory.',
                shortcut = 't',
                callback = 'g:NERDTreeOpenKittyTabHere',
            }
        end,
    }
) -- }}}
