--- @author jarrin-p
--- @file `init.lua`
-- add folders to be required.
require 'os'
local rc_path, suffix = os.getenv('MYVIMRC'), ''
if rc_path ~= nil and rc_path:match('.lua') then
    suffix = '.lua'
else
    suffix = '.vim'
end

-- add path so require function will find additional files in `requires` subfolder
package.path = string.gsub(rc_path, 'init' .. suffix, '') .. 'requires/?.lua;' .. '?.lua;'
                   .. package.path

-- general settings
require 'util'

require 'plugins'
require 'p_fzf'
require 'p_treesitter'
require 'p_fugitive'
require 'p_nerdtree'
require 'p_metals'
require 'p_lspconfig'
require 'p_nvim_cmp'

require 'commands'
require 'autocmd'
require 'settings'
require 'remaps'
require 'colorscheme'
require 'snippets'

-- specific files
require 'statusline'
require 'lesschords'
