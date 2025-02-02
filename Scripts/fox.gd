extends Area2D

const WALK_SPEED = 200
const HUNT_SPEED = 400
const START_HUNGER = 10
const MAX_HUNGER = 10
const WANDER_RANGE = 300
const BIRTH_RANGE = 100

var current_state = "idle"
var hunger
var speed
var direction
var visible_rabbits = []
var visible_foxes = []
var target_position
var can_give_birth = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$SightCircle.connect("area_entered", _on_sight_entered)
	$SightCircle.connect("area_exited", _on_sight_exited)
	$HungerTimer.timeout.connect(_lose_hunger)
	$BirthTimer.timeout.connect(_birth_timer_timeout)
	
	connect("area_entered", _area_entered)
	hunger = START_HUNGER

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if global_position.distance_to(Vector2(0,0)) > 5000:
			print(current_state)
	if hunger <= 0:
		queue_free()
		
	match current_state:
		"hunting":
			_hunt(delta)
		"mating":
			_seek_mate(delta)
		"wandering":
			_wander(delta)
	
	_evaluate_state()

func _evaluate_state():
	for rabbit in visible_rabbits:
		if not is_instance_valid(rabbit):
			visible_rabbits.erase(rabbit)
		if not _is_outside_coop(rabbit.position):
			visible_rabbits.erase(rabbit)
	if current_state == "idle":
		if hunger < 7 and visible_rabbits:
			current_state = "hunting"
		elif hunger >= 7 and _find_closest_node(visible_foxes) and can_give_birth:
			current_state = "mating"
		else:
			_start_wandering()

func _area_entered(body):
	if body.is_in_group("rabbits"):
		hunger = clamp(hunger + 5, 0, MAX_HUNGER)
		body.queue_free()
		current_state = "idle"
	elif body.is_in_group("foxes") and hunger >= 7 and can_give_birth:
		_give_birth()

func _on_sight_entered(body):
	if body.is_in_group("rabbits") and _is_outside_coop(body.position):
		visible_rabbits.append(body)
		if hunger < 7:
			current_state = "hunting"
	elif body.is_in_group("foxes") and body != self:
		visible_foxes.append(body)
		if hunger >= 7 and can_give_birth:
			current_state = "mating"

func _on_sight_exited(body):
	if body.is_in_group("rabbits"):
		visible_rabbits.erase(body)
	elif body.is_in_group("foxes"):
		visible_rabbits.erase(body)

func _hunt(delta):
	speed = HUNT_SPEED
	direction = _get_prey_dir()
	global_position += direction * speed * delta

func _seek_mate(delta):
	if hunger < 7:
		current_state = "idle"
	speed = WALK_SPEED
	direction = _get_mate_dir()
	global_position += direction * speed * delta

func _start_wandering():
	var wander_position
	if $WanderTimer.is_stopped():
		current_state = "wandering"
		wander_position = global_position
		while true:
			var new_target_position = _get_random_offset(WANDER_RANGE) + wander_position
			var clamp_target_position = Vector2(
				clamp(new_target_position.x, -2500, 2500),
				clamp(new_target_position.y, -2500, 2500)
			)
			if _is_outside_coop(clamp_target_position):
				target_position = clamp_target_position
				break

func _wander(delta):
	if target_position:
		speed = WALK_SPEED
		direction = (target_position - global_position).normalized()
		global_position += direction * speed * delta
		
		if global_position.distance_to(target_position) < 10.0:
			$WanderTimer.start()
			target_position = null
			current_state = "idle"

func _lose_hunger():
	hunger -= 1

func _birth_timer_timeout():
	can_give_birth = true

func _get_prey_dir():
	var closest_rabbit = _find_closest_node(visible_rabbits)
	if closest_rabbit:
		return (closest_rabbit.global_position - position).normalized()
	else:
		current_state = "idle"
		return Vector2(0,0)

func _get_mate_dir():
	var closest_fox = _find_closest_node(visible_foxes)
	if closest_fox:
		if global_position.distance_to(closest_fox.position) < 3:
			_give_birth()
		return (closest_fox.global_position - position).normalized()
	else:
		target_position = null
		current_state = "idle"
		return Vector2(0,0)

func _find_closest_node(node_list):
	var closest_node = null
	var closest_distance = INF
	
	for node in node_list:
		if is_instance_valid(node):
			if _is_outside_coop(node.global_position):
				var outside_coop = _is_outside_coop(node.global_position)
				var distance = global_position.distance_to(node.global_position)
				if distance < closest_distance and distance != 0:
					closest_distance = distance
					closest_node = node
			else:
				node_list.erase(node)
	
	return closest_node

func _get_random_offset(offset_range):
	var random_offset = Vector2()
	while random_offset.length() < 50.0:  # Ensure at least 5 pixels distance
		random_offset = Vector2(
			randf_range(-offset_range, offset_range),
			randf_range(-offset_range, offset_range)
		)
	return random_offset

func _give_birth():
	can_give_birth = false
	$BirthTimer.start()
	var mating_position = global_position
	var random_pos = _get_random_offset(BIRTH_RANGE)
	get_parent().spawn_fox_at_vector(random_pos + mating_position)
	current_state = "idle"

func _is_outside_coop(vector):
	var coop_maximum = Vector2(Global.coop_origin.x + Global.coop_size, Global.coop_origin.y + Global.coop_size)
	return _is_outside_range(vector, Global.coop_origin, coop_maximum)

func _is_outside_range(vector, min_vector, max_vector):
	return (vector.x < min_vector.x || vector.x > max_vector.x) || (vector.y < min_vector.y || vector.y > max_vector.y) 
