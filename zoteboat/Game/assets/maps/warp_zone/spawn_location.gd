extends ColorRect

@export var own_group : String = "none"

func _ready() -> void:
	add_to_group(own_group)
	
	visible = Engine.is_editor_hint()
