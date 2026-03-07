extends Node2D

@export var warp_zones: Array[Area2D]

func _ready() -> void:
	warp_zones.shuffle()
	warp_zones[0].correct = true
