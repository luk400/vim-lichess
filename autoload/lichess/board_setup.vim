""""""""""""""""""""
" highlighting setup
""""""""""""""""""""
let params = lichess#play#get_square_dim_and_piece_chars()
let s:square_width = params[0]
let s:square_height = params[1]
let s:white_piece_char = params[2]
let s:black_piece_char = params[3]
let s:start_wcell = '`'
let s:start_bcell = "'"
let s:move_cell_dark = '-'
let s:move_cell_light = '_'

if !hlexists('lichess_cell_delimiters')
    highlight lichess_cell_delimiters guifg=#000000 guibg=#000000 ctermbg=0 ctermfg=0
endif
if !hlexists('lichess_black_squares')
    highlight lichess_black_squares guibg=#B58863 ctermbg=94
endif
if !hlexists('lichess_white_squares')
    highlight lichess_white_squares guibg=#F0D9B5 ctermbg=7
endif
if !hlexists('lichess_black_pieces')
    highlight lichess_black_pieces guifg=#000000 guibg=#000000 ctermbg=0 ctermfg=0
endif
if !hlexists('lichess_white_pieces')
    highlight lichess_white_pieces guifg=#ffffff guibg=#ffffff ctermbg=15 ctermfg=15
endif
if !hlexists('lichess_from_square_dark')
    highlight lichess_from_square_dark guifg=#AAA23A guibg=#AAA23A ctermbg=172 ctermfg=172
endif
if !hlexists('lichess_from_square_light')
    highlight lichess_from_square_light guifg=#CDD26A guibg=#CDD26A ctermbg=178 ctermfg=178
endif

let s:empty_line = repeat(' ', s:square_width)
let s:empty_line_move_dark = repeat(s:move_cell_dark, s:square_width)
let s:empty_line_move_light = repeat(s:move_cell_light, s:square_width)

fun! lichess#board_setup#syntax_matching() abort
    syn clear

    exe 'syn match lichess_cell_delimiters /' . s:start_wcell . '/ contains=ALL containedin=ALL'
    exe 'syn match lichess_cell_delimiters /' . s:start_bcell . '/ contains=ALL containedin=ALL'

    exe 'syn match lichess_black_squares /' . s:start_bcell . '.\{-}' . s:start_wcell . '/ containedin=ALL'
    exe 'syn match lichess_white_squares /' . s:start_wcell . '.\{-}' . s:start_bcell . '/ containedin=ALL'

    exe 'syn match lichess_black_pieces /' . s:black_piece_char . '/ containedin=lichess_black_squares,lichess_white_squares'
    exe 'syn match lichess_white_pieces /' . s:white_piece_char . '/ containedin=lichess_black_squares,lichess_white_squares'

    exe 'syn match lichess_from_square_dark /' . s:move_cell_dark . '/ containedin=lichess_black_squares,lichess_white_squares'
    exe 'syn match lichess_from_square_light /' . s:move_cell_light . '/ containedin=lichess_black_squares,lichess_white_squares'
endfun


""""""""""""""""
" board creation
""""""""""""""""
let s:piece_symbols = {
    \ 'p': p,
    \ 'r': r,
    \ 'k': k,
    \ 'q': q,
    \ 'b': b,
    \ 'n': n,
    \ 'P': P,
    \ 'R': R,
    \ 'K': K,
    \ 'Q': Q,
    \ 'B': B,
    \ 'N': N,
    \ }

function! s:create_board(fen, latest_move) abort
    " example FEN:
    " rn2k1r1/ppp1pp1p/3p2p1/5bn1/P7/2N2B2/1PPPPP2/2BNK1RR

    if a:latest_move != "None"
        let from_row = a:latest_move[0] - 1
        let from_column = a:latest_move[1] - 1
        let to_row = a:latest_move[2] - 1 
        let to_column = a:latest_move[3] - 1
    else
        let from_row = -1
        let from_column = -1
        let to_row = -1
        let to_column = -1
    endif
    
    let board = repeat(s:start_wcell, 9 + s:square_width * 8) . "\n"
    let i = 0
    for str in split(a:fen, '/')
        " rn2k1r1
        for j in range(s:square_height)
            let n = 0
            for char in str
                " r
                let next_cell_black = fmod(i + n, 2) == 0.0
                let is_move_cell = (i == from_row) && (n == from_column) || (i == to_row) && (n == to_column)
                if next_cell_black
                    let board = board . s:start_wcell
                else
                    let board = board . s:start_bcell
                endif

                if str2float(char) > 0
                    for k in range(char)
                        if is_move_cell && !next_cell_black
                            let board = board . s:empty_line_move_dark
                        elseif is_move_cell
                            let board = board . s:empty_line_move_light
                        else
                            let board = board . s:empty_line
                        endif

                        if next_cell_black && (k < char - 1)
                            let board = board . s:start_bcell 
                        elseif (k < char - 1)
                            let board = board . s:start_wcell
                        endif
                        let n += 1
                        let next_cell_black = fmod(i + n, 2) == 0.0
                        let is_move_cell = (i == from_row) && (n == from_column) || (i == to_row) && (n == to_column)
                    endfor
                else
                    if is_move_cell && !next_cell_black
                        let board = board . substitute(s:piece_symbols[char][j], ' ', s:move_cell_dark, 'g')
                    elseif is_move_cell
                        let board = board . substitute(s:piece_symbols[char][j], ' ', s:move_cell_light, 'g')
                    else
                        let board = board . s:piece_symbols[char][j]
                    endif
                    let n += 1
                endif
            endfor

            if fmod(i, 2) == 0.0
                let board = board . s:start_wcell . "\n"
            else
                let board = board . s:start_bcell . "\n"
            endif
        endfor
        let i += 1
    endfor
    let board = board . repeat(s:start_wcell, 9 + s:square_width * 8)

    return board
endfunction


function! lichess#board_setup#display_board(fen, latest_move) abort
    let board = s:create_board(a:fen, a:latest_move)
    call append(0, split(board, '\n'))
endfunction
