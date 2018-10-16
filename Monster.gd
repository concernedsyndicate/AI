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
	#rotation = velocity.angle()
	$Sprite.rotation = velocity.angle() -36 # oszukanko xD
	

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
	
	desiredVelocity = (position - tPosition).normalized() * maxSpeed
	
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

##func Pursuit():
#if the evader is ahead and facing the agent then we can just seek
#for the evader's current position.
	# nasze toTarget: Vector2D ToEvader = evader->Pos() - m_pVehicle->Pos()
	##var RelativeHeading = m_pVehicle->Heading().dot(evader->Heading())
	##if ((ToEvader.Dot(m_pVehicle->Heading()) > 0) && (RelativeHeading < -0.95)): #acos(0.95)=18 degs
	##	return Seek(evader->Pos())
	#Not considered ahead so we predict where the evader will be.
	#the look-ahead time is proportional to the distance between the evader
	#and the pursuer; and is inversely proportional to the sum of the
	#agents' velocities
	##var LookAheadTime = ToEvader.Length() / (m_pVehicle->MaxSpeed() + evader->Speed())
	#now seek to the predicted future position of the evader
	##return Seek(evader->Pos() + evader->Velocity() * LookAheadTime);

func _draw():
	draw_vector(Vector2(0,0), velocity, Color(255, 0, 0), 5)                                # red
	draw_vector(Vector2(0,0), target.position-self.position, Color(0, 255, 0), 5)  # green
	
	
func draw_vector( origin, vector, color, arrow_size ):
	if vector.length_squared() > 1:
		var points    = []
		var direction = vector.normalized()
		points.push_back( vector + direction * arrow_size * 2 )
		points.push_back( vector + direction.rotated(  PI / 2 ) * arrow_size )
		points.push_back( vector + direction.rotated( -PI / 2 ) * arrow_size )
		draw_polygon( points, PoolColorArray([color]))
		draw_line( origin, vector, color, arrow_size )
	
	
func Vec2DistanceSq(one, two):
	var ySep = two.y - one.y;
	var xSep = two.x - one.x;
	return ySep * ySep + xSep * xSep;
