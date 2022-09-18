# vim-lichess

Play online chess in (Neo)Vim!

![vimlichessdemo](https://user-images.githubusercontent.com/57172028/190704946-4708be17-83c0-4652-ae3e-9cb958faa557.gif)

### Why?

Because why not. Not having to leave (Neo)Vim to play online chess should be a basic human right.

### Honestly, why?

Honestly, because why not.

## Requirements

* (Neo)Vim with python3 support
* `berserk` package for python3 (install via `pip install berserk`)
* A lichess account
* Tested on python version 3.9.12

## Basic setup and how to play

Install the plugin using e.g. `Plug 'luk400/vim-lichess'` in case you're using vim-plug. 

Open (Neo)Vim and run `:LichessFindGame`. You'll be prompted with instructions on how to create and specify your lichess API token in your vim config if you haven't yet (see first variable in section [Other parameters](#other-parameters)). If you've already set your API Token, a new buffer will open and a new game will be started. 

***You can then play by simply left-clicking on a piece and then right-clicking on its destination square***, or alternatively by typing the move in UCI format ([see this link for examples](https://en.wikipedia.org/wiki/Universal_Chess_Interface#Design)) after using the `LichessMakeMoveUCI` command.

For other actions, such as resigning, offering draws, takebacks, chatting, etc. see section [Commands and mappings](#commands-and-mappings)

When the game is over, you can either start a new game again using `:LichessFindGame` or delete the buffer using e.g. `:bd` and get back to whatever you've been doing before.

## Commands and mappings

#### Commands
* `:LichessFindGame`: Find a new game using [the parameters specified in your vim config](#game-parameters)
* `:LichessResign`: Resign a game
* `:LichessAbort`: Abort a game
* `:LichessClaimVictory`: Claim victory if opponent has abandoned the game (unfortunately there's no way to determine whether a game is "claimable" through lichess API, thus you'll just have to try by running the command when you think the opponent might've abandoned the game)
* `:LichessDrawOfferAccept`: Create or accept a draw offer
* `:LichessDrawDecline`: Decline a draw offer
* `:LichessTakebackOfferAccept`: Create or accept a takeback offer
* `:LichessTakebackOfferDecline`: Decline a takeback offer
* `:LichessMakeMoveUCI`: type a move to make in UCI format ([see this link for examples](https://en.wikipedia.org/wiki/Universal_Chess_Interface#Design))
* `:LichessChat`: write a message in chat (note that your messages won't register if you're shadowbanned)

#### Mappings
```vim
nnoremap <buffer> <leader>lm :LichessMakeMoveUCI<cr>
nnoremap <buffer> <leader>lc :LichessChat 
nnoremap <buffer> <leader>la :LichessAbort<cr>
nnoremap <buffer> <leader>lr :LichessResign<cr>
nnoremap <buffer> <leader>ldo :LichessOfferDraw<cr>
nnoremap <buffer> <leader>lda :LichessAcceptDraw<cr>
nnoremap <buffer> <leader>ldd :LichessDeclineDraw<cr>
nnoremap <leader>ch :call lichess#play#find_game()<cr>
```

## Global variables

#### Game parameters
```vim
let g:lichess_autoqueen = 1
" whether to automatically promote to queen or not
let g:lichess_time = 10
" game time in minutes - must be >= 8, since lichess API only allows rapid or classical games
let g:lichess_increment = 0
" increment in seconds
let g:lichess_rated = 1
" whether to play rated games (1) or unrated games (0)
let g:lichess_variant = "standard"
" lichess variant to play -> this plugin has currently only been tested with 'standard'! possible values: ['standard', 'chess960', 'crazyhouse', 'antichess', 'atomic', 'horde', 'kingOfTheHill', 'racingKings', 'threeCheck']
let g:lichess_color = "random"
" which color you want to play as. possible values: ['white', 'black', 'random']
let g:lichess_rating_range = []
" rating range of your opponents, can be an empty list to use the default (recommended) or a list like `[low,high]`, where `low` and `high` are integers.
```

#### Other parameters
```vim
let g:lichess_api_token = ''
" your required lichess API token. you can easily easily create one which you can put in your config using this link: https://lichess.org/account/oauth/token/create?scopes[]=challenge:write&scopes[]=board:play&description=vim+lichess
let g:python_cmd = 'python3'
" python command to run server in background - this should be the python executable for which berserk is installed (can also be a full path)
let g:lichess_debug_level = -1
" set debugging level. -1 means nothing is logged and no log files are created, 0 -> all info is logged, 1 -> only warnings and 'worse' are logged, 2 -> only errors and 'worse' are logged, 3 -> only crashes are logged
```

#### Highlighting

In case you want change the board colors or other highlighting options, you can modify any of the following highlights and put them in your vim config (AFTER  the plugin is loaded - e.g. after `call plug#end()` in case you're using vim-plug) to overwrite them:

```vim
highlight lichess_black_squares guibg=#B58863 ctermbg=94
" highlighting of black squares
highlight lichess_white_squares guibg=#F0D9B5 ctermbg=7
" highlighting of white squares
highlight lichess_black_pieces guifg=#000000 guibg=#000000 ctermbg=0 ctermfg=0
" highlighting of black pieces
highlight lichess_white_pieces guifg=#ffffff guibg=#ffffff ctermbg=15 ctermfg=15
" highlighting of white pieces
highlight lichess_from_square_dark guifg=#AAA23A guibg=#AAA23A ctermbg=172 ctermfg=172
" highlighting of the previous and new square of the latest moved piece if it's a dark square
highlight lichess_from_square_light guifg=#CDD26A guibg=#CDD26A ctermbg=178 ctermfg=178
" highlighting of the previous and new square of the latest moved piece if it's a light square
highlight lichess_cell_delimiters guifg=#000000 guibg=#000000 ctermbg=0 ctermfg=0
" highlighting of vertical cell delimiters between squares
highlight lichess_user_turn guibg=#3eed6c guifg=#000000 ctermbg=2 ctermfg=0 cterm=bold gui=bold
" highlighting of the name of the user whose turn it currently is
highlight lichess_user_noturn guifg=#ffffff ctermfg=15 cterm=bold gui=bold
" highlighting of the name of the user whose turn it's currently not
highlight lichess_searching_game guifg=#42d7f5 guibg=#000000 ctermfg=14 ctermbg=0 cterm=bold gui=bold
" highlighting of 'searching game...' prompt
highlight lichess_game_ended guibg=#e63c30 guifg=#ffffff ctermbg=1 ctermfg=15 cterm=bold gui=bold
" highlighting of last game status (e.g. 'MATE' or 'RESIGN')
highlight lichess_chat guibg=#e3f27e guifg=#000000 ctermbg=191 ctermfg=0
" highlighting of of opponent chat messages
highlight lichess_chat_system guibg=#ed8787 guifg=#000000 ctermbg=178 ctermfg=0
" highlighting of of lichess chat messages
highlight lichess_chat_you guibg=#b4e364 guifg=#000000 ctermbg=190 ctermfg=0
" highlighting of your chat messages
highlight lichess_chat_bold guibg=#e3f27e guifg=#000000 ctermbg=191 ctermfg=0 cterm=bold gui=bold
" highlighting of of 'CHAT:' prompt
highlight lichess_move_info guibg=#9ea832 guifg=#000000 ctermbg=3 ctermfg=0 cterm=bold gui=bold
" echohl highlighting of echoed move-message
highlight lichess_too_many_requests guibg=#c20202 guifg=#ffffff ctermbg=15 ctermfg=9 cterm=bold gui=bold
" echohl highlighting of too_many_requests error
```

#### Piece representation

In case you don't like my piece design, you can design your own as shown below.
You can also change their width/height (number of characters in strings/number of strings in list) to make them bigger if you want more detail, as long as you follow the following restrictions:
* all pieces must have the same height (number of strings in piece list)
* all pieces must have the same width (number of characters in the strings)
* there must be exactly one unique non-whitespace character for all black and one unique non-whitespace character for all white pieces. This can not be the same for the white and black pieces and it must have a length of 1 (there are certain characters which have a different length in vim - e.g.: `echo len('║')` will print `3` even though it's a single character)


```vim
" black pieces
let g:lichess_piece_p =
    \   ["            ",
    \    "     ,,     ",
    \    "    ,,,,    ",
    \    "    ,,,,    ",
    \    "    ,,,,    ",
    \    "            "] " black pawn
let g:lichess_piece_r =
    \   ["            ",
    \    "   , ,, ,   ",
    \    "   ,,,,,,   ",
    \    "   ,,,,,,   ",
    \    "  ,,,,,,,,  ",
    \    "            "] " black rook
let g:lichess_piece_k =
    \   ["            ",
    \    "     ,,     ",
    \    "  ,,,,,,,,  ",
    \    "     ,,     ",
    \    "     ,,     ",
    \    "            "] " black king
let g:lichess_piece_q =
    \   ["            ",
    \    "   , ,, ,   ",
    \    "    ,,,,    ",
    \    "     ,,     ",
    \    "   ,,,,,,   ",
    \    "            "] " black queen
let g:lichess_piece_b =
    \   ["            ",
    \    "    ,,,,    ",
    \    "    ,,,,    ",
    \    "     ,,     ",
    \    "   ,,,,,,   ",
    \    "            "] " black bishop
let g:lichess_piece_n =
    \   ["            ",
    \    "    ,,,     ",
    \    "  ,,, ,,    ",
    \    "     ,,,    ",
    \    "   ,,,,,,   ",
    \    "            "] " black knight

" white pieces
let g:lichess_piece_P =
    \   ["            ",
    \    "     ;;     ",
    \    "    ;;;;    ",
    \    "    ;;;;    ",
    \    "    ;;;;    ",
    \    "            "] " white pawn
let g:lichess_piece_R =
    \   ["            ",
    \    "   ; ;; ;   ",
    \    "   ;;;;;;   ",
    \    "   ;;;;;;   ",
    \    "  ;;;;;;;;  ",
    \    "            "] " white rook
let g:lichess_piece_K =
    \   ["            ",
    \    "     ;;     ",
    \    "  ;;;;;;;;  ",
    \    "     ;;     ",
    \    "     ;;     ",
    \    "            "] " white king
let g:lichess_piece_Q =
    \   ["            ",
    \    "   ; ;; ;   ",
    \    "    ;;;;    ",
    \    "     ;;     ",
    \    "   ;;;;;;   ",
    \    "            "] " white queen
let g:lichess_piece_B =
    \   ["            ",
    \    "    ;;;;    ",
    \    "    ;;;;    ",
    \    "     ;;     ",
    \    "   ;;;;;;   ",
    \    "            "] " white bishop
let g:lichess_piece_N =
    \   ["            ",
    \    "    ;;;     ",
    \    "  ;;; ;;    ",
    \    "     ;;;    ",
    \    "   ;;;;;;   ",
    \    "            "] " white knight
```

# Credit

All credit goes to my huge procrastination issues
