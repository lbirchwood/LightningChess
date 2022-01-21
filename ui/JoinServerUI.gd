extends TextureButton

var client
# Called when the node enters the scene tree for the first time.
func _ready():
    pass # Replace with function body.

func _pressed():
    client = load("res://ui/Client.tscn").instance()
    var ip = get_node("../VBoxContainer/Input").text
    
    
    
    var peer = client.init(ip)
    get_tree().network_peer = peer
    get_tree().connect("connected_to_server", self, "connection_established")
    get_tree().connect("connection_failed", self, "connection_failed")


func connection_failed():
    print("Connection Failed")
    get_node("../Label").set_text("Cannot connect to server")


func connection_established():
    print("Connection Established")
    var root = get_tree().get_root()
    root.add_child(client)
    
    var old_scene = root.get_node("JoinServer")
    root.remove_child(old_scene)
    
    old_scene.call_deferred("free")
