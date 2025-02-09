extends Area2D

const WALK_SPEED = 150
const FLEE_SPEED = 200
const MAX_HUNGER = 10
const START_HUNGER = 5
const WANDER_RANGE = 300
const BIRTH_RANGE = 100

var current_state = "idle"
var direction = Vector2(1,0)
var last_direction
var speed
var hunger
var visible_rabbits = []
var visible_berries = []
var visible_foxes = []
var target_position
var can_give_birth = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$SightCircle.connect("area_entered", _on_sight_entered)
	$SightCircle.connect("area_exited", _on_sight_exited)
	connect("area_entered", area_entered)
	$HungerTimer.connect("timeout", _hunger_countdown)
	$BirthTimer.connect("timeout", _birth_timer_timeout)
	hunger = START_HUNGER
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if hunger == 0:
		queue_free()
	
	match current_state:
		"fleeing":
			_flee(delta)
		"eating":
			_seek_food(delta)
		"mating":
			_seek_mate(delta)
		"wandering":
			_wander(delta)
	
	_evaluate_state()

func area_entered(body):
	if body.is_in_group("berries"):
		hunger = clamp(hunger + 3, 0, MAX_HUNGER)
		body.queue_free()
		current_state = "idle"
	elif body.is_in_group("rabbits") and hunger >= 7 and can_give_birth:
		_give_birth()

func _evaluate_state():
	if current_state == "idle":
		if visible_foxes:
			current_state = "fleeing"
		elif visible_berries and hunger < 7:
			current_state = "eating"
		elif _find_closest_node(visible_rabbits) and hunger >= 7:
			current_state = "mating"
		else:
			_start_wandering()

func _flee(delta):
	speed = FLEE_SPEED
	direction = _get_flee_dir()
	$AnimationPlayer.play("Run")
	global_position += direction * speed * delta

func _seek_food(delta):
	speed = WALK_SPEED
	direction = _get_food_dir()
	$AnimationPlayer.play("Walk")
	global_position += direction * speed * delta

func _seek_mate(delta):
	speed = WALK_SPEED
	direction = _get_mate_dir()
	$AnimationPlayer.play("Walk")
	global_position += direction * speed * delta

func _start_wandering():
	var wander_position
	if $WanderTimer.is_stopped():
		current_state = "wandering"
		wander_position = global_position
		$AnimationPlayer.play("Walk")
		var new_target_position = _get_random_offset(WANDER_RANGE) + wander_position
		var clamp_target_position = Vector2(
			clamp(new_target_position.x, -2500, 2500),
			clamp(new_target_position.y, -2500, 2500)
		)
		target_position = clamp_target_position

func _wander(delta):
	if target_position:
		speed = WALK_SPEED
		direction = (target_position - global_position).normalized()
		global_position += direction * speed * delta
		
		if global_position.distance_to(target_position) < 5.0:
			$WanderTimer.start()
			target_position = null
			$AnimationPlayer.play("RESET")
			current_state = "idle"

func _on_sight_entered(body):
	if body.is_in_group("berries"):
		visible_berries.append(body)
		if hunger < 7 and current_state != "fleeing":
			current_state = "eating"
	elif body.is_in_group("rabbits") and body != self:
		visible_rabbits.append(body)
		if hunger >= 7 and current_state != "fleeing":
			current_state = "mating"
	elif body.is_in_group("foxes"):
		visible_foxes.append(body)
		current_state = "fleeing"

func _on_sight_exited(body):
	if body.is_in_group("berries"):
		visible_berries.erase(body)
	elif body.is_in_group("rabbits"):
		visible_rabbits.erase(body)
	elif body.is_in_group("foxes"):
		visible_foxes.erase(body)

func _hunger_countdown():
	hunger -= 1

func _birth_timer_timeout():
	var mating_position = global_position
	var random_pos = _get_random_offset(BIRTH_RANGE)
	get_parent().spawn_rabbit_at_vector(random_pos + mating_position)
	can_give_birth = true
	
func _get_random_offset(offset_range):
	var random_offset = Vector2()
	while random_offset.length() < 50.0:  # Ensure at least 5 pixels distance
		random_offset = Vector2(
			randf_range(-offset_range, offset_range),
			randf_range(-offset_range, offset_range)
		)
	return random_offset

func _get_food_dir():
	var closest_berry = _find_closest_node(visible_berries)
	if closest_berry:
		return (closest_berry.global_position - position).normalized()
	else:
		current_state = "idle"
		return Vector2(0,0)

func _find_closest_node(node_list):
	var closest_node = null
	var closest_distance = INF
	
	for node in node_list:
		if is_instance_valid(node):
			var distance = global_position.distance_to(node.global_position)
			if distance < closest_distance and distance != 0:
				closest_distance = distance
				closest_node = node
	
	if closest_distance > 1000 and closest_node:
		print(closest_distance)
	return closest_node

func _get_mate_dir():
	var closest_rabbit = _find_closest_node(visible_rabbits)
	if closest_rabbit:
		if global_position.distance_to(closest_rabbit.position) < 3:
			_give_birth()
		return (closest_rabbit.global_position - position).normalized()
	else:
		target_position = null
		current_state = "idle"
		return Vector2(0,0)

func _get_flee_dir():
	var closest_fox = _find_closest_node(visible_foxes)
	if closest_fox:
		return (position - closest_fox.global_position).normalized()
	else:
		target_position = null
		current_state = "idle"
		return Vector2(0,0)

func _give_birth():
	hunger = clamp(hunger - 5, 0, MAX_HUNGER)
	can_give_birth = false
	$BirthTimer.start()
	var mating_position = global_position
	var random_pos = _get_random_offset(BIRTH_RANGE)
	get_parent().spawn_rabbit_at_vector(random_pos + mating_position)
	current_state = "idle"
