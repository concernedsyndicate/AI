extends KinematicBody2D

export (int) var speed = 400
export (float) var rotation_speed = 1.5

var screensize          # Size of the game window.

var velocity = Vector2()
var rotation_dir = 0
var heading = Vector2()

func _ready():
	 screensize = get_viewport_rect().size

func get_input():
	rotation_dir = 0
	velocity = Vector2()
	if Input.is_action_pressed("ui_right"):
		rotation_dir += 1
	if Input.is_action_pressed("ui_left"):
		rotation_dir -= 1
	if Input.is_action_pressed("ui_down"):
		velocity = Vector2(-speed, 0).rotated(rotation)
	if Input.is_action_pressed("ui_up"):
		velocity = Vector2(speed, 0).rotated(rotation)

func _process(delta):
	get_input()
	rotation += rotation_dir * rotation_speed * delta
	move_and_slide(velocity)

func _draw():
	draw_line(Vector2(0,0), heading, Color(255, 0, 0), 1)                       # red