extends RichTextLabel
class_name Name_title

func _ready() -> void:
	Global.Name_text = self
	
	visible_ratio = 0.0

func reveal_text(shown_text: String, time: float = 1.0) -> void:
	visible_ratio = 0.0
	text = shown_text
	
	var tween = create_tween()
	tween.tween_property(self, "visible_ratio", 1.0, time)

func remove_text(time: float = 1.0):
	var tween = create_tween()
	tween.tween_property(self, "visible_ratio", 0.0, time)
