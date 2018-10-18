extends KinematicBody2D

export (int) var speed
export (float) var rotation_speed
var health = 1000 setget set_health

var screensize          # Size of the game window.

var velocity = Vector2()
var rotation_dir = 0

func _ready():
	 screensize = get_viewport_rect().size

func _process(delta):
	get_input()
	rotation += rotation_dir * rotation_speed * delta
	$UI.rotation = -rotation
	move_and_slide(velocity)

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

func _draw():
	draw_line(Vector2(0,0), Vector2(speed, 0).rotated(rotation), Color(1, 0, 0, 0.5), 1)                       # red
	# dlaczego nie jest w stanie rysowac dla 'velocity' ?

func set_health(h):
	health = h
	$UI/Health.text = str(h)
	$UI/Health/Bar.value = h