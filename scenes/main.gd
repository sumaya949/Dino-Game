extends Node

#preload obstacles
var rock_scene = preload("res://scenes/rock.tscn")
var carrot_scene = preload("res://scenes/carrot.tscn")
var bird_scene = preload("res://scenes/bird.tscn")
var obstacle_types := [rock_scene, carrot_scene]
var obstacles : Array
var bird_heights := [120, 425] #varies the height that the bird spawns at

# variables
#start position for the dinosaur
const DINO_START_POS := Vector2i(150, 485)
const CAM_START_POS := Vector2i(576, 324)
var difficulty
const MAX_DIFFICULTY : int = 2
var score : int
const SCORE_MODIFIER : int = 10
var high_score : int 
#start position for thr 2D camera node

#speed variables
var speed : float #changing speed as the time passes and the game becomes more difficult
const START_SPEED : float = 10.0 #how fast the burger will move across the screen
const MAX_SPEED : int = 25
const SPEED_MODIFIER : int = 5000
var screen_size : Vector2i
var ground_height : int
var tcb_height : int
var game_running : bool
var last_obs #tracks last obstacle created


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	screen_size = get_window().size
	tcb_height = $tcb.get_node("Sprite2D").texture.get_height()
	ground_height = $Ground.get_node("Sprite2D").texture.get_height()
	$GameOver.get_node("Button").pressed.connect(new_game) #triggers new game function with the button input
	new_game()

func new_game():
	#reset variables
	score = 0
	show_score()
	game_running = false
	get_tree().paused = false
	difficulty = 0
	
	#delete all obstacles/reset
	for obs in obstacles:
		obs.queue_free()
	obstacles.clear()
	
	# reset the nodes, prepare for new run of game
	$Dino.position = DINO_START_POS
	$Dino.velocity = Vector2i(0, 0)
	$Camera2D.position = CAM_START_POS
	$Ground.position = Vector2i(0, 0)
	$tcb.position = Vector2i(0,0)
	
	#reset HUD and game over screen 
	$HUD.get_node("StartLabel").show()
	$GameOver.hide()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if game_running:
		#speed up and adjust difficulty
		speed = START_SPEED + score / SPEED_MODIFIER
		if speed > MAX_SPEED:
			speed = MAX_SPEED # making sure the speed does not surpass the max and make the game unplayable
		adjust_difficulty()
		
		generate_obs()
		
		
		#move burger and camera by constantly increasing their x coordinates
		$Dino.position.x += speed
		$Camera2D.position.x += speed
	
		score += speed
		show_score()
		# update ground positiom
		if $Camera2D.position.x - $Ground.position.x > screen_size.x * 1.5:
			$Ground.position.x += screen_size.x
		#remove obstacles that have gone off screen
		if $Camera2D.position.x - $tcb.position.x > screen_size.x * 1.5:
			$tcb.position.x += screen_size.x
		for obs in obstacles:
				if(obs.position.x < $Camera2D.position.x - screen_size.x):
					remove_obs(obs)
	else:
		if Input.is_action_pressed("ui_accept"):
			game_running = true
			$HUD.get_node("StartLabel").hide() #hides start button before game starts
	
func generate_obs():
		#generate ground obstacles
		if obstacles.is_empty() or last_obs.position.x < score + randi_range(300,500) : #checks if obstacle is off screen, and randomizes where it lands on the screen
			if Global.jet_enabled:
				spawn_bird()
				return
			var obs_type = obstacle_types[randi() % obstacle_types.size()] #picks random index from obstacle array then makes it an obstacle type
			var obs
			var max_obs = difficulty + 1
			for i in range(randi() % max_obs + 1): # allows for objects to spawn in clusters
				obs = obs_type.instantiate()
				var obs_height = obs.get_node("Sprite2D").texture.get_height() #gets the exact height from the obstacle
				var obs_scale = obs.get_node("Sprite2D").scale
				var obs_x : int = screen_size.x + score + 100 + (i * 100) #equation to decide where the 
				var obs_y : int = screen_size.y - ground_height - (obs_height * obs_scale.y / 2) + 5
				last_obs = obs
				add_obs(obs, obs_x, obs_y)
			if difficulty == MAX_DIFFICULTY:
				if(randi() % 2) == 0: #50/50 chance of bird spawning
					obs = bird_scene.instantiate()
					var obs_x : int = screen_size.x + score + 100
					var obs_y : int = bird_heights[randi() % bird_heights.size()]
					add_obs(obs, obs_x, obs_y)
	
func add_obs(obs, x, y):
	obs.position = Vector2i(x, y)
	obs.body_entered.connect(hit_obs) #find the body entered signal, connect to it and use the function hit_obs
	add_child(obs)
	obstacles.append(obs)
	
func remove_obs(obs):
	obs.queue_free() #removes the instance of the obstacle off the main node scene
	obstacles.erase(obs)
	
func hit_obs(body):
	if body.name == "Dino":
		game_over()
	
func  show_score():
	#gets score label from the HUD node
	$HUD.get_node("ScoreLabel").text = "SCORE: " + str(score / SCORE_MODIFIER) #str converts int to str
	
func check_high_score():
	if score > high_score:
		high_score = score
		$HUD.get_node("HighScore").text = "HIGH SCORE: " + str(high_score / SCORE_MODIFIER)

func adjust_difficulty():
	difficulty = score / SPEED_MODIFIER
	if difficulty > MAX_DIFFICULTY:
		difficulty = MAX_DIFFICULTY
		
func game_over():
	check_high_score()
	get_tree().paused = true 
	game_running = false
	$GameOver.show()
func spawn_bird():
	var obs = bird_scene.instantiate()
	var bird_heights := [100, 270, 390, 430] 
	var obs_x : int = screen_size.x + score + 100
	var obs_y : int = bird_heights[randi() % bird_heights.size()]
	last_obs = obs
	add_obs(obs, obs_x, obs_y)
	



func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://main_menu.gd")
