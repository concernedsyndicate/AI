tool
extends Node2D

var map_bounds = Rect2(0, 0, 1200, 1200)

func _ready():
	var camera = $"../Player/Camera2D"
	
	camera.limit_top = map_bounds.position.y
	camera.limit_left = map_bounds.position.x
	camera.limit_bottom = map_bounds.position.y + map_bounds.size.y
	camera.limit_right = map_bounds.position.x + map_bounds.size.x

func _draw():
	if Engine.editor_hint: draw_rect(map_bounds, Color.blue, false)