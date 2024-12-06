extends Panel

@export_multiline var text : String
@export var icon : CompressedTexture2D
@export var icon_node : TextureRect

# Called when the node enters the scene tree for the first time.
func _ready():
	$HBoxContainer/RichTextLabel.text = text
	$HBoxContainer/TextureRect.texture = icon

func update_text(mytext):
	$HBoxContainer/RichTextLabel.text = mytext
	
func update_icon(myicon):
	var loadicon = load(myicon)
	$HBoxContainer/TextureRect.texture = loadicon

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
