import socket
import time
import os
import re

from datetime import datetime


PLUGIN_PATH = os.path.normpath(os.path.split(os.path.realpath(__file__))[0] + os.sep + os.pardir)
HOST = socket.gethostname()
MSG_SEP = "-,-/ß/-,-"


_debug_file = os.path.join(PLUGIN_PATH, ".debug_level")
if not os.path.isfile(_debug_file):
    DEBUG_LEVEL = -1
else:
    try:
        with open(_debug_file, "r") as f:
            DEBUG_LEVEL = int(f.read())
        assert DEBUG_LEVEL in [0, 1, 2, 3], "debug level must be 0, 1, 2 or 3"
    except Exception as e:
        DEBUG_LEVEL = -1


def log_message(message, level=0):
    if level < DEBUG_LEVEL or DEBUG_LEVEL == -1:
        return
    elif level == 0:
        prefix = "[INFO]"
    elif level == 1:
        prefix = "[WARNING]"
    elif level == 2:
        prefix = "[ERROR]"
    elif level == 3:
        prefix = "[CRASH]"
    else:
        raise ValueError("level must be 0, 1, 2 or 3")

    date = datetime.now().strftime("%Y_%m_%d")
    current_time = datetime.now().strftime("%H:%M:%S.%f")

    log_dir = os.path.join(PLUGIN_PATH, "log")
    if not os.path.isdir(log_dir):
        os.mkdir(log_dir)

    with open(os.path.join(log_dir, date + ".log"), "a+") as f:
        f.write(f"{prefix} {current_time}: {message}\n")


def log_func_failure(handle_failure):
    """ decorator which logs occuring errors using the `log_message` function 
    with the function name, the given error_message and the error string """
    
    def log_decorator(func):
        def wrapper(*args, **kwargs):
            try:
                return func(*args, **kwargs)
            except Exception as e:
                if isinstance(handle_failure, str):
                    log_message(f"{func.__name__}: {handle_failure}: {str(e)}", 2)
                    return f"<QUERYERROR>{handle_failure}".encode()
                elif callable(handle_failure):
                    return handle_failure(e)
                else:
                    raise TypeError('Unexpected argument type for `handle_failure`')

        return wrapper

    return log_decorator


def is_port_in_use(port):
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        return s.connect_ex((HOST, port)) == 0


def query_server(query, port, max_tries=5):
    for _ in range(max_tries):
        try:
            with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
                s.connect((HOST, port))
                s.sendall(query.encode())
                response = s.recv(1024)

            return response
        except ConnectionRefusedError as e:
            log_message(f"connection refused (query: {query}): {str(e)}", 2)
            time.sleep(0.03)

    if not is_port_in_use(port):
        raise ConnectionRefusedError(f"port {port} is not in use anymore")


def flip_fen(fen):
    fen_split = fen.split(" ")
    fen_pos, fen_rest = fen_split[0], fen_split[1:]
    pos_flipped = "/".join([el[::-1] for el in fen_pos.split("/")[::-1]])
    return f"{pos_flipped} {' '.join(fen_rest)}"


def get_current_game(client):
    all_games = client.games.get_ongoing()
    if not len(all_games) == 1:
        return None

    return all_games[0]


def fen_to_board(fen):
    rows = fen.split(" ")[0].split("/")
    num = [str(i) for i in range(1, 9)]
    board = [
        list("".join([("0" * int(p) if p in num else p) for p in row])) for row in rows
    ]

    return board


def board_to_fen(board):
    new_fen = []
    for row in board:
        num_before = False
        new_row = ""
        n = 0
        for el in row:
            if el == "0":
                n += 1
                num_before = True
            elif num_before:
                new_row += str(n) + el
                n = 0
                num_before = False
            else:
                new_row += el

        if num_before:
            new_row += str(n)

        new_fen.append(new_row)

    return "/".join(new_fen)


def change_fen_last_move(fen, last_move):
    fen_split = fen.split(" ")
    fen_pos, fen_rest = fen_split[0], fen_split[1:]
    color = fen_rest[0][0]

    m_row = re.match(r"[a-z](\d)[a-z](\d)[a-z]*", last_move)
    m_idx = re.match(r"([a-z])\d([a-z])\d([a-z]*)", last_move)

    assert (
        m_row is not None and m_idx is not None
    ), f"last move could not be parsed! (last_move: {last_move} - type:{type(last_move)})"

    letter_idx_map = {"a": 0, "b": 1, "c": 2, "d": 3, "e": 4, "f": 5, "g": 6, "h": 7}

    row_before_i, row_after_i = m_row.groups()
    row_before_i, row_after_i = 8 - int(row_before_i), 8 - int(row_after_i)
    idx_before_i, idx_after_i, new_piece = m_idx.groups()
    idx_before, idx_after = letter_idx_map[idx_before_i], letter_idx_map[idx_after_i]

    board = fen_to_board(fen)

    if len(new_piece):
        moved_piece = new_piece.upper() if color == "w" else new_piece.lower()
    else:
        moved_piece = board[row_before_i][idx_before]

    board[row_before_i][idx_before] = "0"
    board[row_after_i][idx_after] = moved_piece

    if last_move == "e1g1" or last_move == "e8g8":
        board[row_before_i][-1] = "0"
        board[row_before_i][5] = "R" if color == "w" else "r"
    elif last_move == "e1c1" or last_move == "e8c8":
        board[row_before_i][0] = "0"
        board[row_before_i][3] = "R" if color == "w" else "r"

    fen_pos = board_to_fen(board)
    return f"{fen_pos} {' '.join(fen_rest)}"
