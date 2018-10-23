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
	max_speed = 130

func _process(delta):
	to_target = target.position - position
	to_target_heading = to_target + target.velocity
	#velocity += seek(target.position)
	#velocity += flee(target.position)
	#velocity += arrive(target.position, 2)
	velocity += pursuit(target.position)
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

func obstacle_avoidance(obstacles): #przy wywolaniu getTree.getNodesingroup(obstacles)

	#the detection box length is proportional to the agent's velocity
	var detection_box_length = min_detection_box_length + (speed/max_speed) * min_detection_box_length
	

	#tag all obstacles within range of the box for processing
#	m_pVehicle->World()->TagObstaclesWithinViewRange(m_pVehicle, detection_box_length)
	
	#this will keep track of the closest intersecting obstacle (CIB)
	var closest_intersecting_obstacle
	
	#this will be used to track the distance to the CIB
	var DistToClosestIP = 999999999999999999999999999999999999999999999.0 # jak w godocie jest maxvalue
	#this will record the transformed local coordinates of the CIB
	var LocalPosOfClosestObstacle = Vector2()
	for obstacle in get_tree().get_nodes_in_group("obstacles"):
		#if the obstacle has been tagged within range proceed
		if (obstacle.global_position - global_position).length_squared() < 600:
			#calculate this obstacle's position in local space
			var LocalPos = Vector2(PointToLocalSpace(obstacle.position, velocity, m_pVehicle->Side(), m_pVehicle->Pos()))
			#if the local position has a negative x value then it must lay behind the agent. (in which case it can be ignored)
			if (LocalPos.x >= 0):
				#if the distance from the x axis to the object's position is less than its radius
				# + half the width of the detection box then there is a potential intersection.
				var ExpandedRadius = obstacle.radius + radius
				if (fabs(LocalPos.y) < ExpandedRadius):
					#now to do a line/circle intersection test. The center of the circle is represented by (cX, cY).
					#The intersection points are given by the formula x = cX +/-sqrt(r^2-cY^2) for y=0.
					#We only need to look at the smallest positive value of x because that will be the closest point of intersection.
					var cX = LocalPos.x
					var cY = LocalPos.y
					#we only need to calculate the sqrt part of the above equation once
					var SqrtPart = sqrt(ExpandedRadius*ExpandedRadius - cY*cY)
					
					var ip = A - SqrtPart
					if (ip <= 0):
						ip = A + SqrtPart
					#test to see if this is the closest so far. If it is, keep a
					#record of the obstacle and its local coordinates
					if (ip < DistToClosestIP):
						DistToClosestIP = ip
						ClosestIntersectingObstacle = obstacle
						LocalPosOfClosestObstacle = LocalPos

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