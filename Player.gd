extends Area2D

export (int) var speed  # How fast the player will move (pixels/sec).
var screensize          # Size of the game window.

func _ready():
	 screensize = get_viewport_rect().size

func _process(delta):
	
	#for debug purposes
	var velocity = Vector2() # The player's movement vector.
	if Input.is_action_pressed("ui_right"):
		velocity.x += 1
	if Input.is_action_pressed("ui_left"):
		velocity.x -= 1
	if Input.is_action_pressed("ui_down"):
		velocity.y += 1
	if Input.is_action_pressed("ui_up"):
		velocity.y -= 1
	if velocity.length() > 0:
		velocity = velocity.normalized() * speed
        #$AnimatedSprite.play()
    #else:
        #$AnimatedSprite.stop()
	position += velocity * delta