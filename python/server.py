import socket
import json
import re
import berserk
import time
from datetime import datetime
from threading import Thread

import util

HOST = socket.gethostname()


def _parse_make_move_exception(e):
    json_str = re.sub(r'HTTP 400.*?{', '{', str(e)).replace('\'', '"')
    error = json.loads(json_str)["error"]
    return f"<QUERYERROR>{error}".encode()


class Server:
    def __init__(self, port, client):
        self.port = port
        self.client = client
        self.reset_parameters()
        self.username = client.account.get()["username"]
        util.log_message(f"Server started on port {self.port}")
        self._update_dict = {
            "chat": {"freq": 1, "last": time.time()},
        }

    def reset_parameters(self):
        self.start_new_game = False
        self.chat_messages = None
        self.player_times = None
        self.player_info = None
        self.latest_move = None
        self.game_params = None
        self.last_game = None
        self.next_move = None
        self.last_err = None
        self.premove = None
        self.my_turn = None
        self.game_id = None
        self.status = None
        self.color = None
        self.fen = None

    @util.log_func_failure("couldn't start self.handle_client in new thread")
    def start(self):
        t = Thread(target=self.handle_client)
        t.start()

    @util.log_func_failure("socket error occured")
    def handle_client(self):
        exit_ = False
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            s.bind((HOST, self.port))
            while not exit_:
                s.listen()
                conn, _ = s.accept()
                with conn:
                    while True:
                        data = conn.recv(1024)
                        if not data:
                            break

                        data = data.decode("utf-8")

                        if data == "<kill>":
                            util.log_message(f"function handle_client: received kill signal")
                            exit_ = True
                            break

                        response = self.parse_data(data)
                        conn.sendall(response)

                        self.post_response_update(data)

        util.log_message(f"function handle_client: socket closed")

    @util.log_func_failure("could not update attributes")
    def post_response_update(self, data):
        tdiff = time.time() - self._update_dict['chat']['last']
        if data == "get_all_info" and tdiff > self._update_dict['chat']['freq']:
            self._update_dict['chat']['last'] = time.time()
            if self.game_id is not None:
                self._update_chat(self.client, self.game_id)
            else:
                self.chat_messages = None

    @util.log_func_failure("could not parse data")
    def parse_data(self, data):
        response = b"success"

        # new move
        if data.startswith("<set_move>"):
            response = self.make_move(data)
        elif data == "get_move":
            response = f"{self.next_move}".encode()
        # game_id
        elif data.startswith("<set_game_id>"):
            self.game_id = data.replace("<set_game_id>", "")
        elif data == "get_game_id":
            response = f"{self.game_id}".encode()
        # is it my turn?
        elif data.startswith("<set_my_turn>"):
            self.my_turn = data.replace("<set_my_turn>", "") == "True"
        elif data == "get_my_turn":
            response = f"{self.my_turn}".encode()
        # current fen
        elif data.startswith("<set_fen>"):
            response = self.set_fen(data)
        elif data == "get_fen":
            response = f"{self.fen}".encode()
        # latest move
        elif data.startswith("<set_latest_move>"):
            response = self.set_latest_move(data)
        elif data == "get_latest_move":
            response = f"{self.latest_move}".encode()
        # current game status
        elif data.startswith("<set_status>"):
            self.status = data.replace("<set_status>", "")
        elif data == "get_status":
            response = f"{self.status}".encode()
        # what's my color
        elif data.startswith("<set_color>"):
            self.color = data.replace("<set_color>", "")
        elif data == "get_color":
            response = f"{self.color}".encode()
        # player info: <my_rating>-<opp_rating>-<my_name>-<opp_name>-<my_title>-<opp_title>
        elif data.startswith("<set_player_info>"):
            self.player_info = data.replace("<set_player_info>", "")
        elif data == "get_player_info":
            response = f"{self.player_info}".encode()
        # current chat messages
        elif data == "get_chat_messages":
            response = f"{self.chat_messages}".encode()
        # time left of each player
        elif data.startswith("<set_player_times>"):
            self.player_times = data.replace("<set_player_times>", "")
        elif data == "get_player_times":
            response = self.get_player_times()
        # fen of last move in game which can't be obtained using game dict
        elif data.startswith("<set_last_fen>"):
            response = self.process_last_fen(data)
        # write a chat message
        elif data.startswith("<write_message>"):
            response = self.write_chat_message(data)
        # signal that new game should be started
        elif data.startswith("<set_start_new_game>"):
            response = self.handle_start_new_game(data)
        elif data == "get_start_new_game":
            response = f"{self.start_new_game}/{self.game_params}".encode()
        # abort game
        elif data == "abort_game":
            response = self.abort_game()
        # resign game
        elif data == "resign_game":
            response = self.resign_game()
        # claim a victory if opponent left game
        elif data == "claim_victory":
            response = self.claim_victory()
        # make/accept/decline draw offer
        elif data.startswith("<draw_offer>"):
            response = self.draw_offer(data)
        # make/accept/decline takeback offer
        elif data.startswith("<takeback_offer>"):
            response = self.takeback_offer(data)
        # get current game dict
        elif data == "get_game_dict":
            response = self.get_game_dict()
        # occured errors
        elif data.startswith("<set_last_err>"):
            self.last_err = data.replace("<set_last_err>", "")
        # all needed info to display board and player info in vim
        elif data.startswith("<set_all_info>"):
            response = self.parse_all_info(data)
        elif data == "get_all_info":
            response = self.get_all_info()
        # unknown request
        else:
            response = b"<QUERYERROR>unknown request"
            util.log_message(f"function parse_data: unknown request: {data}", 2)

        util.log_message(
            f"function parse_data: new request: {data} - RESPONSE: {response}"
        )

        return response

    @util.log_func_failure(_parse_make_move_exception)
    def make_move(self, data):
        move = data.replace("<set_move>", "")

        try:
            self.client.board.make_move(self.game_id, move=move)
        except Exception as e:
            if "not your turn" in str(e).lower() and not self.my_turn:
                self.premove = move
                return f"<QUERYERROR>premoving {move}".encode()
            else:
                raise e

        return b"success"

    @util.log_func_failure("could not parse all info")
    def parse_all_info(self, data):
        data = data.replace("<set_all_info>", "")
        self.status, my_turn, fen, self.player_times, latest_move = data.split(
            util.MSG_SEP
        )
        self.my_turn = my_turn == "True"
        self.latest_move = latest_move if len(latest_move) > 0 else None

        if self.premove is not None and my_turn:
            self.make_move(f"<set_move>{self.premove}")
            self.premove = None

        return self.set_fen(fen)

    @util.log_func_failure("could not set fen")
    def set_fen(self, data):
        if self.color == 'white':
            self.fen = data.replace("<set_fen>", "")
        elif self.color == 'black':
            self.fen = util.flip_fen(data.replace("<set_fen>", ""))
        else:
            return b"<QUERYERROR>unknown color"

        return b"success"

    @util.log_func_failure("could not set latest move")
    def set_latest_move(self, data):
        move = data.replace("<set_latest_move>", "")
        self.latest_move = move if len(move) > 0 else None
        return b"success"

    @util.log_func_failure("could not process last fen")
    def process_last_fen(self, data):
        self.fen = data.replace("<set_last_fen>", "")
        if self.color == "black":
            self.fen = util.flip_fen(self.fen)

        return b"success"

    @util.log_func_failure("could not write chat message")
    def write_chat_message(self, data):
        msg = data.replace("<write_message>", "")
        if self.game_id is not None:
            self.client.board.post_message(self.game_id, msg)
            return b"success"

        return b"<QUERYERROR>could not write text message"

    @util.log_func_failure("could not get game dict")
    def get_game_dict(self):
        game = util.get_current_game(self.client)
        if game is not None:
            if self.color == "black":
                game["fen"] = util.flip_fen(game["fen"])

            response = f"{game}".encode()
            self.last_game = game
        elif self.last_game is not None:
            response = f"{self.last_game}".encode()
        else:
            response = b"<QUERYERROR>could not get game dict - no game found"

        return response

    @util.log_func_failure("could not get player times")
    def get_player_times(self):
        if self.player_times is not None:
            thentime = datetime.strptime(
                self.player_times.split("/")[0], "%Y-%m-%d-%H:%M:%S.%f"
            )
            td = (datetime.now() - thentime).total_seconds()
            my_time = float(self.player_times.split("/")[1].split("-")[0])
            opp_time = float(self.player_times.split("/")[1].split("-")[1])
            return f"{td}/{my_time}-{opp_time}".encode()

        return f"{self.player_times}".encode()

    @util.log_func_failure("could not get all info")
    def get_all_info(self):
        if self.player_times is not None:
            thentime = datetime.strptime(
                self.player_times.split("/")[0], "%Y-%m-%d-%H:%M:%S.%f"
            )
            td = (datetime.now() - thentime).total_seconds()
            my_time = float(self.player_times.split("/")[1].split("-")[0])
            opp_time = float(self.player_times.split("/")[1].split("-")[1])
            times_parsed = f"{td}/{my_time}-{opp_time}"
        else:
            times_parsed = None

        all_info = {
            "color": self.color,
            "messages": self.chat_messages,
            "player_info": self.player_info,
            "player_times": times_parsed,
            "is_my_turn": self.my_turn,
            "latest_move": self.latest_move,
            "status": self.status,
            "username": self.username,
            "fen": self.fen,
            "msg_sep": util.MSG_SEP,
            "last_err": self.last_err,
            "searching_game": self.start_new_game,
        }

        self.last_err = None

        return f"{all_info}".encode()

    @util.log_func_failure("could not resign game")
    def resign_game(self):
        if self.game_id is not None:
            self.client.board.resign_game(self.game_id)
            return b"success"
        else:
            util.log_message(f"function resign_game: no game id found!", 1)
            return b"<QUERYERROR>could not resign game - no game id found"

    @util.log_func_failure("could not abort game")
    def abort_game(self):
        if self.game_id is not None:
            self.client.board.abort_game(self.game_id)
            return b"success"
        else:
            util.log_message(f"function abort_game: no game id found!", 1)
            return b"<QUERYERROR>could not abort game - no game id found"

    @util.log_func_failure("could not set start new game signal")
    def handle_start_new_game(self, data):
        data = data.replace("<set_start_new_game>", "")
        # parameter order:
        # time (integer in minutes)
        # increment (integer in seconds)
        # rated = False
        # variant = "standard"
        # color = "random"
        # rating_range = None (can be passed as [low, high])
        start_new_game, game_params = data.split("/")
        start_new_game = start_new_game == "True"

        if game_params != "None":
            self.game_params = game_params

        self.start_new_game = start_new_game

        util.log_message(
            "function handle_start_new_game: start_new_game: "
            f"{start_new_game} (parsed: {self.start_new_game}),"
            f" params: {self.game_params}",
            0,
        )

        return b"success"

    @util.log_func_failure("could not claim victory")
    def claim_victory(self):
        path = f"/api/board/game/{self.game_id}/claim-victory"
        response = self.client.board._r.post(
            path, data=None, fmt=berserk.formats.TEXT, stream=False
        )
        response = json.loads(response)

        if "ok" in response.keys():
            util.log_message("function claim_victory: ok", 0)
            return b"success"
        elif "error" in response.keys():
            util.log_message(f"function claim_victory error: {response['error']}", 2)
            return f"<QUERYERROR>{response['error']}".encode()

    @util.log_func_failure("could not handle draw offer")
    def draw_offer(self, data):
        accept = data.replace("<draw_offer>", "")
        path = f"/api/board/game/{self.game_id}/draw/{accept}"
        response = self.client.board._r.post(
            path, data=None, fmt=berserk.formats.TEXT, stream=False
        )
        response = json.loads(response)

        if "ok" in response.keys():
            util.log_message("function draw_offer: ok", 0)
            return b"success"
        elif "error" in response.keys():
            util.log_message(f"function draw_offer error: {response['error']}", 2)
            return f"<QUERYERROR>{response['error']}".encode()

    @util.log_func_failure("could not handle takeback offer")
    def takeback_offer(self, data):
        accept = data.replace("<takeback_offer>", "")
        path = f"/api/board/game/{self.game_id}/takeback/{accept}"
        response = self.client.board._r.post(
            path, data=None, fmt=berserk.formats.TEXT, stream=False
        )
        response = json.loads(response)

        if "ok" in response.keys():
            util.log_message("function takeback_offer: ok", 0)
            return b"success"
        elif "error" in response.keys():
            util.log_message(f"function takeback_offer error: {response['error']}", 2)
            return f"<QUERYERROR>{response['error']}".encode()

    @util.log_func_failure("could not fetch game chat")
    def _update_chat(self, client, game_id):
        path = f"api/board/game/{game_id}/chat"
        response = client.board._r.get(
            path, data=None, fmt=berserk.formats.TEXT, stream=False
        )
        response = json.loads(response)
        chat = util.MSG_SEP.join([f'{msg["user"]}: {msg["text"]}' for msg in response])
        self.chat_messages = chat

    @util.log_func_failure("could not fetch game chat")
    def _update_fen(self, client):
        game = util.get_current_game(client)
        if game is not None:
            self.set_fen(game["fen"])
