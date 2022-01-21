extends Control



export var list_path : NodePath


const port = 8888
const max_players = 20
const factor = 2

var players := []
var inactive_games = []
var active_games = []
var id_counter = 0

var list_updater_thread = null
var list_updater_option = Enums.LISTOPTIONS.Players

var PIECES = Enums.PIECES


# Called when the node enters the scene tree for the first time.
func _ready():
    var network = NetworkedMultiplayerENet.new()
    network.create_server(port, max_players)
    get_tree().network_peer = network
    print("Server Started")
    
    network.connect("peer_connected", self, "_peer_connected")
    network.connect("peer_disconnected", self, "_peer_disconnected")

    ServerClientInterface.connect("server_signal_join_game", self, "server_signal_join_game_handler")
    ServerClientInterface.connect("server_signal_create_game", self, "server_signal_create_game_handler")
    ServerClientInterface.connect("server_signal_make_move", self, "server_signal_make_move_handler")
    
    list_updater_thread = Thread.new()
    list_updater_thread.call_deferred("start", self, "_update_game_list")

func server_signal_join_game_handler(player_id, game):
    var counter = 0
    for game in inactive_games:
        if game[0] == int(game[0]):
            break
        counter += 1
    # If there is a game present, then move it to an active game. Will be picked
    # up by the game loop. 
    if counter < len(inactive_games):
        var old_game = inactive_games[counter]
        var new_game = [old_game[0], old_game[1], old_game[2], old_game[3], player_id]
        inactive_games.remove(counter)
        
        active_games.append(new_game)
        ServerClientInterface.server_join_game(player_id, new_game)

func server_signal_create_game_handler(player_id, game_name):
    id_counter += 1
    var new_game = [id_counter, game_name, create_default_game(), player_id]
    
    set_moves(new_game)

    inactive_games.append(new_game)
    self.update_client_game_list()
    ServerClientInterface.server_send_created_game(player_id, new_game)

func server_signal_make_move_handler(game_id, move):
    var game = null
    var counter = 0
    for active_game in active_games:
        if active_game[0] == game_id:
            game = active_game
            break
        counter += 1
    game = make_move(game, move)
    set_moves(game)
    active_games[counter] = game
    var player_1 = game[3]
    var player_2 = game[4]
    
    ServerClientInterface.server_update_game(player_1, game)
    ServerClientInterface.server_update_game(player_2, game)

func update_client_game_list():
    for player in players:
        ServerClientInterface.server_send_game_list_client(player, inactive_games)

func _update_game_list():
    var list = get_node(list_path)
    while(true):
        list.clear_root()

        # Update list based on button presses
        if list_updater_option == Enums.LISTOPTIONS.ActiveGames:
            
            list.set_column_titles(["ID", "Game Name", "Player 1", "Player 2"])
            for game in active_games:
                list.add_row([str(game[0]), game[1], str(game[3]), str(game[4])])

        elif list_updater_option == Enums.LISTOPTIONS.Players:
            list.set_column_titles(["Players"])
            for player in players:
                list.add_row([str(player)])
                
        
        elif list_updater_option == Enums.LISTOPTIONS.InactiveGames:
            
            list.set_column_titles(["ID", "Game Name", "Waiting Player"])
            
            for game in inactive_games:
                list.add_row([str(game[0]), game[1], str(game[3])])

        yield(get_tree().create_timer(0.5), "timeout")

func update_options(option):
    self.list_updater_option = option

func _peer_connected(player_id : int) -> void:
    print("User " + str(player_id) + " connected")
    players.append(player_id)
    ServerClientInterface.server_send_game_list_client(player_id, inactive_games)

func _peer_disconnected(player_id : int) -> void:
    print("User " + str(player_id) + " disconnected")
    var counter = 0
    for player in players:
        if player_id == player:
            break
    if counter != len(players):
        players.remove(counter)

func set_moves(game):
    # Get all of the moves that the player can make. 
    var moves = get_all_moves(game)
    var colour = game[2]["turn"]
    
    # For each move, make the move and see if the opponent can attack the king. 
    for i in 8:
        for j in 8:
            var new_move_ary = moves[str((7-i)) + str(j)].duplicate(true)
            var purge_ary = []
            var counter = 0
            for move in new_move_ary:
                var new_move = [[(7 - i),j], move]
                var new_game = make_move(game, new_move)

                if get_in_check(new_game, colour):
                    print("Purging")
                    purge_ary.append(counter)
                counter += 1
            purge_ary.invert()
            for purge in purge_ary:
                new_move_ary.remove(purge)
            moves[str(7-i) + str(j)] = new_move_ary
    var counter = 0
    for move in moves:
        for second_move in moves[move]:
            counter += 1
    print(counter)
    game[2]["moves"] = moves

func make_move(param_game, move):
    var game = param_game.duplicate(true)
    var from_location = move[0]
    var to_location = move[1]
    var old_x = from_location[0]
    var old_y = from_location[1]
    var new_x = to_location[0]
    var new_y = to_location[1]
    
    var old_board = game[2]
    
    var piece_board = old_board["piece_board"]
    var moved_board = old_board["moved_board"]
    var first_move_board = old_board["first_move"]
    var weights_board = old_board["weights_board"]
    var turn = not old_board["turn"]
    var moves = {}
    var white_health = old_board["white_health"]
    var black_health = old_board["black_health"]
    
    # En passant - If it is a pawn
    if piece_board[old_x][old_y] == PIECES.WhitePawn or piece_board[old_x][old_y] == PIECES.BlackPawn:
        # If pawn move is taking a piece
        if (abs(old_x - new_x) == 1) and (abs(old_y - new_y) == 1):
            if piece_board[new_x][new_y] == PIECES.EmptySpace:
                # Clean up adjacent pawn for en passant
                piece_board[old_x][new_y] = PIECES.EmptySpace
                moved_board[old_x][new_y] = true
                first_move_board[old_x][new_y] = false
                weights_board[old_x][new_y] = 0
    
    # Check for castling
    if piece_board[old_x][old_y] == PIECES.WhiteKing or piece_board[old_x][old_y] == PIECES.BlackKing:
        
        # Short castle
        if old_y - new_y < -1:
            piece_board[old_x][old_y + 1] = piece_board[old_x][old_y + 3]
            moved_board[old_x][old_y + 1] = true
            weights_board[old_x][old_y + 1] = weights_board[old_x][old_y + 3]
            
            # Clean up old rook
            piece_board[old_x][old_y + 3] = PIECES.EmptySpace
            moved_board[old_x][old_y + 3] = true
            weights_board[old_x][old_y + 3] = 0
        # Long Castle    
        if old_y - new_y > 1:
            piece_board[old_x][old_y - 1] = piece_board[old_x][old_y - 4]
            moved_board[old_x][old_y - 1] = true
            weights_board[old_x][old_y - 1] = weights_board[old_x][old_y - 4]
            
            # Clean up old rook
            piece_board[old_x][old_y - 4] = PIECES.EmptySpace
            moved_board[old_x][old_y - 4] = true
            weights_board[old_x][old_y - 4] = 0
        
        
    
    # New values
    piece_board[new_x][new_y] = piece_board[from_location[0]][from_location[1]]
    moved_board[new_x][new_y] = true
    weights_board[new_x][new_y] = factor * weights_board[from_location[0]][from_location[1]]
    
    first_move_board = [
        [false, false, false, false, false, false, false, false],
        [false, false, false, false, false, false, false, false],
        [false, false, false, false, false, false, false, false],
        [false, false, false, false, false, false, false, false],
        [false, false, false, false, false, false, false, false],
        [false, false, false, false, false, false, false, false],
        [false, false, false, false, false, false, false, false],
        [false, false, false, false, false, false, false, false]]
        
    if moved_board[old_x][old_y] == false:
        first_move_board[new_x][new_y] = true
    else:
        first_move_board[new_x][new_y] = false
    
    if not turn:
        white_health = white_health - weights_board[old_x][old_y]
    else:
        black_health = black_health - weights_board[old_x][old_y]
    
    # Clean up old locations on boards
    piece_board[old_x][old_y] = PIECES.EmptySpace
    moved_board[old_x][old_y] = true
    first_move_board[old_x][old_y] = false
    weights_board[old_x][old_y] = 0
    
    game[2] = {"piece_board" : piece_board,
            "moved_board" : moved_board,
            "first_move" : first_move_board, 
            "weights_board" : weights_board,
            "turn" : turn,
            "moves" : generate_empty_moves(),
            "white_health" : white_health,
            "black_health" : black_health}
    return game

func get_in_check(game, colour):
    var piece_board = game[2]["piece_board"]
    var opponent_moves = get_all_moves(game)
    var king
    if colour:
        king = PIECES.WhiteKing
    else:
        king = PIECES.BlackKing
    
    for i in 8:
        for j in 8:
            for move in opponent_moves[str((7-i)) + str(j)]:
                if piece_board[move[0]][move[1]] == king:
                    print("here")
                    return true
    
    return false

func get_all_moves(game):
    var moves = generate_empty_moves()
    
    for i in 8:
        for j in 8:
            moves[str((7-i)) + str(j)] = get_moves(game, (7-i), j)
    
    return moves

func get_moves(game, x, y):
    var boards = game[2]
    var piece_board = boards["piece_board"]
    var piece = piece_board[x][y]
    var colour = get_colour(piece)
    
    # If it is not their turn, they cannot move. 
    if are_enemies(colour, boards["turn"]):
        return []
        
    if piece == PIECES.WhitePawn or piece == PIECES.BlackPawn:
        return get_pawn_moves(game, x, y)
    if piece == PIECES.WhiteRook or piece == PIECES.BlackRook:
        return get_rook_moves(game, x, y)
    if piece == PIECES.WhiteKnight or piece == PIECES.BlackKnight:
        return get_knight_moves(game, x, y)
    if piece == PIECES.WhiteBishop or piece == PIECES.BlackBishop:
        return get_bishop_moves(game, x, y)
    if piece == PIECES.WhiteQueen or piece == PIECES.BlackQueen:
        return get_queen_moves(game, x, y)
    if piece == PIECES.WhiteKing or piece == PIECES.BlackKing:
        return get_king_moves(game, x, y)
        
    return []

func get_queen_moves(game, x, y):
    var return_ary = get_rook_moves(game, x, y)
    return_ary += get_bishop_moves(game, x, y)
    return return_ary

func get_rook_moves(game, x, y):
    var boards = game[2]
    var piece_board = boards["piece_board"]
    var piece = piece_board[x][y]
    var colour = get_colour(piece)
    
    var return_moves = []
    
    var directions = [[1,0],[-1,0],[0,1],[0,-1]]
    
    
    for direction in directions:
        var new_x = x + direction[0]
        var new_y = y + direction[1]
    
        while new_x < 8 and new_x > -1 and new_y < 8 and new_y > -1 and piece_board[new_x][new_y] == PIECES.EmptySpace:
            return_moves.append([new_x, new_y])
            new_x = new_x + direction[0]
            new_y = new_y + direction[1]
                
        if new_x < 8 and new_x > 0 and new_y < 8 and new_y > 0:
            if are_enemies(colour, get_colour(piece_board[new_x][new_y])):
                return_moves.append([new_x, new_y])
    return return_moves

func get_bishop_moves(game, x, y):
    var boards = game[2]
    var piece_board = boards["piece_board"]
    var piece = piece_board[x][y]
    var colour = get_colour(piece)
    
    var return_moves = []
    
    var x_directions = [-1, 1]
    var y_directions = [-1, 1]
    for x_direction in x_directions:
        for y_direction in y_directions:
            var new_x = x + x_direction
            var new_y = y + y_direction
            
            while new_x < 8 and new_x > -1 and new_y < 8 and new_y > -1 and piece_board[new_x][new_y] == PIECES.EmptySpace:
                return_moves.append([new_x, new_y])
                new_x = new_x + x_direction
                new_y = new_y + y_direction
            
            if new_x < 8 and new_x > 0 and new_y < 8 and new_y > 0:
                if are_enemies(colour, get_colour(piece_board[new_x][new_y])):
                    return_moves.append([new_x, new_y])
    return return_moves

func get_knight_moves(game, x, y):
    var boards = game[2]
    var piece_board = boards["piece_board"]
    var piece = piece_board[x][y]
    var colour = get_colour(piece)
    
    var return_moves = [
        [x - 2, y + 1],
        [x - 2, y - 1],
        [x + 2, y + 1],
        [x + 2, y - 1],
        [x + 1, y + 2],
        [x + 1, y - 2],
        [x - 1, y + 2],
        [x - 1, y - 2]]
    
    return purge_friendly_fire(purge_out_of_bounds(return_moves), piece_board, colour)

func get_king_moves(game, x, y):
    var boards = game[2]
    var moved_board = boards["moved_board"]
    var piece_board = boards["piece_board"]
    var piece = piece_board[x][y]
    var colour = get_colour(piece)
    
    var return_moves = []
    for i in 3:
        for j in 3:
            return_moves.append([x + 1 - i,y + 1 - j])
    
    # Castling
    if not moved_board[x][y]:
        
        # Check short castle
        if piece_board[x][y + 1] == PIECES.EmptySpace and piece_board[x][y + 2]:
            var temp_board = game.duplicate(true)
            temp_board = make_move(temp_board, [[x,y], [x,y + 1]])
            if not get_in_check(temp_board, colour):
                temp_board = make_move(temp_board, [[x, y + 1], [x, y + 2]])
                if not get_in_check(temp_board, colour):
                    return_moves.append([x, y + 2])
        # Check long castle
        if piece_board[x][y - 1] == PIECES.EmptySpace and piece_board[x][y - 2] == PIECES.EmptySpace and piece_board[x][y - 3] == PIECES.EmptySpace:
            var temp_board = game.duplicate(true)
            temp_board = make_move(temp_board, [[x,y], [x,y - 1]])
            if not get_in_check(temp_board, colour):
                temp_board = make_move(temp_board, [[x, y + 1], [x, y - 2]])
                if not get_in_check(temp_board, colour):
                    return_moves.append([x, y - 2])
            
    
    return purge_friendly_fire(purge_out_of_bounds(return_moves), piece_board, colour)
    
func get_pawn_moves(pgame, x, y):
    var game = pgame.duplicate()
    var boards = game[2]
    var piece_board = boards["piece_board"]
    var moved_board = boards["moved_board"]
    var first_move = boards["first_move"]
    var piece = piece_board[x][y]
    var has_moved = moved_board[x][y]
    var colour = get_colour(piece)
    var return_moves = []
    
    var direction
    if colour:
        direction = 1
    else:
        direction = -1
    
    if (x + direction) < 8:
        if piece_board[x + direction][y] == PIECES.EmptySpace:
            return_moves.append([x+direction, y])
            
            if not moved_board[x][y]:
                if piece_board[x + direction * 2][y] == PIECES.EmptySpace:
                    return_moves.append([x + direction * 2, y])
        var other_colour
        if (y - 1) >= 0:
            other_colour = get_colour(piece_board[x + direction][y - 1])
            if are_enemies(colour, other_colour):
                return_moves.append([x + direction,y - 1])
        if (y + 1) <= 7:
            other_colour = get_colour(piece_board[x + direction][y + 1])
            if are_enemies(colour, other_colour):
                return_moves.append([x + direction, y + 1])
    
    # En Passant
    if (y - 1) >= 0:
        var adj_piece = piece_board[x][y-1]
        if are_enemies(colour, get_colour(adj_piece)):
            if adj_piece == PIECES.BlackPawn or adj_piece == PIECES.WhitePawn:
                if first_move[x][y-1]:
                    return_moves.append([x+direction,y-1])
    if (y + 1) <= 7:
        var adj_piece = piece_board[x][y+1]
        if are_enemies(colour, get_colour(adj_piece)):
            if adj_piece == PIECES.BlackPawn or adj_piece == PIECES.WhitePawn:
                if first_move[x][y+1]:
                    return_moves.append([x+direction,y+1])
    return return_moves
        
func are_enemies(first_colour, second_colour):
    if first_colour == null or second_colour == null:
        return false
    return not((first_colour and second_colour) or ((not first_colour) and (not second_colour)))

func are_friends(first_colour, second_colour):
    if first_colour == null or second_colour == null:
        return false
    return (first_colour and second_colour) or ((not first_colour) and (not second_colour))

func purge_friendly_fire(return_moves, piece_ary, colour):
    var remove_array = []
    var counter = 0
    for move in return_moves:
        if are_friends(colour, get_colour(piece_ary[move[0]][move[1]])):
            remove_array.append(counter)
        counter += 1
    remove_array.invert()
    for indicies in remove_array:
        return_moves.remove(indicies)
    return return_moves

func purge_out_of_bounds(return_moves):
    var remove_array = []
    var counter = 0
    for move in return_moves:
        if move[0] < 0 or move[0] > 7:
            remove_array.append(counter)
        elif move[1] < 0 or move[1] > 7:
            remove_array.append(counter)
        counter += 1
    remove_array.invert()
    for indicies in remove_array:
        return_moves.remove(indicies)
    
    return return_moves


func get_colour(piece):
    
    if piece == PIECES.EmptySpace:
        return null
    elif piece == Enums.PIECES.WhitePawn:
        return true
        
    elif piece == Enums.PIECES.WhiteRook:
        return true
        
    elif piece == Enums.PIECES.WhiteKnight:
        return true
        
    elif piece == Enums.PIECES.WhiteBishop:
        return true
        
    elif piece == Enums.PIECES.WhiteKing:
        return true
        
    elif piece == Enums.PIECES.WhiteQueen:
        return true
    return false

func create_default_game():
    return create_new_game(1000, 1000, [1,1,1,1,1,1],[1,1,1,1,1,1])

# Creates a new dictionary which stores all information required to play a game. 
# Weights are as follows: Rook, Knight, Bishop, Queen, King, Pawn
func create_new_game(white_health, black_health, white_weights, black_weights):
    var piece_board = [
        [PIECES.WhiteRook, PIECES.WhiteKnight, PIECES.WhiteBishop, PIECES.WhiteQueen, PIECES.WhiteKing, PIECES.WhiteBishop, PIECES.WhiteKnight, PIECES.WhiteRook],
        [PIECES.WhitePawn, PIECES.WhitePawn, PIECES.WhitePawn, PIECES.WhitePawn, PIECES.WhitePawn, PIECES.WhitePawn, PIECES.WhitePawn, PIECES.WhitePawn],
        [PIECES.EmptySpace, PIECES.EmptySpace, PIECES.EmptySpace, PIECES.EmptySpace, PIECES.EmptySpace, PIECES.EmptySpace, PIECES.EmptySpace, PIECES.EmptySpace],
        [PIECES.EmptySpace, PIECES.EmptySpace, PIECES.EmptySpace, PIECES.EmptySpace, PIECES.EmptySpace, PIECES.EmptySpace, PIECES.EmptySpace, PIECES.EmptySpace],
        [PIECES.EmptySpace, PIECES.EmptySpace, PIECES.EmptySpace, PIECES.EmptySpace, PIECES.EmptySpace, PIECES.EmptySpace, PIECES.EmptySpace, PIECES.EmptySpace],
        [PIECES.EmptySpace, PIECES.EmptySpace, PIECES.EmptySpace, PIECES.EmptySpace, PIECES.EmptySpace, PIECES.EmptySpace, PIECES.EmptySpace, PIECES.EmptySpace],
        [PIECES.BlackPawn, PIECES.BlackPawn, PIECES.BlackPawn, PIECES.BlackPawn, PIECES.BlackPawn, PIECES.BlackPawn, PIECES.BlackPawn, PIECES.BlackPawn],
        [PIECES.BlackRook, PIECES.BlackKnight, PIECES.BlackBishop, PIECES.BlackQueen, PIECES.BlackKing, PIECES.BlackBishop, PIECES.BlackKnight, PIECES.BlackRook]
    ]
    # Use for castling
    var moved_board = [
        [false, false, false, false, false, false, false, false],
        [false, false, false, false, false, false, false, false],
        [false, false, false, false, false, false, false, false],
        [false, false, false, false, false, false, false, false],
        [false, false, false, false, false, false, false, false],
        [false, false, false, false, false, false, false, false],
        [false, false, false, false, false, false, false, false],
        [false, false, false, false, false, false, false, false]
       ]
    # Use for en passant
    var first_move = [[false, false, false, false, false, false, false, false],
        [false, false, false, false, false, false, false, false],
        [false, false, false, false, false, false, false, false],
        [false, false, false, false, false, false, false, false],
        [false, false, false, false, false, false, false, false],
        [false, false, false, false, false, false, false, false],
        [false, false, false, false, false, false, false, false],
        [false, false, false, false, false, false, false, false]
       ]
    
    var weights_board = [
        [white_weights[0],white_weights[1],white_weights[2],white_weights[3],white_weights[4],white_weights[2],white_weights[1],white_weights[0]], 
        [white_weights[5],white_weights[5],white_weights[5],white_weights[5],white_weights[5],white_weights[5],white_weights[5],white_weights[5]],
        [0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0],
        [black_weights[5],black_weights[5],black_weights[5],black_weights[5],black_weights[5],black_weights[5],black_weights[5],black_weights[5]],
        [black_weights[0],black_weights[1],black_weights[2],black_weights[4],black_weights[3],black_weights[2],black_weights[1],black_weights[0]]
        ]
    
    # True if white's turn (White Starts)
    var turn = true

    # Return a dictionary of all of the data generated. 
    return {"piece_board" : piece_board, 
            "moved_board" : moved_board,
            "first_move" : first_move, 
            "weights_board" : weights_board,
            "turn" : turn,
            "moves" : generate_empty_moves(),
            "white_health" : white_health,
            "black_health" : black_health}

func generate_empty_moves():
    var return_moves = {}
    for i in 8:
        for j in 8:
            return_moves[str(7 - i) + str(j)] = []
    return return_moves

static func print_piece_board(piece_board):
    var new_ary = piece_board.duplicate(true)
    print(new_ary)
    var PIECES = Enums.PIECES
    for i in 8:
        for j in 8:
            var piece = piece_board[i][j]
            if piece == PIECES.WhitePawn:
                new_ary[i][j] = "WP"
            if piece == PIECES.BlackPawn:
                new_ary[i][j] = "BP"
            if piece == PIECES.WhiteRook:
                new_ary[i][j] = "WR"
            if piece == PIECES.BlackRook:
                new_ary[i][j] = "BR"
            if piece == PIECES.WhiteKnight:
                new_ary[i][j] = "WN"
            if piece == PIECES.BlackKnight:
                new_ary[i][j] = "BN"
            if piece == PIECES.WhiteBishop:
                new_ary[i][j] = "WB"
            if piece == PIECES.BlackBishop:
                new_ary[i][j] = "BB"
            if piece == PIECES.WhiteQueen:
                new_ary[i][j] = "WQ"
            if piece == PIECES.BlackQueen:
                new_ary[i][j] = "BQ"
            if piece == PIECES.WhiteKing:
                new_ary[i][j] = "WK"
            if piece == PIECES.BlackKing:
                new_ary[i][j] = "BK"
            if piece == PIECES.EmptySpace:
                new_ary[i][j] = "  "
    print("------------------------------")
    for row in new_ary:
        var next_row_string = "|"
        for square in row:
            next_row_string += square
            next_row_string += "|"
        print(next_row_string)
        print("------------------------------")
    
    
    
