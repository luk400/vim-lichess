fun! lichess#setup_mappings() abort
    setlocal colorcolumn=
    setlocal mouse=a
    nnoremap <buffer> <silent> <LeftMouse> <LeftMouse>:silent let b:lichess_pos_init = getpos(".")[1:2]<cr>
    nnoremap <buffer> <silent> <RightMouse> <RightMouse><esc>:call lichess#play#make_move(getpos(".")[1:2])<cr>
    
    if !hasmapto('LichessMakeMoveUCI', 'n')
        nnoremap <buffer> <leader>lm :LichessMakeMoveUCI<cr>
    endif
    if !hasmapto('LichessChat', 'n')
        nnoremap <buffer> <leader>lc :LichessChat 
    endif
    if !hasmapto('LichessAbort', 'n')
        nnoremap <buffer> <leader>la :LichessAbort<cr>
    endif
    if !hasmapto('LichessResign', 'n')
        nnoremap <buffer> <leader>lr :LichessResign<cr>
    endif
    if !hasmapto('LichessOfferDraw', 'n')
        nnoremap <buffer> <leader>ldo :LichessOfferDraw<cr>
    endif
    if !hasmapto('LichessAcceptDraw', 'n')
        nnoremap <buffer> <leader>lda :LichessAcceptDraw<cr>
    endif
    if !hasmapto('LichessDeclineDraw', 'n')
        nnoremap <buffer> <leader>ldd :LichessDeclineDraw<cr>
    endif
endfun


if !hasmapto('lichess#play#find_game()', 'n')
    nnoremap <leader>ch :call lichess#play#find_game()<cr>
endif


command! -nargs=1 LichessChat :call lichess#play#write_msg(<q-args>)
command! LichessFindGame :call lichess#play#find_game()
command! LichessResign :call lichess#play#resign_game()
command! LichessAbort :call lichess#play#abort_game()
command! LichessClaimVictory :call lichess#play#claim_victory()
command! LichessDrawDecline :call lichess#play#draw_offer('no')
command! LichessDrawOfferAccept :call lichess#play#draw_offer('yes')
command! LichessTakebackOfferAccept :call lichess#play#takeback_offer('yes')
command! LichessTakebackOfferDecline :call lichess#play#takeback_offer('no')
command! LichessMakeMoveUCI :call lichess#play#make_move_keyboard()


" time (integer in minutes) - must be >= 8, since lichess API only allows rapid or classical games
let g:lichess_time = get(g:, 'lichess_time', 10)
" increment (integer in seconds)
let g:lichess_increment = get(g:, 'lichess_increment', 0)
" rated = False
let g:lichess_rated = get(g:, 'lichess_rated', 1)
" variant = "standard"
let g:lichess_variant = get(g:, 'lichess_variant', "standard")
" color = "random"
let g:lichess_color = get(g:, 'lichess_color', "random")
" rating_range = None (can be passed as [low,high])
let g:lichess_rating_range = get(g:, 'lichess_rating_range', [])
" set debug level
let g:lichess_debug_level = get(g:, 'lichess_debug_level', -1)
" whether to automatically promote to queen or not
let g:lichess_autoqueen = get(g:, 'lichess_autoqueen', 1)
" command for python executable to run server in background (can also be full path)
let g:python_cmd = get(g:, 'python_cmd', 'python3')
