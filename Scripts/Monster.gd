extends Area2D

onready var target = get_tree().get_nodes_in_group("player")[0]

var max_speed
var speed
var velocity = Vector2(0,0) # current velocity, works as 'self heading' for now too
var desired_velocity
var to_target = Vector2(0,0)
var to_target_heading = Vector2(0,0)
var is_damaging = -100
const radius = 32 # 

func _ready():
	speed = 0
	max_speed = 130
	rotation = randf() * PI*2
	
	var theta = randf() * 2*PI
	wander_target = Vector2(WANDER_RADIUS * cos(theta), WANDER_RADIUS * sin(theta))

func _process(delta):
	to_target = target.position - position
	to_target_heading = to_target + target.velocity
	#velocity += seek(target.position)
	#velocity += flee(target.position)
	#velocity += arrive(target.position, 2)
	velocity = (velocity + wander()).clamped(max_speed)
	velocity += pursuit(target.position)
	velocity += obstacle_avoidance(get_tree().get_nodes_in_group("obstacles"))
	position += declip()
	speed = velocity.length()
	position += velocity * delta
	#rotation = velocity.angle()
	rotation = velocity.angle()
	
	if is_damaging >= 0:
		is_damaging -= delta
	elif is_damaging > -100:
		is_damaging = 1
		target.health -= 1
	
	update()

func seek(target_position):
	desired_velocity = (target_position - position).normalized() * max_speed
	return desired_velocity - velocity

func flee(target_position): 
	var panic_distance_sq = 300.0 * 300.0;
	if vec_to_distance_sq(self.position, target_position) > panic_distance_sq:
		return Vector2(0,0)
	
	desired_velocity = (position - target_position).normalized() * max_speed
	
	return desired_velocity - velocity

func arrive(target_position, deceleration):
	var dist = to_target.length()
	if dist > 0:
		var deceleration_tweaker = 0.3
		var speed = dist / deceleration * deceleration_tweaker
		
		speed = clamp(speed, 0, max_speed)
		desired_velocity = to_target * speed / dist
		
		return desired_velocity - velocity
	return Vector2(0,0)

func pursuit(target_position):
	var relative_heading = velocity.dot(target.velocity)
	
	if to_target.dot(velocity) > 0 and relative_heading < -0.95: return seek(target_position)
	
	var look_ahead_time = to_target.length() / (max_speed + target.speed)
	return seek(target_position + target.velocity * look_ahead_time)

const MIN_DETECTION_BOX_LENGTH = 200
const BRAKING_WEIGHT = 0.2

#var avoided

func obstacle_avoidance(obstacles):
	var detection_box_length = MIN_DETECTION_BOX_LENGTH + (speed/max_speed) * MIN_DETECTION_BOX_LENGTH
	
	var dist_to_closest_ip = INF
	var closest_intersecting_obstacle
	var local_pos_of_closest_obstacle = Vector2()
	
	for obstacle in obstacles:
		if (obstacle.global_position - global_position).length_squared() < detection_box_length * detection_box_length:
			var local_pos = (obstacle.global_position - global_position).rotated(-rotation)
			
			if local_pos.x >= 0:
				var expanded_radius = obstacle.radius + radius
				
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
	var pos = position# + velocity
	for obstacle in get_tree().get_nodes_in_group("obstacles"):
		if (obstacle.position - pos).length() < obstacle.radius + radius:
			return -(obstacle.position - pos).normalized() * ((obstacle.position - pos).length() - obstacle.radius - radius/2)
	for obstacle in get_tree().get_nodes_in_group("monsters"):
		if (obstacle.position - pos).length() < obstacle.radius + radius:
			return -(obstacle.position - pos).normalized() * ((obstacle.position - pos).length() - obstacle.radius - radius/2)
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

const DISTANCE_FROM_BOUNDARY = 30

func get_hiding_position(obstacle, target):
	var dist_away = obstacle.radius + DISTANCE_FROM_BOUNDARY
	var towards_obstacle = (obstacle.global_position - target.global_position).normalized()
	return towards_obstacle * dist_away * obstacle.global_position

func _draw():
	if Input.is_key_pressed(KEY_CONTROL):
		draw_set_transform(Vector2(), -rotation, Vector2(1, 1))
		draw_vector(Vector2(0,0), to_target_heading, Color(0, 0, 1, 0.3), 5)  # blue
		draw_vector(Vector2(0,0), to_target, Color(0, 1, 0, 0.3), 5)  # green
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