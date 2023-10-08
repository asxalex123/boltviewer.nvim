
if exists('g:loaded_boltviewer')
    call BoltviewerLoad()
    finish
endif

let g:loaded_boltviewer = 1

" boltviewer golang
function! s:Requirebolt(host) abort
        return jobstart(['boltviewer'], {'rpc': v:true})
endfunction

call remote#host#Register('boltviewer', 'x', function('s:Requirebolt'))

call remote#host#RegisterPlugin('boltviewer', '0', [
\ {'type': 'function', 'name': 'BoltviewerCreateBucket', 'sync': 1, 'opts': {}},
\ {'type': 'function', 'name': 'BoltviewerCreateEntry', 'sync': 1, 'opts': {}},
\ {'type': 'function', 'name': 'BoltviewerCreateEntryAnyway', 'sync': 1, 'opts': {}},
\ {'type': 'function', 'name': 'BoltviewerDeleteBucket', 'sync': 1, 'opts': {}},
\ {'type': 'function', 'name': 'BoltviewerDeleteEntry', 'sync': 1, 'opts': {}},
\ {'type': 'function', 'name': 'BoltviewerLoad', 'sync': 1, 'opts': {}},
\ ])

function! GetBucketName()
    let @" = ""
    execute "normal! ma$?^[^ \t].*$\<cr>viwy:nohl\<cr>`a"
    return @"
endfunction

function! GetBucketLine()
    execute "normal! ma$?^[^ \t].*$\<cr>:let tempname=nvim_win_get_cursor(0)\<cr>:nohl\<cr>`a"
    return tempname[0]
endfunction

function! BoltviewerInsertBucket()
    lua require'boltviewer'.lua_insert_bucket()
endfunction

function! BoltviewerInsertEntry()
    lua require'boltviewer'.lua_insert_entry()
endfunction

function! BoltviewerDelete()
    lua require'boltviewer'.delete()
endfunction

function! BoltviewerModifyEntry()
    lua require'boltviewer'.lua_modify_entry()
endfunction

call BoltviewerLoad()

nnoremap <leader>bib :call BoltviewerInsertBucket()<cr>
nnoremap <leader>bie :call BoltviewerInsertEntry()<cr>
nnoremap <leader>bd :call BoltviewerDelete()<cr>
nnoremap <leader>bm :call BoltviewerModifyEntry()<cr>

" lua require'boltviewer'.init_bolt()
