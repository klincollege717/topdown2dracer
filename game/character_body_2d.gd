extends CharacterBody2D

@export var max_speed: float = 2500
@export var max_reverse: float = 800
@export var engine_power: float = 1000     # Acceleration strength
@export var back: float = 1200 
@export var friction: float = -0.2          # Slows the car down naturally
@export var drag: float = -0.0002            # Air resistance / drag
@export var turning_speed: float = 3.0      # How fast the car turns (radians per second)

var rotation_direction: float = 0.0

func _physics_process(delta: float) -> void:
	rotation_direction = Input.get_axis("ui_left", "ui_right")
	
	# Apply steering only when the car is moving
	var move_input = Input.get_axis("ui_down", "ui_up")
	
	# Rotate the car
	if abs(velocity.length()) > 5.0:
		rotation += rotation_direction * turning_speed * delta * (1.0 if move_input >= 0 else -1.0)
	
	# Calculate acceleration vector based on car's facing direction
	# Assuming the sprite faces UP (-transform.y)
	var forward_direction = -transform.y
	var backward_direction = transform.y
	
	
	velocity = forward_direction * velocity.dot(forward_direction)
	
	
	if move_input > 0:
		velocity += forward_direction * move_input * engine_power * delta
		velocity = velocity.limit_length(max_speed)
	elif move_input < 0:
		velocity -= backward_direction * move_input * back * delta
		velocity = velocity.limit_length(max_reverse)
		
		
	# Apply friction and drag
	var friction_force = velocity * friction * delta
	var drag_force = velocity * velocity.length() * drag * delta
	velocity += friction_force + drag_force
	
	# Move the car and handle collisions
	move_and_slide()
