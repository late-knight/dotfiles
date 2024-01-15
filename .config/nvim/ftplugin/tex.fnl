(let [callback (fn [event]
                 (let [open (. (require :io) :open)]
                   (case (open :Makefile :r)
                     [nil err] (print err)
                     f (vim.api.nvim_exec2 "silent make build" {})
                     _ (print :shit))))]
  (vim.api.nvim_create_autocmd [:BufWritePost]
                               {:pattern [:*.tex :*.sty] : callback}))

{}
