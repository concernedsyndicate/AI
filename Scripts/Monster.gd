extends Area2D

onready var target = get_tree().get_nodes_in_group("player")[0]

var max_speed
var velocity = Vector2(0,0) # current velocity, works as 'self heading' for now too
var desired_velocity
var to_target = Vector2(0,0)
var to_target_heading = Vector2(0,0)
var is_damaging = -100

func _ready():
	max_speed = 130

func _process(delta):
	to_target = target.position - position
	to_target_heading = to_target + target.velocity
	#velocity += seek(target.position)
	#velocity += flee(target.position)
	#velocity += arrive(target.position, 2)
	velocity += pursuit(target.position)
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
	# only flee if the target is within 'panic distance'. Work in distance
	# squared space.
	var panic_distance_sq = 300.0 * 300.0;
	if vec_to_distance_sq(self.position, target_position) > panic_distance_sq:
		return Vector2(0,0)
	
	desired_velocity = (position - target_position).normalized() * max_speed
	
	return desired_velocity - velocity

func arrive(target_position, deceleration):
	var dist = to_target.length()
	if dist > 0:
		#because Deceleration is enumerated as an int, this value is required
		#to provide fine tweaking of the deceleration.
		var deceleration_tweaker = 0.3
		#calculate the speed required to reach the target given the desired deceleration
		var speed = dist / deceleration * deceleration_tweaker
		#make sure the velocity does not exceed the max
		speed = clamp(speed, 0, max_speed)
		#from here proceed just like Seek except we don't need to normalize the to_target vector
		#because we have already gone to the trouble of calculating its length: dist.
		desired_velocity = to_target * speed / dist
		return desired_velocity - velocity
	return Vector2(0,0)

func pursuit(target_position):
#if the evader is ahead and facing the agent then we can just seek for the evader's current position.
	var relative_heading = velocity.dot(target.velocity)
	if to_target.dot(velocity) > 0 and relative_heading < -0.95: #acos(0.95)=18 degs
		return seek(target_position)
	#Not considered ahead so we predict where the evader will be.
	#the look-ahead time is proportional to the distance between the evader
	#and the pursuer; and is inversely proportional to the sum of the
	#agents' velocities
	var look_ahead_time = to_target.length() / (max_speed + target.speed)
	#now seek to the predicted future position of the evader
	return seek(target_position + target.velocity * look_ahead_time)

func _draw():
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