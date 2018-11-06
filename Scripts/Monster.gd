extends Area2D

onready var target = get_tree().get_nodes_in_group("player")[0]

const MAX_SPEED = 300
const RADIUS = 32

var velocity = Vector2(0,0)
var is_damaging = -100

func _ready():
	rotation = randf() * PI*2
	
	var theta = randf() * 2*PI
	wander_target = Vector2(WANDER_RADIUS * cos(theta), WANDER_RADIUS * sin(theta))

func _process(delta):
	velocity = (velocity + next_step()).clamped(MAX_SPEED)
	
	position += velocity * delta
	position += declip()
	rotation = velocity.angle()
	
	if is_damaging >= 0:
		is_damaging -= delta
	elif is_damaging > -100:
		is_damaging = 1
		target.health -= 1
	
	update()

func next_step():
	return hide()
	return wander()

func seek(target_position):
	var desired_velocity = (target_position - position).normalized() * MAX_SPEED
	return desired_velocity - velocity

const PANIC_DISTANCE_SQ = pow(300, 2)

func flee(target_position):
	if vec_to_distance_sq(position, target_position) > PANIC_DISTANCE_SQ:
		return Vector2(0,0)
	
	var desired_velocity = (position - target_position).normalized() * MAX_SPEED
	return desired_velocity - velocity

enum Deceleration{SLOW = 3, NORMAL = 2, FAST = 1}
const DECELERATION_TWEAKER = 0.3

func arrive(target_position, deceleration):
	var to_target = target_position - position
	var dist = to_target.length()
	
	if dist > 0:
		var speed = dist / deceleration * DECELERATION_TWEAKER
		speed = clamp(speed, 0, MAX_SPEED)
		
		var desired_velocity = to_target * speed / dist
		return desired_velocity - velocity
	
	return Vector2(0,0)

func pursuit():
	var to_target = target.position - position
	var heading = velocity.normalized()
	var relative_heading = heading.dot(target.velocity.normalized())
	
	if to_target.dot(heading) > 0 and relative_heading < -0.95: return seek(target.position)
	
	var look_ahead_time = to_target.length() / (MAX_SPEED + target.speed)
	return seek(target.position + target.velocity * look_ahead_time)

const MIN_DETECTION_BOX_LENGTH = 200
const BRAKING_WEIGHT = 0.2

func obstacle_avoidance(obstacles):
	var speed = 100 #TODO
	var detection_box_length = MIN_DETECTION_BOX_LENGTH + (speed/MAX_SPEED) * MIN_DETECTION_BOX_LENGTH
	
	var dist_to_closest_ip = INF
	var closest_intersecting_obstacle
	var local_pos_of_closest_obstacle = Vector2()
	
	for obstacle in obstacles:
		if (obstacle.position - position).length_squared() < detection_box_length * detection_box_length:
			var local_pos = (obstacle.position - position).rotated(-rotation)
			
			if local_pos.x >= 0:
				var expanded_radius = obstacle.radius + RADIUS
				
				if abs(local_pos.y) < expanded_radius:
					var cX = local_pos.x
					var cY = local_pos.y
					var sqrt_part = sqrt(expanded_radius*expanded_radius - cY*cY)
					
					var ip = cX - sqrt_part
					if ip <= 0: ip = cX + sqrt_part
					
					if ip < dist_to_closest_ip:
						dist_to_closest_ip = ip
						closest_intersecting_obstacle = obstacle
						local_pos_of_closest_obstacle = local_pos
	
	var steering_force = Vector2()
	if closest_intersecting_obstacle:
		var multiplier = 1.0 + (detection_box_length - local_pos_of_closest_obstacle.x) / detection_box_length
		steering_force.y = (closest_intersecting_obstacle.radius - local_pos_of_closest_obstacle.y) * multiplier
		steering_force.x = (closest_intersecting_obstacle.radius - local_pos_of_closest_obstacle.x) * BRAKING_WEIGHT
		
#		avoided = true #powoduje mniejsze skakanie obrotu, ale tak meh
#	elif !avoided:
#		pass #meh meh
##		return pursuit(target.position)
#	else:
#		avoided = false
	
	return steering_force.rotated(rotation)

func declip():
	for obstacle in get_tree().get_nodes_in_group("obstacles"):
		if (obstacle.position - position).length() < obstacle.radius + RADIUS:
			return -(obstacle.position - position).normalized() * ((obstacle.radius + RADIUS) - (obstacle.position - position).length())
	
	for monster in get_tree().get_nodes_in_group("monsters"):
		if monster != self and (monster.position - position).length() < monster.RADIUS + RADIUS:
			monster.position += (monster.position - position).normalized() * ((monster.RADIUS + RADIUS) - (monster.position - position).length())
			return -(monster.position - position).normalized() * ((monster.RADIUS + RADIUS) - (monster.position - position).length())
	return Vector2()

const WANDER_RADIUS = 16
const WANDER_DISTANCE = 256
const WANDER_JITTER = 16

var wander_target

func wander():
	wander_target = (wander_target + Vector2((-1 + randf()*2) * WANDER_JITTER, (-1 + randf()*2) * WANDER_JITTER)).normalized()
	wander_target *= WANDER_RADIUS
	var target_local = wander_target + Vector2(WANDER_DISTANCE, 0)
	return target_local.rotated(rotation)

const DISTANCE_FROM_BOUNDARY = 100

func get_hiding_position(obstacle):
	var dist_away = obstacle.radius + DISTANCE_FROM_BOUNDARY
	var towards_obstacle = (obstacle.position - target.position).normalized()
	return towards_obstacle * dist_away + obstacle.position

func hide():
	var dist_to_closest = INF
	var best_hiding_spot
	
	for obstacle in get_tree().get_nodes_in_group("obstacles"):
		var hiding_spot = get_hiding_position(obstacle)
		var dist = (hiding_spot - position).length_squared()
		
		if dist < dist_to_closest:
			dist_to_closest = dist
			best_hiding_spot = hiding_spot

	if best_hiding_spot: return arrive(best_hiding_spot, FAST)
	else: return Vector2()#evade()


func _draw():
	if Input.is_key_pressed(KEY_CONTROL):
		draw_set_transform(Vector2(), -rotation, Vector2(1, 1))
		draw_vector(Vector2(0,0), target.position - position, Color(0, 1, 0, 0.3), 5)  # green
#		draw_vector(Vector2(0,0), to_target_heading, Color(0, 0, 1, 0.3), 5)  # blue
		draw_vector(Vector2(0,0), velocity, Color(1, 0, 0, 0.4), 5)  # red

func draw_vector( origin, vector, color, arrow_size ):
	if vector.length_squared() > 1:
		var points = []
		var direction = vector.normalized()
		points.push_back(vector + direction * arrow_size * 2)
		points.push_back(vector + direction.rotated(PI / 2) * arrow_size)
		points.push_back(vector + direction.rotated(-PI / 2) * arrow_size)
		draw_polygon(points, PoolColorArray([color]))
		draw_line(origin, vector, color, arrow_size )

func vec_to_distance_sq(one, two):
	var y_sep = two.y - one.y;
	var x_sep = two.x - one.x;
	return y_sep * y_sep + x_sep * x_sep;

func on_collision(body):
	if body.is_in_group("player"):
		is_damaging = 0

func on_decolission(body):
	if body.is_in_group("player"):
		is_damaging = -100