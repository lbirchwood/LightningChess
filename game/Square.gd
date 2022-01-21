extends Control

export var square_path : NodePath
export var piece_path : NodePath

signal square_pressed

var square
var piece
var damage

var x 
var y
var start_colour
var rng = RandomNumberGenerator.new()

var piece_type = null

# Called when the node enters the scene tree for the first time.
func _ready():
    rng.randomize()
    square = get_node(square_path)
    piece = get_node(piece_path)
    
    set_colour(start_colour)
    damage = 0

func get_name():
    if piece_type == Enums.PIECES.EmptySpace:
        return "Empty Square"
        
    elif piece_type == Enums.PIECES.BlackPawn:
        return "Pawn"
        
    elif piece_type == Enums.PIECES.BlackRook:
        return "Rook"
        
    elif piece_type == Enums.PIECES.BlackKnight:
        return "Knight"
        
    elif piece_type == Enums.PIECES.BlackBishop:
        return "Bishop"
        
    elif piece_type == Enums.PIECES.BlackKing:
        return "King"
        
    elif piece_type == Enums.PIECES.BlackQueen:
        return "Queen"
        
    elif piece_type == Enums.PIECES.WhitePawn:
        return "Pawn"
        
    elif piece_type == Enums.PIECES.WhiteRook:
        return "Rook"
        
    elif piece_type == Enums.PIECES.WhiteKnight:
        return "Knight"
        
    elif piece_type == Enums.PIECES.WhiteBishop:
        return "Bishop"
        
    elif piece_type == Enums.PIECES.WhiteKing:
        return "King"
        
    elif piece_type == Enums.PIECES.WhiteQueen:
        return "Queen"
    

func set_piece(new_piece, new_damage):
    damage = new_damage
    piece_type = new_piece
    
    if new_piece == Enums.PIECES.EmptySpace:
        piece.set_texture(get_texture_from_imag("res://assets/images/EmptySquare.png"))
        
    elif new_piece == Enums.PIECES.BlackPawn:
        piece.set_texture(get_texture_from_imag("res://assets/images/pieces/BlackPawn.png"))
        
    elif new_piece == Enums.PIECES.BlackRook:
        piece.set_texture(get_texture_from_imag("res://assets/images/pieces/BlackRook.png"))
        
    elif new_piece == Enums.PIECES.BlackKnight:
        piece.set_texture(get_texture_from_imag("res://assets/images/pieces/BlackKnight.png"))
        
    elif new_piece == Enums.PIECES.BlackBishop:
        piece.set_texture(get_texture_from_imag("res://assets/images/pieces/BlackBishop.png"))
        
    elif new_piece == Enums.PIECES.BlackKing:
        piece.set_texture(get_texture_from_imag("res://assets/images/pieces/BlackKing.png"))
        
    elif new_piece == Enums.PIECES.BlackQueen:
        piece.set_texture(get_texture_from_imag("res://assets/images/pieces/BlackQueen.png"))
        
    elif new_piece == Enums.PIECES.WhitePawn:
        piece.set_texture(get_texture_from_imag("res://assets/images/pieces/WhitePawn.png"))
        
    elif new_piece == Enums.PIECES.WhiteRook:
        piece.set_texture(get_texture_from_imag("res://assets/images/pieces/WhiteRook.png"))
        
    elif new_piece == Enums.PIECES.WhiteKnight:
        piece.set_texture(get_texture_from_imag("res://assets/images/pieces/WhiteKnight.png"))
        
    elif new_piece == Enums.PIECES.WhiteBishop:
        piece.set_texture(get_texture_from_imag("res://assets/images/pieces/WhiteBishop.png"))
        
    elif new_piece == Enums.PIECES.WhiteKing:
        piece.set_texture(get_texture_from_imag("res://assets/images/pieces/WhiteKing.png"))
        
    elif new_piece == Enums.PIECES.WhiteQueen:
        piece.set_texture(get_texture_from_imag("res://assets/images/pieces/WhiteQueen.png"))
    
    

func _pressed():
    var imag
    if start_colour:
        imag = "res://assets/images/WhiteSelected.png"
    else:
        imag = "res://assets/images/BlackSelected.png"
    set_square_imag(imag)
    emit_signal("square_pressed", x, y, self)

func possible_move():
    var imag
    if start_colour:
        imag = "res://assets/images/WhitePressed.png"
    else:
        imag = "res://assets/images/BlackPressed.png"
    set_square_imag(imag)

func unpress():
    set_colour(start_colour)

func init(colour, _x, _y):
    x = _x
    y = _y
    start_colour = colour

func get_white_square():
    var random = [
        "res://assets/images/LightningWhite1.png",
        "res://assets/images/LightningWhite2.png",
        "res://assets/images/LightningWhite3.png",
        "res://assets/images/LightningWhite4.png"]
    
    var r = rng.randi_range(0, 15)
    
    if r < 4:
        return random[r]
    
    return "res://assets/images/White.png"

func get_black_square():
    var random = [
        "res://assets/images/LightningBlack1.png",
        "res://assets/images/LightningBlack2.png",
        "res://assets/images/LightningBlack3.png",
        "res://assets/images/Lightning4.png"]
    
    var r = rng.randi_range(0, 15)
    
    if r < 4:
        return random[r]
    
    return "res://assets/images/Black.png"

func set_colour(colour):
    var imag
    if colour:
        imag = get_white_square()
    else:
        imag = get_black_square()
    
    set_square_imag(imag)

func set_square_imag(imag):
    square.set_texture(load(imag))

static func get_texture_from_imag(imag):
    #var texture = ImageTexture.new()
    #var image = Image.new()
    #image.load(imag)
    #texture.create_from_image(image)
    #return texture
    return load(imag)

