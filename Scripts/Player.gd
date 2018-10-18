extends KinematicBody2D

export (int) var speed
export (float) var rotation_speed

var health = 1000 setget set_health

var velocity = Vector2()
var rotation_dir = 0

func _process(delta):
	process_input()
	
	rotation += rotation_dir * rotation_speed * delta
	$UI.rotation = -rotation
	
	move_and_slide(velocity)

func process_input():
	velocity = Vector2(speed * (int(Input.is_action_pressed("up")) - int(Input.is_action_pressed("down"))), 0).rotated(rotation)
	rotation_dir = int(Input.is_action_pressed("right")) - int(Input.is_action_pressed("left"))

func _draw():
	draw_line(Vector2(0,0), Vector2(speed, 0).rotated(rotation), Color(1, 0, 0, 0.5), 1)
	# dlaczego nie jest w stanie rysowac dla 'velocity' ? //bo musisz robić update()

func set_health(h):
	health = h
	$UI/Health.text = str(h)
	$UI/Health/Bar.value = h