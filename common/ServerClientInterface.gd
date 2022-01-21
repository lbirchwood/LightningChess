extends Node

signal client_signal_game_list
signal client_signal_join_game
signal client_signal_update_game
signal client_signal_send_created_game

signal server_signal_join_game
signal server_signal_create_game
signal server_signal_make_move


#--------SERVER--------
func server_send_game_list_client(client_id, game_list):
    rpc_id(client_id, "client_receive_send_game_list_client", game_list)

remote func client_receive_send_game_list_client(game_list):
    emit_signal("client_signal_game_list", game_list)

#----
func server_join_game(client_id, game):
    rpc_id(client_id, "client_receive_join_game", game)

remote func client_receive_join_game(game):
    emit_signal("client_signal_join_game", game)

#----
func server_update_game(client_id, game):
    rpc_id(client_id, "client_receive_update_game", game)

remote func client_receive_update_game(game):
    emit_signal("client_signal_update_game", game)

#----
func server_send_created_game(client_id, game):
    rpc_id(client_id, "client_receive_send_created_game", game)

remote func client_receive_send_created_game(game):
    emit_signal("client_signal_send_created_game", game)



#--------CLIENT--------
func client_join_game(game_id):
    rpc_id(1, "server_receive_join_game", game_id)

remote func server_receive_join_game(game_id):
    emit_signal("server_signal_join_game", get_tree().get_rpc_sender_id(), game_id)

#----
func client_create_game(game_name):
    rpc_id(1, "server_receieve_create_game", game_name)

remote func server_receieve_create_game(game_name):
    emit_signal("server_signal_create_game", get_tree().get_rpc_sender_id(), game_name)

#----
func client_make_move(game_id, move):
    rpc_id(1, "server_receive_make_move", game_id, move)

remote func server_receive_make_move(game_id, move):
    emit_signal("server_signal_make_move", game_id, move)
