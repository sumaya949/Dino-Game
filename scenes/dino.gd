extends CharacterBody2D

#NOTE --> this this started off as a dino game so ignore the random uses of dino for my burger sprite

const GRAVITY : int = 3500
const JUMP_SPEED : int = -1400
const THRUST : int = 6000
const FLY_GRAVITY: int = 1800 # separate gravity const for jetpack mode
const MAX_SPEED : int = -500 #fastest speed that you can fly up
const MAX_FALL_SPEED : int = 1100 #fastest you can fall down in jetpack mode

var is_jet_enabled : bool = false
func _ready() -> void:
	is_jet_enabled = Global.jet_enabled
	Global.jet_mode_toggled.connect(_on_jet_mode_toggled)
	
func _on_jet_mode_toggled(is_enabled: bool) -> void:
	is_jet_enabled = is_enabled
# Called each frame, delta is the amount of time since the last frame
#chained if statement that takes in input and plays the correct assigned animation
func _physics_process(delta):
		var game_running : bool = get_parent().game_running

		
		if is_jet_enabled and game_running:
			velocity.y += FLY_GRAVITY*delta
			_jetpack_mode(delta)
		else :
			velocity.y += GRAVITY*delta
			_normal_mode()
		move_and_slide()
	
func _jetpack_mode(delta: float) -> void: #new function to handle jetpack mode
	var thrusting := Input.is_action_pressed("ui_accept")
	
	if thrusting:
		velocity.y -= THRUST*delta
		
	
	velocity.y = clamp(velocity.y, MAX_SPEED, MAX_FALL_SPEED)
	
	if is_on_floor() and not thrusting:
		# Walking on the ground between flying periods
		$RunCol.disabled = false
		if Input.is_action_pressed("ui_down"):
			$AnimatedSprite2D.play("duck")
			$RunCol.disabled = true
		else:
			$AnimatedSprite2D.play("run")
	else:
		$RunCol.disabled = false
		$AnimatedSprite2D.play("jump")
func _normal_mode() -> void:
	if is_on_floor():
		if not get_parent().game_running:
			$AnimatedSprite2D.play("idle")
		else:
			$RunCol.disabled = false
			if Input.is_action_pressed("ui_accept"):
				velocity.y = JUMP_SPEED
				$JumpSound.play()
			elif Input.is_action_pressed("ui_down"):
				$AnimatedSprite2D.play("duck")
				$RunCol.disabled = true
			else:
				$AnimatedSprite2D.play("run")
	else:
		$AnimatedSprite2D.play("jump")
	
