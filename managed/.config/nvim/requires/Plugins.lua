--- @author jarrin-p
--- @file `Plugins.lua`

require 'Util'

--- vim-plug initialization {{{
local Plug = vim.fn['plug#']
if vim.fn.has('unix') == 1 then vim.call('plug#begin', '~/.config/nvim/autoload/plugged')
elseif vim.fn.has('mac') == 1 then vim.call('plug#begin', '~/.config/nvim/autoload/plugged')
end

-- import plugins

Plug 'sainnhe/vim-color-forest-night'

Plug 'tpope/vim-fugitive'
Exec "Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }"
Plug 'vimwiki/vimwiki'

Exec "Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}"
Plug 'williamboman/nvim-lsp-installer'

Plug 'hrsh7th/nvim-cmp' -- autocompletion plugin
Plug 'hrsh7th/cmp-nvim-lsp' -- lsp source for nvim-cmp
Plug 'saadparwaiz1/cmp_luasnip' -- snippets source for nvim-cmp
Plug 'L3MOn4d3/LuaSnip' -- snippets plugin

Plug 'neovim/nvim-lspconfig'
Plug 'preservim/nerdtree'
-- TODO Plug 'put luatree here'
Plug 'tpope/vim-surround'

-- end of plugin defining
vim.call('plug#end')
-- end vim-plug setup }}}

--- simple nvim specific setups {{{
vim.cmd("colorscheme everforest")
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
vim.g.NERDTreeWinSize = 50
vim.g.NERDTreeShowBookmarks = 1

-- open nerdtree as soon as vim opens. make it full screen if no other buffer is open
function NERDTreeStartupBehavior()
    vim.api.nvim_command('NERDTreeToggleVCS') -- open nerdtree
    vim.api.nvim_command('wincmd p')
    if CurrentBufIsEmpty() then vim.api.nvim_command('q') end
end
vim.api.nvim_create_autocmd({'VimEnter'}, { callback = NERDTreeStartupBehavior })

-- adds a filter list to NERDTree. {{{
-- TODO view the filter api instead.
Exec([[ command! -nargs=1 NTI let NERDTreeIgnore=<args> ]], false) -- takes an array }}}

--- opens new kitty tab at specified path or `current` directory. {{{
-- @tparam path (string) path to the location of the new tab.
function NewKittyTab(path)
    vim.fn.system('kitty @ launch --cwd=' .. (path or 'current') .. ' --type=tab')
end -- }}}

--- opens kitty tab at directory of current node. {{{
-- setting it globally to vim allows it to be used as a callback.
-- (it's registered as a global vim function this way)
vim.g.NERDTreeOpenKittyTabHere = function()
    local node_path_table = vim.api.nvim_eval('g:NERDTreeFileNode.GetSelected()').path
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

-- fzf enhancements {{{

--- wraps the api call into something more friendly to `lua`.
--- @param source_cmd string the string grep command whose result will be used for input.
--- @param sink_fn function the callback that will be used for handling the result.
function FzfWrapper(source_cmd, sink_fn)
    vim.fn['fzf#run'](vim.fn['fzf#wrap']({ source = source_cmd, sink = sink_fn }))
end

--- fuzzy find internal or external things.
--- @param build_cmd_opts rg_cmd_opts options to be used for the BuildRipGrepCommand function.
--- @param result_handler_fn function vim.g.function takes a string, will be executed on the selected entry.
function FzfSearch(build_cmd_opts, result_handler_fn)
    vim.g.FzfSearchFn = result_handler_fn -- the fzf sink needs to be wrapped into a global function to be accessed.
    FzfWrapper(BuildRipGrepCommand(build_cmd_opts), vim.g.FzfSearchFn)
end
-- end fzf search }}}
--- grep {{{
function LiveFuzzyGrep()
    FzfSearch({
        grep_args = function()
            local all_flags = { '--hidden', '--column', '--line-number', '--with-filename', '--no-heading' }
            local exclude_globs = PrependToEachTableEntry({ '"!*.class"', '"!*.jar"', '"!*.java.html"', '"!*.git*"' }, "--glob=")
            for _, flag in ipairs(exclude_globs) do table.insert(all_flags, flag) end
            return all_flags
        end
    },
        function(grep_result)
            local grep_result_as_table = SplitStringToTable(grep_result, ':')
            vim.cmd('e ' .. grep_result_as_table[1]) -- 1 is the file path.
            vim.fn.cursor(grep_result_as_table[2], grep_result_as_table[3]) -- 2 is the row, 3 is column.
        end
    )
end
-- end live fuzzy grep }}}
--- buffer selection {{{
function LiveBufSelect()
    FzfSearch({
        t = GetListedBufNames,
    },
        function(grep_result)
            vim.cmd('e ' .. grep_result)
        end
    )
end
-- end fzf live buffer select }}}
--- git branch selection {{{
function LiveGitBranchSelection()
    FzfSearch({
        t = function()
            -- runs a system command to get all git branches then splits them into a table based on newlines.
            local branches = SplitStringToTable(vim.fn.system('git branch --no-color'), '\n')
            for i, branch in ipairs(branches) do branches[i] = string.gsub(branch, ' ', '') end
            return branches
        end,
    },
    function(grep_result)
        if (grep_result:find('*')) == 1 then
            print('already on this branch!')
        else
            vim.cmd('G branch ' .. grep_result)
        end
    end
    )
end
-- end git branch selection }}}
--- remaps {{{
nnoremap('<leader>g', ':lua LiveFuzzyGrep()<enter>')
nnoremap('<leader>b', ':lua LiveBufSelect()<enter>')
nnoremap('<leader>B', ':lua LiveGitBranchSelection()<enter>')
nnoremap('<leader>f', ':FZF<enter>')
-- }}}

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
