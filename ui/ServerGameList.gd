extends Tree

var root = self.create_item()

# Called when the node enters the scene tree for the first time.
func _ready():
    self.set_column_titles_visible(true)

func set_column_titles(titles):
    self.columns = len(titles)
    var counter = 0
    for title in titles:
        self.set_column_title(counter, title)
        counter += 1

func add_row(items):
    var row = self.create_item(root)
    var counter = 0
    for row_item in items:
        row.set_text(counter, row_item)
        counter += 1

func clear_root():
    self.clear()
    root = self.create_item()

func get_selected():
    return root.get_selected()
