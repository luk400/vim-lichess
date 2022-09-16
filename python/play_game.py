import berserk
import time
import argparse
from datetime import datetime
from threading import Thread

import util
from server import Server


def seek_game(client, port, *args, **kwargs):
    try:
        util.log_message(
            f"function seek_game: seeking game with args: {args}, kwargs: {kwargs}"
        )
        client.board.seek(*args, **kwargs)
    except Exception as e:
        util.log_message(f"function seek_game: {type(e)}: {str(e)}", 2)
        if "HTTP 429" in str(e):
            msg = "Too many HTTP requests at once, please wait one minute before trying again!"
            util.query_server(f"<set_last_err>{msg}", port)
        else:
            util.query_server(f"<set_last_err>{str(e)}", port)


def game_loop(client, all_games, port):
    util.query_server(f"<set_start_new_game>False/None", port)
    state = None
    game = all_games[0]
    color = game["color"]

    util.query_server(f"<set_color>{color}", port)
    util.query_server(f"<set_fen>{game['fen']}", port)

    game_id = game["gameId"]
    util.query_server(f"<set_game_id>{game_id}", port)
    util.log_message(f"function game_loop: you're {color}! (game id: {game_id})")
    fen, latest_move, last_move = None, None, None

    for state in client.board.stream_game_state(game_id):
        last_game = game
        game = util.get_current_game(client)

        util.log_message(f"state dict: {state} ---- game dict: {game}")

        if game is None:
            game = last_game

        if state["type"] == "gameFull":
            game_info = state
            state = state["state"]

            my_info = game_info[color]
            opp_info = game_info["white" if color == "black" else "black"]
            util.query_server(
                "<set_player_info>"
                + util.MSG_SEP.join(
                    [
                        str(el)
                        for el in [
                            my_info["rating"],
                            opp_info["rating"],
                            my_info["name"],
                            opp_info["name"],
                            my_info["title"],
                            opp_info["title"],
                        ]
                    ]
                ),
                port,
            )
        elif state["type"] == "chatLine":
            continue

        fen = game["fen"]

        curtime = datetime.now().strftime("%Y-%m-%d-%H:%M:%S.%f")
        my_time = state["wtime" if color == "white" else "btime"]
        opp_time = state["wtime" if color == "black" else "btime"]
        if isinstance(my_time, int):
            my_time_seconds = my_time / 1000
            opp_time_seconds = opp_time / 1000
        else:
            my_time_seconds = my_time.second + my_time.minute * 60 + my_time.hour * 3600
            opp_time_seconds = (
                opp_time.second + opp_time.minute * 60 + opp_time.hour * 3600
            )

        latest_move = game["lastMove"]
        util.query_server(
            "<set_all_info>"
            + util.MSG_SEP.join(
                [
                    f"{state['status']}",
                    f"{game['isMyTurn']}",
                    f"{fen}",
                    f"{curtime}/{my_time_seconds}-{opp_time_seconds}",
                    f"{latest_move}",
                ]
            ),
            port,
        )

    util.log_message(
        f"function game_loop: game loop over. last_move={last_move}, latest_move={latest_move}, fen={fen}, last state={state}"
    )

    latest_move = state["moves"].split(" ")[-1] if state is not None else None
    if (
        not any([el is None for el in [fen, latest_move, state]])
        and len(latest_move)
        and state["status"] == "mate"
    ):
        fen = util.change_fen_last_move(fen, latest_move)
        util.log_message(
            f"function game_loop: fen after change: {fen} (latest_move:{latest_move})"
        )
        util.query_server(f"<set_last_fen>{fen}", port)
        util.query_server(f"<set_latest_move>{latest_move}", port)


def wait_until_start_signal(port):
    start_new_game = False
    params = ""
    while not start_new_game:
        response = util.query_server(f"get_start_new_game", port)
        if response is None:
            time.sleep(1)
            util.log_message(
                "function wait_until_start_signal: server not responding ", 2
            )
            continue

        start_new_game, params = response.decode("utf-8").split("/")
        start_new_game = start_new_game == "True"

        if not start_new_game:
            time.sleep(1)

    # params in order:
    # time (integer in minutes)
    # increment (integer in seconds)
    # rated = False
    # variant = "standard"
    # color = "random"
    # rating_range = None (can be passed as [low,high])
    t, inc, rated, variant, color, rating_range = params.split("-")
    t = int(t)
    inc = int(inc)
    rated = rated == "True"
    if rating_range == "None":
        rating_range = None
    else:
        l, h = rating_range.replace("[", "").replace("]", "").split(",")
        rating_range = [int(l), int(h)]

    kwargs = {
        "rated": rated,
        "variant": variant,
        "color": color,
        "rating_range": rating_range,
    }

    return (t, inc), kwargs


def start_server(port, token):
    util.log_message("function start_server: starting lichess session")
    session = berserk.TokenSession(token)
    client = berserk.Client(session)

    try:
        client.account.get()
    except Exception as e:
        util.log_message(
            "function start_server: could not get account! "
            f"possibly invalid api token ({str(e)})",
            3,
        )
        raise e

    server = Server(port, client)

    if not util.is_port_in_use(port):
        server.start()
    else:
        raise Exception("port already in use")

    while True:
        all_games = client.games.get_ongoing()
        seek_params = wait_until_start_signal(port)
        if not len(all_games):
            t2 = Thread(
                target=seek_game,
                args=(client, port, *seek_params[0]),
                kwargs=seek_params[1],
            )
            t2.start()
            all_games = client.games.get_ongoing()
            no_game = True
            while no_game:
                all_games = client.games.get_ongoing()
                no_game = not len(all_games)
                time.sleep(1)
        elif len(all_games) > 1:
            raise Exception("more than one game found!")

        util.log_message("function start_server: game found!")
        game_loop(client, all_games, port)
        util.log_message("function start_server: game ended!")


def parse_cmd_args():
    parser = argparse.ArgumentParser(description="vim-lichess server")
    parser.add_argument("port", type=int, help="port to listen on")
    parser.add_argument("token", type=str, help="lichess api token")
    args = parser.parse_args()
    return args


if __name__ == "__main__":
    args = parse_cmd_args()
    util.log_message(f"starting server on port: {args.port}", 0)
    try:
        start_server(args.port, args.token)
    except Exception as e:
        util.log_message(f"function start_server: {str(e)}", 3)
        if "HTTP 429" in str(e):
            msg = "Too many HTTP requests at once, please wait one minute before trying again!"
            util.query_server(f"<set_last_err>{msg}", args.port)
        else:
            util.query_server(f"<set_last_err>{str(e)}", args.port)

        raise e
