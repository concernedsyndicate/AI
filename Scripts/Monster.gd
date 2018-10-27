extends Area2D

onready var target = get_tree().get_nodes_in_group("player")[0]

var max_speed
var speed
var velocity = Vector2(0,0) # current velocity, works as 'self heading' for now too
var desired_velocity
var to_target = Vector2(0,0)
var to_target_heading = Vector2(0,0)
var is_damaging = -100
var min_detection_box_length = 400
var radius = 32 # 

func _ready():
	speed = 0
	max_speed = 130

func _process(delta):
	to_target = target.position - position
	to_target_heading = to_target + target.velocity
	#velocity += seek(target.position)
	#velocity += flee(target.position)
	#velocity += arrive(target.position, 2)
	#velocity += pursuit(target.position)
	velocity += obstacle_avoidance(get_tree().get_nodes_in_group("obstacles"))
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

func obstacle_avoidance(obstacles): #przy wywolaniu get_tree().get_nodes_in_group("obstacles")

	#length ~ velocity, min = 400
	var detection_box_length = min_detection_box_length + (speed/max_speed) * min_detection_box_length
	

	#tag all obstacles within range of the box for processing - 
#	m_pVehicle->World()->TagObstaclesWithinViewRange(m_pVehicle, detection_box_length)
	
	#for keeping track of the closest intersecting obstacle (CIB)
	var closest_intersecting_obstacle
	
	#for tracking the distance to CIB
	var dist_to_closest_ip = 99999999999999999999999999999999999999.0 # jak w godocie jest maxvalue?
	
	#for recording transformed local coordinates of the CIB
	var local_pos_of_closest_obstacle = Vector2()
	
	for obstacle in obstacles:
		#proceed if obstacle tagged within range
		if (obstacle.global_position - global_position).length_squared() < detection_box_length:
			#calculate this obstacle's position in local space
			#var LocalPos = Vector2(PointToLocalSpace(obstacle.position, velocity, m_pVehicle->Side(), m_pVehicle->Pos()))
			#po co tej funkcji z ksiazki bylo side i vel?
			var local_pos = obstacle.global_position - global_position
			#if local_pos has a negative x value then it lays behind agent (and can be ignored)
			if (local_pos.x >= 0):
				#potential intersection if dist. from x axis to obj_pos < its radius + half width of detection box
				var expanded_radius = obstacle.radius + radius
				if (abs(local_pos.y) < expanded_radius):
					#Line/circle intersection test. Center of circle = (cX, cY).
					#intersection points given by the formula x = cX +/-sqrt(r^2-cY^2) for y=0.
					#only need to look at the smallest positive value of x bec that will be the closest point of intersection.
					var cX = local_pos.x
					var cY = local_pos.y
					#only need to calculate the sqrt part of the above equation once
					var sqrt_part = sqrt(expanded_radius*expanded_radius - cY*cY)
					
					var ip = cX - sqrt_part
					if (ip <= 0):
						ip = cX + sqrt_part
					#test to see if this is the closest so far. If it is, keep a
					#record of the obstacle and its local coordinates
					if (ip < dist_to_closest_ip):
						dist_to_closest_ip = ip
						closest_intersecting_obstacle = obstacle
						local_pos_of_closest_obstacle = local_pos
						
	#if intersecting obstacle found, calculate a steering force away from it
	var steering_force = Vector2()
	if(closest_intersecting_obstacle):
		#the closer the agent is to an object, the stronger the steering force should be
		var multiplier = 1.0 + (detection_box_length - local_pos_of_closest_obstacle.x) / detection_box_length
		#calculate the lateral force
		
		steering_force.y = (closest_intersecting_obstacle.radius - local_pos_of_closest_obstacle.y) * multiplier
		#apply a braking force ~ to obstacle’s distance from the vehicle
		
		var braking_weight = 0.2
		steering_force.x = (closest_intersecting_obstacle.radius - local_pos_of_closest_obstacle.x) * braking_weight
	else:
		return pursuit(target.position)
	#finally, convert the steering vector from local to world space
#	return VectorToWorldSpace(SteeringForce, m_pVehicle->Heading(), m_pVehicle->Side())
	return steering_force + global_position

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