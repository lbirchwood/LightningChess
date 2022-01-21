extends MarginContainer

export var lightning_chess : NodePath

# Called when the node enters the scene tree for the first time.
func _ready():
    pass # Replace with function body.

func update_board(game):
    get_node(lightning_chess).update_board(game)
