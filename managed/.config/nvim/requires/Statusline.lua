require 'Global'

-- status line modifications
local bl = '«'
local te = '->'
-- local br = '»'
-- local enter_sym = '⏎'
-- local te = '⋯'

--- nvim highlight group wrapper that allows easier inline status text formatting.
-- additionally, has defaults specified to keep the status line uniform
SLColorgroup = {
    name = 'Not set',
    scope = 0,
    options = {
        underline = 1, -- underline needs to be enabled for custom underline color.
        sp = Colors.h_split_underline -- default for the underline color.
    },

    --- create new statusline colorgroup object. attempting to manage statusline color groups
    -- so its behavior can be more easily updated.
    new = function(self, arg_table)
        self.__index = self
        local obj = {}
        setmetatable(obj, self)

        for key, val in pairs(arg_table) do
            if key == 'options' then
                -- if it's the options table, loop through to add to the table instead of
                -- overwriting from the new table. this preserves default settings.
                for opts_key, opts_val in pairs(val) do
                    obj.options[opts_key] = opts_val
                end

            else
                obj[key] = val
            end
        end
        vim.api.nvim_set_hl(obj.scope, obj.name, obj.options)
        return obj
    end,

    --- returns the string to use the color group in the status line.
    -- @param text_to_color [optional] for code readability, to "pseudo" wrap the group of characters to be colored.
    set = function(self, text_to_color)
        text_to_color = text_to_color or ''
        return '%#' .. self.name .. '#' .. text_to_color
    end,
}

-- create custom color groups for the status line. assigning them to variables
-- allows the color groups to have a `set` helper function that uses defaults.
local bracket = SLColorgroup:new{ name = 'SLBracket', options = { bold = 0, ctermfg = 8 } }
local sl_item = SLColorgroup:new{ name = 'SLItem', options = { ctermfg = 121 } }
local directory = SLColorgroup:new{ name = 'SLDir', options = { italic = 1, ctermfg = 3 } }
local header = SLColorgroup:new{ name = 'SLFileHeader', options = { bold = 1, italic = 0, ctermfg = 11 } }
local mod = SLColorgroup:new{ name = 'SLModified', options = { italic = 0, ctermfg = 9 } }

--- gets the absolute path of the currently worked on file using `expand`
-- and splits it into a table.
-- @returns abs_file_table an ordered table containing each directory for the path.
function GetAbsolutePathAsTable()
    local abs_file_path = {}
    for match in vim.fn.expand('%:p'):sub(1):gmatch('/[^/]*') do
        table.insert(abs_file_path, (match:gsub('/', '')))
    end
    return abs_file_path
end

--- standard linear search function
-- @param table_to_search the table to be searched.
-- @param item_to_find object to be found in the table
-- @returns int index of item. returns -1 if nothing is found
function LinearSearch(table_to_search, item_to_find)
    for i, item in ipairs(table_to_search) do
        if item == item_to_find then return i end
    end
    return -1
end

--- build the path itself.
function MakePath()
    local file_type = vim.api.nvim_get_option_value('filetype', {})
    if file_type == 'help' then
        return header:set'Help'

    elseif file_type == 'qf' then
        return header:set'Quick Fix || Location List'

    elseif file_type == 'fugitive' then
        return header:set'Fugitive ' .. bracket:set(bl) .. directory:set' Git'

    elseif file_type == 'gitcommit' then
        return header:set'Commit ' .. bracket:set(bl) .. directory:set' Fugitive ' .. bracket:set(bl) .. directory:set' Git'

    elseif file_type == 'git' then
        return header:set'Branch ' .. bracket:set(bl) .. directory:set' Fugitive ' .. bracket:set(bl) .. directory:set' Git'

    elseif file_type == 'nerdtree' then
        return (sl_item:set'↟' .. header:set'NERDTree')

    elseif vim.fn.FugitiveIsGitDir() == 1 then
        local abs_file_path = GetAbsolutePathAsTable()

        local _, last_index = vim.fn.FugitiveWorkTree():find('.*/')
        local index_of_dir = LinearSearch(abs_file_path, (vim.fn.FugitiveWorkTree():sub(last_index):gsub('/', '')) )

        local status = ConvertTableToPathString(abs_file_path, 5, index_of_dir)
        return status
    else
        local status = ConvertTableToPathString(GetAbsolutePathAsTable(), 5)
        return status
    end
end

--- takes the path and converts it to a string that will be set on the statusline.
-- @param path_table table to be converted to status.
-- @param project_root_index directory of the project root
-- @param truncate_point (optional) max number of entries on the status line.
function ConvertTableToPathString(path_table, truncate_point, project_root_index)
    if not path_table then return 'no path to convert' end
    truncate_point = truncate_point or #path_table
    project_root_index = project_root_index or 1

    local status, reverse_path = '', {}
    for i = #path_table, project_root_index, -1 do table.insert(reverse_path, path_table[i]) end

    -- while there's more than one entry left to add to the path that will be displayed
    while (#reverse_path > 1) do
        -- pop the next item to be displayed in the path from the stack and add a bracket
        local pop = directory:set(table.remove(reverse_path))
        if #reverse_path < truncate_point then
            status = pop .. status
            status =  ' ' .. bracket:set(bl) .. ' ' .. status

        -- set the point where truncation occurs on the list
        elseif #path_table == truncate_point then
            status = ' ' .. bracket:set(bl) .. directory:set' <% '
        end
    end

    --- the `open` file itself is the last item in the table to be popped.
    -- additionally, adds a modified symbol if ... the file has been modified ...
    status = header:set(table.remove(path_table)) .. mod:set(AddSymbolIfSet('modified', '+')) .. status
    return status
end

--- uses fugitive to check if in a git directory, and if it is, return the head.
function GetBranch()
    if vim.fn.FugitiveIsGitDir() == 1 then
        return sl_item:set("⤤ " .. vim.fn.FugitiveHead()) .. bracket:set(" " .. te) .. ' '
    else
        return ''
    end
end

--- checks if a boolean option is true, then adds a user defined symbol if it is.
function AddSymbolIfSet(option, symbol_to_use)
    if (vim.api.nvim_get_option_value(option, {}) == true) then
        return symbol_to_use
    else
        return ''
    end
end

--- finally, customize the statusline using the components we made.
function MakeStatusLine()
    -- left hand side padding, also declaration for easier adjusting.
    local sl = header:set'  '

    -- left hand side.
    sl = sl .. MakePath()

    -- where to truncate and where the statusline splits.
    sl = sl .. "%="

    -- right hand side
    sl = sl .. '        ' -- added 8 spaces of padding for when the status line is long.
    sl = sl .. '        ' -- added 8 spaces of padding for when the status line is long.
    sl = sl .. GetBranch()
    sl = sl .. sl_item:set"buf %n" -- buffer id.
    sl = sl .. header:set'  ' -- rhs padding.

    -- updates the window being worked in only.
    SetWinLocal.statusline = sl
end

-- add autocommands for the statusline to update.
vim.api.nvim_create_autocmd({'VimEnter', 'WinEnter', 'BufWinEnter', 'WinNew', 'BufModifiedSet'}, { callback = MakeStatusLine })
vim.api.nvim_create_autocmd({'FileType'}, { pattern = {'nerdtree'}, callback = MakeStatusLine })
