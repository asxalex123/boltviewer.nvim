if exists('g:loaded_boltviewer')
    finish
endif

let g:loaded_boltviewer = 1

command! Boltviewer lua require'boltviewer'.open_win()
