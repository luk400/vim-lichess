"""""""""""""""""""
" get piece symbols
"""""""""""""""""""
let p = get(g:, 'lichess_piece_p',
    \   ["            ",
    \    "     ,,     ",
    \    "    ,,,,    ",
    \    "    ,,,,    ",
    \    "    ,,,,    ",
    \    "            "])
let r = get(g:, 'lichess_piece_r',
    \   ["            ",
    \    "   , ,, ,   ",
    \    "   ,,,,,,   ",
    \    "   ,,,,,,   ",
    \    "  ,,,,,,,,  ",
    \    "            "])
let k = get(g:, 'lichess_piece_k',
    \   ["            ",
    \    "     ,,     ",
    \    "  ,,,,,,,,  ",
    \    "     ,,     ",
    \    "     ,,     ",
    \    "            "])
let q = get(g:, 'lichess_piece_q',
    \   ["            ",
    \    "   , ,, ,   ",
    \    "    ,,,,    ",
    \    "     ,,     ",
    \    "   ,,,,,,   ",
    \    "            "])
let b = get(g:, 'lichess_piece_b',
    \   ["            ",
    \    "    ,,,,    ",
    \    "    ,,,,    ",
    \    "     ,,     ",
    \    "   ,,,,,,   ",
    \    "            "])
let n = get(g:, 'lichess_piece_n',
    \   ["            ",
    \    "    ,,,     ",
    \    "  ,,, ,,    ",
    \    "     ,,,    ",
    \    "   ,,,,,,   ",
    \    "            "])

let P = get(g:, 'lichess_piece_P',
    \   ["            ",
    \    "     ;;     ",
    \    "    ;;;;    ",
    \    "    ;;;;    ",
    \    "    ;;;;    ",
    \    "            "])
let R = get(g:, 'lichess_piece_R',
    \   ["            ",
    \    "   ; ;; ;   ",
    \    "   ;;;;;;   ",
    \    "   ;;;;;;   ",
    \    "  ;;;;;;;;  ",
    \    "            "])
let K = get(g:, 'lichess_piece_K',
    \   ["            ",
    \    "     ;;     ",
    \    "  ;;;;;;;;  ",
    \    "     ;;     ",
    \    "     ;;     ",
    \    "            "])
let Q = get(g:, 'lichess_piece_Q',
    \   ["            ",
    \    "   ; ;; ;   ",
    \    "    ;;;;    ",
    \    "     ;;     ",
    \    "   ;;;;;;   ",
    \    "            "])
let B = get(g:, 'lichess_piece_B',
    \   ["            ",
    \    "    ;;;;    ",
    \    "    ;;;;    ",
    \    "     ;;     ",
    \    "   ;;;;;;   ",
    \    "            "])
let N = get(g:, 'lichess_piece_N',
    \   ["            ",
    \    "    ;;;     ",
    \    "  ;;; ;;    ",
    \    "     ;;;    ",
    \    "   ;;;;;;   ",
    \    "            "]
    \)


"""""""""""""""""""""""""""""""""
" check validity of piece symbols
"""""""""""""""""""""""""""""""""
let black_pieces = [p, r, k, q, b, n]
let white_pieces = [P, R, K, Q, B, N]
let i = 0
for piece_set in [black_pieces, white_pieces]
    for piece in piece_set
        let str_concat = join(split(join(piece)), '')
        let all_chars = split(str_concat, '\zs')
        let unique_chars = filter(copy(all_chars), 'index(all_chars, v:val, v:key+1)==-1')
        let err_msg = 'Error: all piece representations must contain exactly one '
            \ . 'unique character (ignoring whitespaces), and there must be exactly '
            \ . 'one such character for the white and one for the black pieces!'
        if !(len(unique_chars) == 1)
            echohl ErrorMsg | echom err_msg | echohl None
            finish
        endif

        if i==0 && !exists('s:black_piece_char')
            let s:black_piece_char = unique_chars[0]
        elseif i==0 && unique_chars[0] != s:black_piece_char
            echohl ErrorMsg | echom err_msg | echohl None
            finish
        elseif i==1 && !exists('s:white_piece_char')
            let s:white_piece_char = unique_chars[0]
        elseif i==1 && unique_chars[0] != s:white_piece_char
            echohl ErrorMsg | echom err_msg | echohl None
            finish
        endif

        let h = len(piece)

        let err_msg = 'Error: all piece representations must have the same height!'
        if !exists('s:square_height')
            let s:square_height = h
        elseif h != s:square_height
            echohl ErrorMsg | echom err_msg | echohl None
            finish
        endif

        for l in piece
            let w = len(l)
            if !exists('s:square_width')
                let s:square_width = w
            elseif w != s:square_width
                echohl ErrorMsg | echom err_msg | echohl None
                finish
            endif
        endfor
    endfor
    let i += 1
endfor

if s:black_piece_char == s:white_piece_char
    let err_msg = "Error: white piece character and black piece character can't be the same!"
    echohl ErrorMsg | echom err_msg | echohl None
    finish
elseif len(s:black_piece_char) != 1
    let err_msg = "Error: Only piece characters with length 1 allowed (check via `len`"
        \ . " in vim), otherwise the cursor position can't be determined correctly! "
        \ . "Current character for black pieces (" . s:black_piece_char . "): "
        \ . "len(" . s:black_piece_char . ")=" . len(s:black_piece_char)
    echohl ErrorMsg | echom err_msg | echohl None
    finish
elseif len(s:white_piece_char) != 1
    let err_msg = "Error: Only piece characters with length 1 allowed (check via `len`"
        \ . " in vim), otherwise the cursor position can't be determined correctly! "
        \ . "Current character for white pieces (" . s:white_piece_char . "): "
        \ . "len(" . s:white_piece_char . ")=" . len(s:white_piece_char)
    echohl ErrorMsg | echom err_msg | echohl None
    finish
endif

fun! lichess#play#get_square_dim_and_piece_chars() abort
    return [s:square_width, s:square_height, s:white_piece_char, s:black_piece_char]
endfun


"""""""""""""""""""""""""""""""""""""""""
" other needed variables and highlighting
"""""""""""""""""""""""""""""""""""""""""
let s:lichess_fen = "None"
let s:hl_was_set = 0
let yoffset = 2
let xoffset = 0

if !hlexists('lichess_move_info')
    highlight lichess_move_info guibg=#9ea832 guifg=#000000 ctermbg=3 ctermfg=0 cterm=bold gui=bold
endif
if !hlexists('lichess_too_many_requests')
    highlight lichess_too_many_requests guibg=#c20202 guifg=#ffffff ctermbg=15 ctermfg=9 cterm=bold gui=bold
endif
if !hlexists('lichess_user_turn')
    highlight lichess_user_turn guibg=#3eed6c guifg=#000000 ctermbg=2 ctermfg=0 cterm=bold gui=bold
endif
if !hlexists('lichess_user_noturn')
    highlight lichess_user_noturn guifg=#ffffff ctermfg=15 cterm=bold gui=bold
endif
if !hlexists('lichess_searching_game')
    highlight lichess_searching_game guifg=#42d7f5 guibg=#000000 ctermfg=14 ctermbg=0 cterm=bold gui=bold
endif
if !hlexists('lichess_game_ended')
    highlight lichess_game_ended guibg=#e63c30 guifg=#ffffff ctermbg=1 ctermfg=15 cterm=bold gui=bold
endif
if !hlexists('lichess_chat')
    highlight lichess_chat guibg=#e3f27e guifg=#000000 ctermbg=191 ctermfg=0
endif
if !hlexists('lichess_chat_system')
    highlight lichess_chat_system guibg=#ed8787 guifg=#000000 ctermbg=178 ctermfg=0
endif
if !hlexists('lichess_chat_bold')
    highlight lichess_chat_bold guibg=#e3f27e guifg=#000000 ctermbg=191 ctermfg=0 cterm=bold gui=bold
endif
if !hlexists('lichess_chat_you')
    highlight lichess_chat_you guibg=#b4e364 guifg=#000000 ctermbg=190 ctermfg=0
endif


""""""""""""""""""""""""""""""""""""""""""""""""""""""
" dictionaries to map cursor position to board squares
""""""""""""""""""""""""""""""""""""""""""""""""""""""
let s:line_squareline_map_black = {}
for idx in range(1, s:square_height * 8)
    let s:line_squareline_map_black[yoffset + 1 + idx] = float2nr(ceil(str2float(idx) / s:square_height))
endfor
let s:line_squareline_map_black[yoffset + 1] = 8
let s:line_squareline_map_black[s:square_height * 8 + yoffset + 2] = 1

let s:line_squareline_map_white = {}
for idx in range(1, s:square_height * 8)
    let s:line_squareline_map_white[yoffset + 1 + idx] = 9 - float2nr(ceil(str2float(idx) / s:square_height))
endfor
let s:line_squareline_map_white[yoffset + 1] = 1
let s:line_squareline_map_white[s:square_height * 8 + yoffset + 2] = 8


let s:col_squarecol_map_white = {}
for idx in range(1, 8 + s:square_width * 8)
    let s:col_squarecol_map_white[xoffset + idx] = float2nr(ceil(str2float(idx) / (s:square_width + 1)))
endfor
let s:col_squarecol_map_white[8 + s:square_width * 8 + 1] = 1

let s:col_squarecol_map_black = {}
for idx in range(1, 8 + s:square_width * 8)
    let s:col_squarecol_map_black[xoffset + idx] = 9 - float2nr(ceil(str2float(idx) / (s:square_width + 1)))
endfor
let s:col_squarecol_map_black[8 + s:square_width * 8 + 1] = 8


let s:col_idx_to_letter = {1: 'a', 2: 'b', 3: 'c', 4: 'd', 5: 'e', 6: 'f', 7: 'g', 8: 'h'}


""""""""""""""""""""
" gameplay functions
""""""""""""""""""""
fun! lichess#play#write_msg(msg_txt) abort
    if a:msg_txt == ''
        return
    endif
    let msg = '<write_message>' . a:msg_txt
    call s:query_server(msg)
endfun


fun! lichess#play#abort_game() abort
    let response = s:query_server("abort_game")
    call s:check_for_query_error(response)
    call lichess#util#log_msg('Game aborted. Response: ' . response, 0)
endfun


fun! lichess#play#resign_game() abort
    let response = s:query_server("resign_game")
    call s:check_for_query_error(response)
    call lichess#util#log_msg('Game resigned. Response: ' . response, 0)
endfun


fun! lichess#play#claim_victory() abort
    let response = s:query_server("claim_victory")
    call s:check_for_query_error(response)
    call lichess#util#log_msg('Tried to claim victory. Response: ' . response, 0)
endfun


fun! lichess#play#draw_offer(accept) abort
    let response = s:query_server("<draw_offer>" . a:accept)
    call s:check_for_query_error(response)
    call lichess#util#log_msg('Handle draw offer - accept=' . a:accept . ' - response: ' . response, 0)
endfun


fun! lichess#play#takeback_offer(accept) abort
    let response = s:query_server("<takeback_offer>" . a:accept)
    call s:check_for_query_error(response)
    call lichess#util#log_msg('Handle takeback offer - accept=' . a:accept . ' - response: ' . response, 0)
endfun


fun! lichess#play#make_move(pos_end) abort
    if !exists('b:lichess_pos_init')
        return
    endif

    let color = s:query_server('get_color')

    let pos_init_idx = s:cursor_pos_to_square_pos(b:lichess_pos_init, color)
    if type(pos_init_idx) != 3
        return
    endif
    let pos_init = s:col_idx_to_letter[pos_init_idx[1]] . pos_init_idx[0]
    unlet b:lichess_pos_init

    let pos_end_idx = s:cursor_pos_to_square_pos(a:pos_end, color)
    if type(pos_end_idx) != 3
        return
    endif
    let pos_end = s:col_idx_to_letter[pos_end_idx[1]] . pos_end_idx[0]

    let move_uci = pos_init . pos_end
    if !g:lichess_autoqueen && s:is_promotion(color, pos_init_idx, pos_end_idx)
        call lichess#util#log_msg('function lichess#play#make_move: pawn is promoting!', 1)
        let promotion_pieces = ['q', 'r', 'n', 'b']
        let new_piece = confirm("Choose promotion piece!", "&queen\n&rook\nk&night\n&bishop", 1)
        let move_uci = pos_init . pos_end . promotion_pieces[new_piece - 1]
    endif

    echo
    call s:query_server('<set_move>' . move_uci, 'lichess_move_info')
endfun


fun! lichess#play#make_move_keyboard() abort
    let move_uci = input('Enter move (UCI notation): ')
    echo
    call s:query_server('<set_move>' . move_uci, 'lichess_move_info')
endfun


fun! lichess#play#find_game() abort
    " required api token
    let g:lichess_api_token = get(g:, 'lichess_api_token', "") 
    if !len(g:lichess_api_token)
        echohl ErrorMsg | echom "No API Token found! You need to add `let g:lichess_api_token = YOUR_API_TOKEN` to your vim config using your generated Token!" |
            \ echom "You can easily create this API Token by logging in on lichess.org and then simply following the following link:" |
            \ echom "https://lichess.org/account/oauth/token/create?scopes[]=challenge:write&scopes[]=board:play&description=vim+lichess" |
            \ echohl None
        return
    endif

    let berserk_not_installed = stridx(system(g:python_cmd . ' -c "import berserk"'), 'ModuleNotFoundError') >= 0
    if berserk_not_installed
        let choice = confirm("Berserk is not installed and needed for vim-lichess. Install it now?", "&yes\n&no", 1)
        if choice == 1
            exe "!" . g:python_cmd . " -m pip install berserk"
        else
            echohl ErrorMsg | echom 'Berserk needs to be installed to use vim-lichess!' | echohl None
            finish
        endif
    endif

    if g:lichess_debug_level != -1
        let plugin_path = lichess#util#plugin_path()
        call writefile([g:lichess_debug_level], plugin_path . '/.debug_level')
    endif

    if !(expand('%') == 'newgame.chess')
        let shortmess_val = &shortmess
        setlocal shortmess+=A
        edit newgame.chess | setlocal buftype=nofile
        exe 'setlocal shortmess=' . shortmess_val
    endif

    let rated = g:lichess_rated ? "True" : "False"
    let rating_range = len(g:lichess_rating_range) ? '[' . join(g:lichess_rating_range, ',') . ']' : "None"
    let query = '<set_start_new_game>True/' . g:lichess_time . '-' . g:lichess_increment
        \ . '-' . rated . '-' . g:lichess_variant . '-' . g:lichess_color . '-' . rating_range
    if !exists('g:_lichess_server_started')
        call s:start_game_loop()
        sleep 500m
        let response = s:query_server(query)
    else
        let response = s:query_server(query)
    endif
    call s:check_for_query_error(response)

    call lichess#setup_mappings()
    syn clear lichess_searching_game
    syn match lichess_searching_game /Searching for game.../
    call append(0, ["Searching for game..."])
endfun


fun! lichess#play#update_board(...) abort
	let all_info = s:query_server('get_all_info')
    if s:check_for_query_error(all_info)
        echohl ErrorMsg | echom "Error getting game info" | echohl None
        return
    endif

	if all_info == 'None'
		return
	endif

	let all_info = substitute(all_info, ": False", ": 0", "g")
	let all_info = substitute(all_info, ": True", ": 1", "g")
	let all_info = substitute(all_info, ": None", ': "None"', "g")
	let all_info = json_decode(all_info)

    if all_info['last_err'] != "None"
        echohl ErrorMsg | echom all_info['last_err'] | echohl None
    endif

	let my_color = all_info['color']
    let searching_game = all_info['searching_game']

	if my_color == 'None'
        call lichess#util#log_msg('function lichess#play#update_board(): my_color is None', 1)
		return
	endif

    if searching_game != 0 " could also be 'None'
        let searching_game = 1
    endif

	let player_info = all_info['player_info']
	let player_times = all_info['player_times']
    let username = all_info['username']
	let s:lichess_fen = split(all_info['fen'], ' ')[0]
	let is_my_turn = all_info['is_my_turn']
	let status = all_info['status']
	let latest_move = all_info['latest_move']
	let messages = all_info['messages']
    let msg_sep = all_info['msg_sep']

	let opp_color = my_color == 'white' ? 'black' : 'white'
	if s:lichess_fen == 'None'
        call lichess#util#log_msg('function lichess#play#update_board(): fen is None', 1)
		return
	endif
	let curpos = getpos('.')
	silent! exe '%delete_'

    if latest_move != 'None' && my_color != 'None'
        let latest_move = s:get_row_col_move(latest_move, my_color)
    endif

	call lichess#board_setup#display_board(s:lichess_fen, latest_move) " DISPLAY BOARD

	if player_info != "None"
		let player_info = split(player_info, msg_sep)

		let my_rating = player_info[0]
		let opp_rating = player_info[1]
		let my_name = player_info[2]
		let opp_name = player_info[3]
		let my_title = player_info[4] == 'None' ? '' : player_info[4] . ' '
		let opp_title = player_info[5] == 'None' ? '' : player_info[5] . ' '

		let td_since_last = str2float(split(player_times, '/')[0])
		let my_time = str2float(split(split(player_times, '/')[1], '-')[0])
		let opp_time = str2float(split(split(player_times, '/')[1], '-')[1])

		if is_my_turn
			let my_time = float2nr(my_time - td_since_last)
			let opp_time = float2nr(opp_time)
		else
			let opp_time = float2nr(opp_time - td_since_last)
			let my_time = float2nr(my_time)
		endif

		if opp_time >= 0 && my_time >=0 && status == 'started'
			let g:lichess_opp_time = printf("%02d", opp_time / 3600) . ':' . printf("%02d", (opp_time % 3600) / 60) . ':' . printf("%02d", opp_time % 3600 % 60)
			let g:lichess_my_time = printf("%02d", my_time / 3600) . ':' . printf("%02d", (my_time % 3600) / 60) . ':' . printf("%02d", my_time % 3600 % 60)
		elseif !exists('g:lichess_opp_time') || !exists('g:lichess_my_time')
			let g:lichess_opp_time = '--:--:--'
			let g:lichess_my_time = '--:--:--'
		endif

		let opp_info = opp_title . opp_name . ' [' . opp_rating . '] - ' . g:lichess_opp_time
		let my_info = my_title . my_name . ' [' . my_rating . '] - ' . g:lichess_my_time
		syn clear lichess_user_turn
		syn clear lichess_user_noturn
		if is_my_turn
            exe 'syn match lichess_user_turn /^' . my_title . my_name . ' .*' . '/ containedin=ALL'
            exe 'syn match lichess_user_noturn /^' . opp_title . opp_name . ' .*' . '/ containedin=ALL'
		else
            exe 'syn match lichess_user_turn /^' . opp_title . opp_name . ' .*' . '/ containedin=ALL'
            exe 'syn match lichess_user_noturn /^' . my_title . my_name . ' .*' . '/ containedin=ALL'
		endif

		call append(0, [opp_info, ''])
		call append('$', my_info)

		if status != 'started'
			let pattern = '- ' . toupper(status) . ' -'
			syn clear lichess_game_ended
			exe 'syn match lichess_game_ended /' . pattern . '/ containedin=ALL'
			call append(0, [pattern, ''])
		endif

		if messages != 'None'
			if !s:hl_was_set
                syn match lichess_chat_bold /CHAT:/ containedin=ALL
                syn match lichess_chat /CHAT:\_.*/ containedin=ALL
                syn match lichess_chat_system /^> lichess:.*/ containedin=ALL
				exe 'syn match lichess_chat_you /^> ' . username . ':.*/ containedin=ALL'
                let s:hl_was_set = 1
			endif
            let msg_lines = split(messages, msg_sep)
			call map(msg_lines, {key, val -> '> ' . val})
			call append('$', ['', '', 'CHAT:'] + msg_lines)
		endif
	else
		call append(0, ['', ''])
		call append('$', '')
	endif

    if searching_game && status != 'started'
        syn clear lichess_searching_game
        syn match lichess_searching_game /Searching for game.../
        call append(0, ["Searching for game...", "", ""])
    endif

	call cursor(curpos[1], curpos[2])
endfun


""""""""""""""""""""""""
" script local functions
""""""""""""""""""""""""
fun! s:check_for_query_error(response, ...) abort
    if a:0 > 0
        let hlgroup = a:1
    else
        let hlgroup = -1
    endif

    let had_querry_error = a:response[:len('<QUERYERROR>')-1] == '<QUERYERROR>'
    if had_querry_error && hlgroup != -1
        exe "echohl " . hlgroup . " | " . "echom substitute(a:response, '<QUERYERROR>', '', '')" . " | echohl None"
        return 1
    elseif had_querry_error
        if stridx(a:response, 'is not in use anymore') < 0
            echom substitute(a:response, '<QUERYERROR>', '', '')
        endif
        return 1
    endif
    return 0
endfun


fun! s:query_server(query, ...) abort
    let plugin_path = lichess#util#plugin_path()
python3 << EOF
import os, sys, vim
plugin_path = vim.eval('plugin_path')
sys.path.append(os.path.join(plugin_path, 'python'))

from util import log_message, query_server

query = vim.eval('a:query')
port = int(vim.eval('g:_lichess_server_port'))

log_message(f'function s:query_server(): query - {query}')
try:
    response = query_server(query, port)
    if isinstance(response, bytes):
        response = response.decode('utf-8')

    if response is not None:
        response = response.replace("'", '"')
    vim.command(f"let response = '{response}'")
except Exception as e:
    log_message(f"function s:query_server(): {str(e)}", 2)
    vim.command(f"let response = '<QUERYERROR>{str(e)}'")
EOF

    if a:0 > 0
        let hlgroup = a:1
    else
        let hlgroup = -1
    endif

    call s:check_for_query_error(response, hlgroup)
    return response
endfun

function! s:get_row_col_move(move, color) abort
    let from_letter = matchstr(a:move, '^[a-h]')
    let from_number = matchstr(a:move, '^[a-h]\zs[1-8]')
    let to_letter = matchstr(a:move, '[a-h][1-8]\zs[a-h]')
    let to_number = matchstr(a:move, '[a-h][1-8][a-h]\zs[1-8]')

    if a:color == 'white'
        let letter_to_col = {'a': 1, 'b': 2, 'c': 3, 'd': 4, 'e': 5, 'f': 6, 'g': 7, 'h': 8}
        let from_row = 9 - from_number
        let to_row = 9 - to_number
        let from_col = letter_to_col[from_letter]
        let to_col = letter_to_col[to_letter]
    else
        let letter_to_col = {'a': 8, 'b': 7, 'c': 6, 'd': 5, 'e': 4, 'f': 3, 'g': 2, 'h': 1}
        let from_row = from_number
        let to_row = to_number
        let from_col = letter_to_col[from_letter]
        let to_col = letter_to_col[to_letter]
    endif
    return from_row . from_col . to_row . to_col
endfunction


fun! s:cursor_pos_to_square_pos(cursor_pos, color) abort
    let lnum = a:cursor_pos[0]
    let cnum = a:cursor_pos[1]

    if a:color == 'white'
        if !has_key(s:line_squareline_map_white, lnum) || !has_key(s:col_squarecol_map_white, cnum)
            echohl ErrorMsg | echom 'Invalid square' | echohl None
            return -1
        endif
        let square_row = s:line_squareline_map_white[lnum]
        let square_col = s:col_squarecol_map_white[cnum]
    else
        if !has_key(s:line_squareline_map_black, lnum) || !has_key(s:col_squarecol_map_black, cnum)
            echohl ErrorMsg | echom 'Invalid square' | echohl None
            return -1
        endif
        let square_row = s:line_squareline_map_black[lnum]
        let square_col = s:col_squarecol_map_black[cnum]
    endif

    return [square_row, square_col]
endfun


fun! s:is_promotion(color, pos_init_idx, pos_end_idx) abort
    if !(a:color == 'black' && a:pos_end_idx[0] == 1 || a:color == 'white' && a:pos_end_idx[0] == 8)
        return 0
    endif

    if s:lichess_fen == -1
        s:lichess_fen = s:query_server('get_fen')
        if s:lichess_fen == 'None'
            return 0
        endif
    endif

    let plugin_path = lichess#util#plugin_path()
python3 << EOF
import os, sys, vim
plugin_path = vim.eval('plugin_path')
sys.path.append(os.path.join(plugin_path, 'python'))

from util import fen_to_board
fen = vim.eval('s:lichess_fen')
color = vim.eval('a:color')
pos_init = [int(el) for el in vim.eval('a:pos_init_idx')]
board = fen_to_board(fen)
if color == 'white':
    idx_row = 8 - pos_init[0]
    idx_col = pos_init[1] - 1
else:
    idx_row = pos_init[0] - 1
    idx_col = 8 - pos_init[1]
is_pawn = int(board[idx_row][idx_col] in ['p', 'P'])
vim.command(f"let is_pawn = {is_pawn}")
EOF
    
    if !is_pawn
        return 0
    endif

    return 1
endfun


fun! s:kill_server() abort
    call lichess#util#log_msg('function s:send_kill_signal: sending kill signal', 0)
    call s:query_server('<kill>')
    if exists('g:_lichess_server_started')
        unlet g:_lichess_server_started
    endif
endfun


fun! s:set_port() abort
python3 << EOF
import socket
from contextlib import closing

def find_free_port():
    with closing(socket.socket(socket.AF_INET, socket.SOCK_STREAM)) as s:
        s.bind(('', 0))
        s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        return s.getsockname()[1]

port = find_free_port()
vim.command(f"let g:_lichess_server_port = {port}")
EOF
endfun


fun! s:start_game_loop() abort
    let g:_lichess_server_started = 1
    call s:set_port()
    let cmd = g:python_cmd . ' ' . lichess#util#plugin_path() . '/python/play_game.py '
        \ . g:_lichess_server_port . ' ' . g:lichess_api_token
    call lichess#util#log_msg('starting game loop', 0)
    if has('nvim')
        noautocmd exec "vsp|term " . cmd | let g:lichess_server_bufnr = bufnr() | setlocal nobl | hide
    else
        noautocmd exec "vsp|term ++curwin " . cmd | let g:lichess_server_bufnr = bufnr() | setlocal nobl | hide
    endif
    exe "autocmd QuitPre,BufDelete <buffer> :silent! bd! " . g:lichess_server_bufnr

    let updatetime = 0.5
    let timer_id = timer_start(str2nr(string(1000 * updatetime)),
        \ function('lichess#play#update_board'), {'repeat': -1})

    exe "au BufLeave <buffer> call timer_pause(" . timer_id . ", 1)"
    exe "au BufEnter <buffer> call timer_pause(" . timer_id . ", 0)"
    exe "au BufDelete <buffer> call timer_stop(" . timer_id . ")"
    au BufDelete <buffer> call s:kill_server()
    let s:hl_was_set = 0
    call lichess#board_setup#syntax_matching()
endfun


fun! OnExit(job_id, code, event) dict
    if a:code == 0
        exec 'bdelete ' . self.bufnr
    endif
endfun
