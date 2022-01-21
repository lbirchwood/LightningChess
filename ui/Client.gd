extends Control

const port = 8888
var peer = null

var game_browser = null
var game_scene = null
var currently_loaded = null


# Called when the node enters the scene tree for the first time.
func _ready():
    ServerClientInterface.connect("client_signal_game_list", self, "client_signal_game_list_handler")
    ServerClientInterface.connect("client_signal_join_game", self, "client_signal_join_game_handler")
    ServerClientInterface.connect("client_signal_update_game", self, "client_signal_update_game_handler")
    ServerClientInterface.connect("client_signal_send_created_game", self, "client_signal_send_created_game_handler")
    
    game_browser = load("res://ui/GameBrowser.tscn").instance()
    game_scene = load("res://ui/GameScene.tscn").instance()
    self.add_child(game_browser)
    currently_loaded = Enums.LOADED.game_browser
    
    game_browser.connect("join_game", self, "join_game")
    game_browser.connect("create_game", self, "create_game")
    game_browser.connect("disconnect_from_server", self, "disconnect_from_server")

func client_signal_send_created_game_handler(game):
    change_loaded(Enums.LOADED.game)
    game_scene.update_board(game)

func client_signal_update_game_handler(game):
    game_scene.update_board(game)

func client_signal_join_game_handler(game):
    change_loaded(Enums.LOADED.game)
    game_scene.update_board(game)

func client_signal_game_list_handler(game_list):
    game_browser.update_list(game_list)
   

func change_loaded(load_state):
    remove_loaded(currently_loaded)
    currently_loaded = load_state
    var next_child
    if load_state == Enums.LOADED.game:
        next_child = game_scene
    elif load_state == Enums.LOADED.game_browser:
        next_child = game_browser
    
    self.add_child(next_child)

func remove_loaded(load_state):
    if load_state == Enums.LOADED.game:
        self.remove_child(game_scene)
    elif load_state == Enums.LOADED.game_browser:
        self.remove_child(game_browser)

func init(ip):
    peer = NetworkedMultiplayerENet.new()
    peer.create_client(ip, port)
    return peer

func create_game(game_name):
    ServerClientInterface.client_create_game(game_name)

func join_game():
    var game_id = game_browser.get_selected_game()
    ServerClientInterface.client_join_game(game_id)

func disconnect_from_server():
    print("Trying to disconnect!")
