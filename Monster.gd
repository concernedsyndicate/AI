extends Area2D

var target
var maxSpeed
var velocity = Vector2(0,0) # current velocity
var desiredVelocity
var toTarget = Vector2(0,0)

func _ready():
	set_process(true)
	target = get_tree().get_root().get_node("Node2D/Player")
	maxSpeed = 150
	pass

func _process(delta):
	update()
	toTarget = target.position-self.position
	#velocity += seek(target.position)
	#velocity += flee(target.position)
	velocity += arrive(target.position, 2)
	position += velocity * delta
	

func seek(tPosition):
	#desiredVelocity = Vector2(tPosition - self.position).normalized() * maxSpeed
	desiredVelocity = toTarget.normalized() * maxSpeed
	
	return (desiredVelocity - velocity)

func flee(tPosition): 
	# only flee if the target is within 'panic distance'. Work in distance
	# squared space.
	var PanicDistanceSq = 300.0 * 300.0;
	if (Vec2DistanceSq(self.position, tPosition) > PanicDistanceSq):
		return Vector2(0,0)
	
	desiredVelocity = Vector2(self.position - tPosition).normalized() * maxSpeed
	
	return (desiredVelocity - velocity)

func arrive(tPosition, deceleration):
	#calculate the distance to the target position
	var dist = toTarget.length()
	if (dist > 0):
		#because Deceleration is enumerated as an int, this value is required
		#to provide fine tweaking of the deceleration.
		var decelerationTweaker = 0.3
		#calculate the speed required to reach the target given the desired deceleration
		var speed = dist / (deceleration * decelerationTweaker)
		#make sure the velocity does not exceed the max
		speed = clamp(speed, 0, maxSpeed)
		#from here proceed just like Seek except we don't need to normalize the toTarget vector
		#because we have already gone to the trouble of calculating its length: dist.
		desiredVelocity = toTarget * speed / dist
		return (desiredVelocity - velocity)
	return Vector2(0,0)

func _draw():
	draw_line(Vector2(0,0), Vector2(velocity), Color(255, 0, 0), 1)                      # red
	draw_line(Vector2(0,0), Vector2(target.position-self.position), Color(0, 255, 0), 1) # green
	
func Vec2DistanceSq(one, two):
	var ySep = two.y - one.y;
	var xSep = two.x - one.x;
	return ySep * ySep + xSep * xSep;
