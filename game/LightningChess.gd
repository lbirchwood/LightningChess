extends PanelContainer

export var board_path : NodePath
export var white_health_path : NodePath
export var black_health_path : NodePath

export var piece_name_path : NodePath
export var damage_path: NodePath
export var owner_path : NodePath

var board
var moves = null
var pressed = null
var pressed_list = []

var game_id

# Called when the node enters the scene tree for the first time.
func _ready():
    board = get_node(board_path)
    build_board()
    
    for square in board.get_children():
        square.connect("square_pressed", self, "square_pressed")

func square_pressed(x, y, square):
    var did_not_make_move = true
    # Try to make a move:
    if moves != null and pressed != null:
        var move_ary = moves[str(pressed.x) + str(pressed.y)]
        
        if [x, y] in move_ary:
            ServerClientInterface.client_make_move(game_id, [[pressed.x, pressed.y], [x, y]])
            did_not_make_move = false
    
    # Unpress all squares needed
    for pressed_square in pressed_list:
        pressed_square.unpress()
    
    empty_selected()
    
    if did_not_make_move:
        set_selected(square)
        
        pressed = square
        pressed_list = [pressed]
        
        if moves != null:
            var move_ary = moves[str(x) + str(y)]
            
            for move in move_ary:
                for possible_square in board.get_children():
                    if move == [possible_square.x, possible_square.y]:
                        possible_square.possible_move()
                        pressed_list.append(possible_square)

func empty_selected():
    get_node(piece_name_path).set_text("")
    get_node(damage_path).set_text("")
    get_node(owner_path).set_text("")

func set_selected(square):
    get_node(piece_name_path).set_text("Piece Name: " + square.get_name())
    get_node(damage_path).set_text("Damage: " + str(square.damage))
    var owner = square.start_colour
    if square.piece_type == null or square.piece_type == Enums.PIECES.EmptySpace:
        get_node(owner_path).set_text("")
    else:
        if square.piece_type in [Enums.PIECES.WhitePawn,
                                 Enums.PIECES.WhiteRook,
                                 Enums.PIECES.WhiteKnight,
                                 Enums.PIECES.WhiteBishop,
                                 Enums.PIECES.WhiteQueen,
                                 Enums.PIECES.WhiteKing]:
            get_node(owner_path).set_text("Owner: White")
        else:
            get_node(owner_path).set_text("Owner: Black")
    

func update_board(game):
    game_id = game[0]
    var boards = game[2]
    var weights_board = boards["weights_board"]
    var piece_board = boards["piece_board"]
    var white_health = boards["white_health"]
    var black_health = boards["black_health"]
    get_node(white_health_path).set_text("White Health: " + str(white_health))
    get_node(black_health_path).set_text("Black Health: " + str(black_health))
    moves = boards["moves"]
    
    for square in board.get_children():
        var x = square.x
        var y = square.y
        
        square.set_piece(piece_board[x][y], weights_board[x][y])

func build_board():
    var square_scene = preload("res://game/Square.tscn")
    var colour = false
    for i in 8:
        colour = not colour
        for j in 8:
            var square = square_scene.instance()
            square.init(colour, (7 - i), j)
            colour = not colour
            
            board.add_child(square)
