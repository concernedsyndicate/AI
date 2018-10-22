extends KinematicBody2D

onready var ray = $Railcast

const RAIL_COOLDOWN = 1.5

export (int) var speed
export (float) var rotation_speed

var health = 100 setget set_health
var cooldown = 0

var velocity = Vector2()
var rotation_dir = 0

func _process(delta):
	process_move(delta)
	process_attack(delta)
	$UI.rotation = -rotation

func process_move(delta):
	velocity = Vector2(speed * (int(Input.is_action_pressed("up")) - int(Input.is_action_pressed("down"))), 0).rotated(rotation)
	rotation_dir = int(Input.is_action_pressed("right")) - int(Input.is_action_pressed("left"))
	
	rotation += rotation_dir * rotation_speed * delta
	
	move_and_slide(velocity)

func process_attack(delta):
	cooldown -= delta
	$Sprite.modulate.b = 1 - clamp(cooldown, 0, RAIL_COOLDOWN) / RAIL_COOLDOWN
	
	if Input.is_action_just_pressed("shoot") and cooldown <= 0:
		cooldown = RAIL_COOLDOWN
		
		var bullet = preload("res://Nodes/RailgunBullet.tscn").instance()
		get_parent().add_child(bullet)
		bullet.position = position
		bullet.rotation = rotation
		
		if ray.is_colliding():
			if ray.get_collider().is_in_group("monsters"): ray.get_collider().queue_free()
			bullet.line.points[1].x = (global_position - ray.get_collision_point()).length()

func _draw():
	draw_line(Vector2(0,0), Vector2(speed, 0).rotated(rotation), Color(0, 0.5, 1, 0.4), 5)
	# dlaczego nie jest w stanie rysowac dla 'velocity' ? //bo musisz robić update() //dzięki, teraz tylko wykminić dlaczego źle rysuje wtedy

func set_health(h):
	health = h
	$UI/Health.text = str(h)
	$UI/Health/Bar.value = h