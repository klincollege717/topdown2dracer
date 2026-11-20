extends CharacterBody2D

@export var max_speed: float = 1700
@export var max_reverse: float = 650
@export var engine_power: float = 700     # Acceleration strength
@export var back: float = 1000
@export var friction: float = -0.2          # Slows the car down naturally
@export var drag: float = -0.00005            # Air resistance / drag
@export var max_turning_speed: float = 3.0    # How fast the car turns (radians per second)
@export var min_turning_speed: float = 1.0
@export var decel: float = 85
@export var brake_power: float = 650.0  # Strong stopping force (higher for supercars)
@export var normal_traction: float = 13.5    # High grip during normal driving
@export var drift_traction: float = 2.0     # Low grip while drifting (lower = more slide)
@export var drift_min_speed: float = 700.0   # Minimum speed required to initiate a drift
@export var drift_turn_boost: float = 1.6
@export var drift_recovery: float = 6.0

var current_traction: float = 15.0

var rotation_direction: float = 0.0

func _physics_process(delta: float) -> void:
	rotation_direction = Input.get_axis("ui_left", "ui_right")
	
	# Apply steering only when the car is moving
	var move_input = Input.get_axis("ui_down", "ui_up")
	
	# Rotate the car
	var current_speed = velocity.length()
	var is_braking = Input.is_action_pressed("ui_accept")
	var is_drifting = is_braking and current_speed > drift_min_speed and rotation_direction != 0
	
	if current_speed > 50.0:
		var speed_ratio = clamp(current_speed / max_speed, 0.0, 1.0)
		var dynamic_turn_speed = lerp(max_turning_speed, min_turning_speed, speed_ratio)
		
		if is_drifting:
			dynamic_turn_speed = lerp(max_turning_speed, min_turning_speed, speed_ratio)
		
		var ramp_window = max_speed * 0.2
		var low_speed_factor = clamp((current_speed - 50.0) / ramp_window, 0.0, 1.0)
		var forward_speed = velocity.dot(-transform.y)
		var steer_dir = 1.0 if forward_speed >= 0 else -1.0
		rotation += rotation_direction * dynamic_turn_speed * low_speed_factor * delta * steer_dir
	# Calculate acceleration vector based on car's facing direction
	# Assuming the sprite faces UP (-transform.y)
	var forward_direction = -transform.y
	var backward_direction = transform.y
	
	
	var forward_velocity = forward_direction * velocity.dot(forward_direction)
	var active_traction = drift_traction if is_drifting else normal_traction
	current_traction = lerp(current_traction, active_traction, clamp(drift_recovery * delta, 0.0, 1.0))
	velocity = velocity.lerp(forward_velocity, clamp(active_traction * delta, 0.0, 1.0))	

	if is_braking:
		# Rapidly slows to 0 and holds there—never reverses
		var active_brake = brake_power * 0.2 if is_drifting else brake_power
		velocity = velocity.move_toward(Vector2.ZERO, active_brake * delta)
	elif move_input > 0:
		velocity += forward_direction * move_input * engine_power * delta
		velocity = velocity.limit_length(max_speed)
	elif move_input < 0:
		velocity -= backward_direction * move_input * back * delta
		velocity = velocity.limit_length(max_reverse)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, decel * delta)
		
		
	# Apply friction and drag
	var friction_force = velocity * friction * delta
	var drag_force = velocity * velocity.length() * drag * delta
	velocity += friction_force + drag_force
	
	var target_offset = velocity * 0.3
	$Camera2D.offset = $Camera2D.offset.lerp(target_offset, 4.0 * delta)
	
	# Move the car and handle collisions
	move_and_slide()
