extends Button

export var game_browser : NodePath

func _pressed():
    get_node(game_browser).emit_create_game(self.text)
