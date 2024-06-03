(local {: get-branch-text} (require :pack.lines.util.options))
(local {: concat} table)

(local {: format : transition : reversed} (require :pack.lines.util.component))
(local {: tabpagenr : tabpagewinnr :win_getid win-getid : fnamemodify} vim.fn)
(local {:nvim_win_get_buf win-getbuff :nvim_buf_get_name buf-getname} vim.api)
(local {: right-align : left-tr} (require :pack.lines.util.symbols))

(local hl-group
       {:normal :Tabline
        :fill :Statusline
        :selected (reversed :Tabline :TablineSelected)})

(fn tab-iter [total-tabs i]
  (let [i (+ i 1)]
    (if (< i (+ total-tabs 1))
        i
        nil)))

(fn tabs-iter []
  (values tab-iter (tabpagenr "$") 0))

(do
  (set vim.g.LinesMakeTabline #(let [selected (tabpagenr)
                                     tabs (icollect [i (tabs-iter)]
                                            (let [highlight (if (= i selected)
                                                                hl-group.selected
                                                                hl-group.normal)
                                                  buf-name (-> (tabpagewinnr i)
                                                               (win-getid i)
                                                               (win-getbuff)
                                                               (buf-getname)
                                                               (fnamemodify ":t"))]
                                              (concat [(format highlight)
                                                       " "
                                                       i
                                                       " "
                                                       buf-name
                                                       " "]
                                                      "")))]
                                 (concat [(format hl-group.normal)
                                          " "
                                          (get-branch-text)
                                          " "
                                          (transition hl-group.fill
                                                      hl-group.normal
                                                      :background left-tr)
                                          (format hl-group.fill)
                                          right-align
                                          " "
                                          (concat tabs)]
                                         "")))
  (vim.cmd "set tabline=%!LinesMakeTabline()"))

{}
; SetMakeRunner nvim --headless +"silent e utils.fnl" +"lua print(vim.g.MakeTabline())" +"lua print(vim.g.LinesMakeTabline())" +q
