extends MarginContainer

export var list_path : NodePath

signal create_game
signal join_game
signal disconnect_from_server

func emit_create_game(text):
    emit_signal("create_game", text)

func emit_join_game():
    emit_signal("join_game")

func emit_disconnect():
    emit_signal("disconnect_from_server")

func update_list(game_list):
    var list = get_node(list_path)
    list.clear_root()
    
    list.set_column_titles(["ID", "Game Name", "Waiting Player"])
    for game in game_list:
        list.add_row([str(game[0]), game[1], str(game[3])])

func get_selected_game():
    var list = get_node(list_path)
    var game_id = list.get_next_selected(null)
    return game_id
