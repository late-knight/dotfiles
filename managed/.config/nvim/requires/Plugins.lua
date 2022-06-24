--- @author jarrin-p
--- @file `Plugins.lua`

--- vim-plug initialization {{{
local Plug = vim.fn['plug#']
if vim.fn.has('unix') == 1 then vim.call('plug#begin', '~/.config/nvim/autoload/plugged')
elseif vim.fn.has('mac') == 1 then vim.call('plug#begin', '~/.config/nvim/autoload/plugged')
end

-- import plugins
-- Plug 'psliwka/vim-smoothie' -- messes up with folds.

Plug 'sainnhe/vim-color-forest-night'

Plug 'petertriho/nvim-scrollbar'
Plug 'tpope/vim-fugitive'
Exec "Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }"
Exec "Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}"
Plug 'williamboman/nvim-lsp-installer'

Plug 'hrsh7th/nvim-cmp' -- autocompletion plugin
Plug 'hrsh7th/cmp-nvim-lsp' -- lsp source for nvim-cmp
Plug 'saadparwaiz1/cmp_luasnip' -- snippets source for nvim-cmp
Plug 'L3MOn4d3/LuaSnip' -- snippets plugin

Plug 'neovim/nvim-lspconfig'
Plug 'preservim/nerdtree'
Plug 'tpope/vim-surround'

-- end of plugin defining
vim.call('plug#end')
-- end vim-plug setup }}}

-- vim.cmd("colorscheme everforest")

--- simple nvim specific setups {{{
require('scrollbar').setup()
-- end simple setups }}}

--- treesitter setup {{{
require 'nvim-treesitter.configs'.setup {
    ensure_installed = 'all',             -- 'all', 'maintained', or a table of languages
    sync_install = true,                  -- install languages synchronously (only applied to `ensure_installed`)
    -- ignore_install = { 'javascript' }, -- list of parsers to ignore installing
    highlight = {
        enable = true,                    -- `false` will disable the whole extension
        --disable = { 'c', 'rust' },      -- list of languages that will be disabled
        additional_vim_regex_highlighting = true,
    },
}
-- end treesitter setup }}}

--- fugitive::git {{{
nnoremap('<leader>G', ':tab G<enter>')
nnoremap('<leader>b', ':G branch<enter>')
-- end fugitive}}}

--- nerd tree {{{
nnoremap('<leader>t', ':NERDTreeFind<enter>:set rnu<enter>')       -- at current working directory
nnoremap('<leader>T', ':NERDTreeToggleVCS<enter>:set rnu<enter>')  -- at vcs toplevel
GSet.NERDTreeWinSize = 50
GSet.NERDTreeShowBookmarks = 1

--- opens new kitty tab at specified path or `current` directory.
-- @tparam path (string) path to the location of the new tab.
function NewKittyTab(path)
    vim.fn.system('kitty @ launch --cwd=' .. (path or 'current') .. ' --type=tab')
end

--- opens kitty tab at directory of current node.
-- setting it globally to vim allows it to be used as a callback.
-- (it's registered as a global vim function this way)
GSet.NERDTreeOpenKittyTabHere = function()
    local node_path_table = vim.api.nvim_eval('g:NERDTreeFileNode.GetSelected()').path
    local file_name

    -- pop last entry in path segments if it's not a directory. stores file_name.
    if node_path_table.isDirectory == 0 then
        file_name = table.remove(node_path_table.pathSegments)
    end

    local path_str = table.concat(node_path_table.pathSegments, '/')
    NewKittyTab('/' .. path_str) -- need to enforce absolute path.
end

--- create the menu items after everything has been loaded using an autocmd.{{{
vim.api.nvim_create_autocmd(
    {'VimEnter'},
    { callback =
        function()
            vim.fn.NERDTreeAddMenuItem{
                text = 'New kitty (t)erminal tab from this directory.',
                shortcut = 't',
                callback = 'g:NERDTreeOpenKittyTabHere',
            }
        end,
    }
) -- end of autocmd }}}

-- end nerdtree config }}}

--- fzf::fuzzy finder {{{
local patterns = { '!*.class', '!*.jar', '!*.java.html', '!*.git*' }
local pattern_string
for _, pattern in ipairs(patterns) do
    if pattern_string then pattern_string = pattern_string .. " --glob='" .. pattern .. "'"
    else pattern_string = " --glob='" .. pattern .. "'" end
end
local rg_string = 'rg --hidden --column --line-number --with-filename --no-heading'
local grep_full = rg_string .. pattern_string .. ' ""'

--- uses fzf for a live fuzzy grep
-- @param args (table)
function LiveFuzzyGrep()
    vim.fn['fzf#run'](vim.fn['fzf#wrap']({
        source = grep_full, sink = GSet.GoToGrepResult
    }))
end

--- opens file from grep result and goes to line, col.
GSet.GoToGrepResult = function(grep_result)
    if not grep_result then return end

    grep_result = grep_result .. ':'
    local grep_table = {}
    for match in string.gmatch(grep_result, '([%w%.%-%_%/]+):') do
        table.insert(grep_table, match)
    end
    vim.cmd('e ' .. grep_table[1]) -- 1 is the file path.
    vim.fn.cursor(grep_table[2], grep_table[3]) -- 2 is the row, 3 is column.
end

nnoremap('<leader>f', ':FZF<enter>')
nnoremap('<leader>g', ':lua LiveFuzzyGrep()<enter>')
-- end fzf }}}

--- lsp server configs {{{
require('nvim-lsp-installer').setup{}
local servers = {
    'pyright',
    'jdtls',
    'sumneko_lua',
    'terraformls',
    'bashls',
    'remark_ls',
    'rnix',
    'vimls',
    'tsserver',
}
local capabilities = require('cmp_nvim_lsp').update_capabilities(vim.lsp.protocol.make_client_capabilities())

local r = require('lspconfig')
for _, s in pairs(servers) do
    if s == 'sumneko_lua' then
        r[s].setup {
            capabilities = capabilities,
            settings = { Lua = { version = 'LuaJIT', diagnostics = { globals = { 'vim' } } } }
        }
    elseif s == 'bashls' then
        r[s].setup {
            capabilities = capabilities,
            filetypes = { "sh", "bash", "zsh" }
        }
    elseif s == 'jdtls' then
        r[s].setup {
            capabilities = capabilities,
            java_home = (vim.env.HOME .. "/.jabba/jdk/openjdk@1.17.0/Contents/Home"),
            -- cmd_env = { -- doesn't actually seem to work
            --     JAVA_HOME = (vim.env.HOME .. "/.jabba/jdk/openjdk@1.17.0/Contents/Home")
            -- },
            use_lombok_agent = true
        }
    else
        r[s].setup {
            capabilities = capabilities,
        }
    end
end
-- end server configs }}}

-- luasnip setup {{{
LS = require 'luasnip'
-- end luasnip setup }}}

--- auto complete settings. depends on luasnip {{{
-- nvim-cmp setup
local cmp = require 'cmp'
cmp.setup {
  snippet = {
    expand = function(args)
      LS.lsp_expand(args.body)
    end,
  },
  mapping = cmp.mapping.preset.insert({
    -- ['<C-d>'] = cmp.mapping.scroll_docs(-4),
    -- ['<C-f>'] = cmp.mapping.scroll_docs(4),
    -- ['<C-Space>'] = cmp.mapping.complete(),
    -- ['<CR>'] = cmp.mapping.confirm {
    --   behavior = cmp.ConfirmBehavior.Replace,
    --   select = true,
    -- },
    -- ['<Tab>'] = cmp.mapping(function(fallback)
    --   if LS.expand_or_jumpable() then
    --     LS.expand_or_jump()
    --   elseif cmp.visible() then
    --     cmp.select_next_item()
    --   else
    --     fallback()
    --   end
    -- end, { 'i', 's' }),
    -- ['<S-Tab>'] = cmp.mapping(function(fallback)
    --   if LS.jumpable(-1) then
    --     LS.jump(-1)
    --   elseif cmp.visible() then
    --     cmp.select_prev_item()
    --   else
    --     fallback()
    --   end
    -- end, { 'i', 's' }),
  }),
  sources = {
    { name = 'luasnip' },
    { name = 'nvim_lsp' },
  },
}
-- end autocomplete config }}}

-- vim: fdm=marker foldlevel=0
