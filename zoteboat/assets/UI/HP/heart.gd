extends Control

func set_full(value: bool):
	$Full.visible = value
	$Empty.visible = not value
