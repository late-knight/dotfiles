--- @author jarrin-p
--- @file `util.lua`
local M = {
    map = function(lhs, rhs)
        vim.api.nvim_set_keymap('', lhs, rhs, { noremap = false, silent = true })
    end,

    nnoremap = function(lhs, rhs)
        vim.api.nvim_set_keymap('n', lhs, rhs, { noremap = true, silent = true })
    end,

    buf_nnoremap = function(lhs, rhs)
        vim.api.nvim_buf_set_keymap(0, 'n', lhs, rhs, { noremap = true, silent = true })
    end,

    --- assumes remap to normal mode.
    inoremap = function(lhs, rhs)
        vim.api.nvim_set_keymap('i', lhs, '<c-o>' .. rhs, { noremap = true, silent = true })
    end,

    tnoremap = function(lhs, rhs)
        vim.api.nvim_set_keymap('t', lhs, rhs, { noremap = true, silent = true })
    end,

    exec = function(str, bool)
        bool = bool or false
        vim.api.nvim_exec(str, bool)
    end,

    --- make_session_on_git_root(opts)
    --- @class make_git_session_opts
    --- @field file_path? string
    --- @field session_name? string

    --- makes sessions in the git root directory if in one.
    --- @param opts? make_git_session_opts
    make_session_on_git_root = function(opts)
        opts = opts or {}
        opts.session_name = opts.session_name or 'Session.vim'
        if vim.fn.FugitiveIsGitDir() == 1 then
            opts.file_path = opts.file_path or vim.fn.FugitiveWorkTree()
        end
        if not opts.file_path then
            return
        end -- don't litter sessions.
        vim.cmd(table.concat({ 'mksession!', opts.file_path .. '/' .. opts.session_name }, ' '))
    end,

    --- load_sessions_from_git_root(opts) 
    --- @class load_git_session_opts
    --- @field file_path? string
    --- @field session_name? string

    --- makes sessions in the git root directory if in one.
    --- @param opts? load_git_session_opts
    load_session_from_git_root = function(opts)
        opts = opts or {}
        opts.session_name = opts.session_name or 'Session.vim'
        if vim.fn.FugitiveIsGitDir() == 1 then
            opts.file_path = opts.file_path or vim.fn.FugitiveWorkTree()
        else
            opts.file_path = opts.file_path .. ' ' or ''
        end
        vim.cmd(table.concat({ 'source', opts.file_path .. '/' .. opts.session_name }, ' '))
    end,

    --- cleans trailing whitespace in a file. win view is saved to keep cursor from jumping around from the substitute command.
    clean_buffer_postspace = function()
        -- TODO make this not keep jumps for undo with subs.
        -- local view = vim.fn.winsaveview()
        -- vim.cmd('keepjumps silent %smagic/ *$//')
        -- vim.fn.winrestview(view)
    end,

    --- get_listed_bufnames 
    --- get list of buffers delimited using newlines by default.
    --- @param delimiter? string (default '\\n') delimiter to use for returned table.
    --- @return table bufnames the buffers as a table.
    get_listed_bufnames = function(delimiter)
        delimiter = delimiter or '\n'

        local bufnames = {}
        for _, buffer in ipairs(vim.fn.getbufinfo()) do
            if buffer.listed == 1 then
                table.insert(bufnames, buffer.name)
            end
        end

        return bufnames
    end,
}

--- PrepentToEachTableEntry(t, text_to_prepend) 
--- prepends to the front of each string in a table. does not update in place.
--- @param t table table of strings that will have each text have prepended.
--- @param text_to_prepend string what will be prepended.
--- @return table new table with text prepended.
function PrependToEachTableEntry(t, text_to_prepend)
    local returned_table = {}
    for _, value in ipairs(t) do
        if type(value) ~= 'string' then
            print('table contains non-string value. returning from function')
            return
        end
        table.insert(returned_table, text_to_prepend .. value)
    end
    return returned_table
end

--- StringToTable(str, delim) 
--- split string into table. a quick implementation of the inverse of `table.concat`.
--- @param str string string to be broken apart.
--- @param delim string delimiter that determines where to break apart string.
--- @return table result_as_table the table of strings that were split.
function StringToTable(str, delim)
    str = str .. delim -- append to make splitting easier.
    local result_as_table = {}
    for match in string.gmatch(str, '([^' .. delim .. ']+)' .. delim) do
        table.insert(result_as_table, match)
    end

    return result_as_table
end

--- GetLSPKind(kind) 
--- kind of like an enum for converting the kind response from the LSP
--- into a physical name. sets it if it hasn't been made yet.
--- @param kind number kind to convert.
function GetLSPKind(kind)
    if not LSPKindEnum then
        LSPKindEnum = {
            [1] = 'File',
            [2] = 'Module',
            [3] = 'Namespace',
            [4] = 'Package',
            [5] = 'Class',
            [6] = 'Method',
            [7] = 'Property',
            [8] = 'Field',
            [9] = 'Constructor',
            [10] = 'Enum',
            [11] = 'Interface',
            [12] = 'Function',
            [13] = 'Variable',
            [14] = 'Constant',
            [15] = 'String',
            [16] = 'Number',
            [17] = 'Boolean',
            [18] = 'Array',
            [19] = 'Object',
            [20] = 'Key',
            [21] = 'Null',
            [22] = 'EnumMember',
            [23] = 'Struct',
            [24] = 'Event',
            [25] = 'Operator',
            [26] = 'TypeParameter',
        }
    end
    return LSPKindEnum[kind]
end

--- MakeFormatPrg() 
--- creates the string for a `formatprg` expression with escaped backslack `\` characters.
--- @param ext_command table
--- @return string|nil command the exact command string that should be evaluated, or nil if a table was not passed.
function MakeFormatPrgText(ext_command)
    if type(ext_command) ~= 'table' then
        return nil
    end
    local prefix = 'silent setlocal formatprg='
    local command = prefix .. table.concat(ext_command, '\\ ')
    return command
end

--- FF() (format file using formatprg) 
function FF()
    if vim.api.nvim_get_option_value('formatprg', {}) ~= '' then
        local view = vim.fn.winsaveview()
        vim.cmd('keepjumps silent norm gggqG')
        vim.fn.winrestview(view)
    end
end

--- exports the cwd to a temp file gotten from the env variable $VIM_CWD_PATH
function ExportCwd()
    -- cd %:p:h<enter>
    local cwd = vim.fn.getcwd()
    os.execute('echo "' .. cwd .. '" > ' .. os.getenv('VIM_CWD_PATH'))
end

--- uses fugitive to check if in a git directory, and if it is, return the head.
--- @return string #the name of the branch, or an empty string.
function GetBranch()
    if vim.fn.FugitiveIsGitDir() == 1 then
        return ('⤤ ' .. vim.fn.FugitiveHead())
    end
    return ''
end

--- @return string #the aws role from $AWS_ROLE.
function GetAwsRole()
    if os.getenv('AWS_ROLE') then
        return ' | ' .. os.getenv('AWS_ROLE')
    end
    return ''
end

--- I'm awful and just copy pasted symbols I wanted.
Symbols = {
    -- bl = '«', -- bracket left
    -- br = '»', -- bracket right
    ra = '->', -- right ..arrow
    left_tr = '',
    right_tr = '',
    bl = '',
    br = '',
    -- local enter_sym = '⏎'
    -- local te = '⋯'
}

return M

-- vim: fdm=marker foldlevel=0
