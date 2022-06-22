--- @author jarrin-p
--- @file `Plugins.lua`

--- setup {{{
LS = require 'luasnip'
SelectChoice = require 'luasnip.extras.select_choice'
LS.cleanup() -- clears all snippets
-- end setup }}}

--- insert mode remaps {{{
vim.api.nvim_set_keymap(
    'i',
    '<tab>',
    '<c-o>:lua LS.expand_or_jump()<enter><c-o>:lua MakeStatusLine()<enter>',
    {noremap = true, silent = true}
)
vim.api.nvim_set_keymap(
    'i',
    '<c-j>',
    '<c-o>:lua LS.change_choice(1)<enter><c-o>:lua MakeStatusLine()<enter>',
    {noremap = true, silent = true}
)
vim.api.nvim_set_keymap(
    'i',
    '<c-k>',
    '<c-o>:lua LS.change_choice(-1)<enter><c-o>:lua MakeStatusLine()<enter>',
    {noremap = true, silent = true}
)
-- end insert mode remaps }}}

--- lua snippets {{{
LS.add_snippets("lua",
    {
        -- function snippet
        LS.snippet("fn",
        {
            LS.choice_node(1, {
                LS.text_node({""}),
                LS.text_node({"local "})
            }),
            LS.text_node("function "),
            LS.insert_node(2, "functionName"),
            LS.text_node({"("}), -- linebreaks are ""
            LS.insert_node(3),
            LS.text_node({")", "" }), -- linebreaks are ""
            LS.text_node({"\t"}),
            LS.insert_node(0),
            LS.text_node({"", "end"}),
        })
    }
)
--- end lua snippets }}}

--- java snippets {{{
LS.add_snippets("java", {
        LS.snippet("pr", -- System.out.println()
        {
            LS.text_node({'System.out.println("'}),
            LS.insert_node(0),
            LS.text_node({'");'}),
        }),
        LS.snippet("log.i", -- log.info
        {
            LS.text_node({'log.info("'}),
            LS.insert_node(0),
            LS.text_node({'");'}),
        }),
        LS.snippet('log.e', -- log.error
        {
            LS.text_node({'log.error("'}),
            LS.insert_node(0),
            LS.text_node({'");'}),
        }),
        LS.snippet('@Mapping', -- mapping
        {
            LS.text_node({'@Mapping(source = "'}),
            LS.insert_node(1, 'sourceName'),
            LS.text_node({'", target = "'}),
            LS.insert_node(2, 'targetName'),
            LS.text_node({'")'}),
        }),
        LS.snippet('class', -- class
        {
            LS.choice_node(1, {
                LS.text_node({"private "}),
                LS.text_node({"public "}),
                LS.text_node({""}),
            }),
            LS.text_node({"class "}), -- linebreaks are ""
            LS.insert_node(2, "className"),
            LS.text_node({" {", "" }), -- linebreaks are ""
            LS.insert_node(0),
            LS.text_node({"", "}"}),
        }),
        LS.snippet('fn', -- function
        {
            LS.choice_node(1, {
                LS.text_node({"private "}),
                LS.text_node({"public "}),
                LS.text_node({""}),
            }),
            LS.choice_node(2, {
                LS.text_node({""}),
                LS.text_node({"static "}),
            }),
            LS.insert_node(3, "returnType"),
            LS.text_node({" {", "" }), -- linebreaks are ""
            LS.text_node({"\t"}),
            LS.insert_node(0),
            LS.text_node({"", "}"}),
        }),
})
--- end java snippets }}}

-- vim: fdm=marker foldlevel=0
