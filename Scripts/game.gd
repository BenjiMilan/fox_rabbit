extends Node2D

@export var Rabbit = preload("res://Scenes/rabbit.tscn")
@export var BerryBush = preload("res://Scenes/berry_bush.tscn")
@export var Fox = preload("res://Scenes/fox.tscn")

const INITIAL_BERRIES = 100
const INITAL_RABBITS = 70
const INITIAL_FOXES = 10

var map_height
var map_width

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	map_height = $Map.size.y
	map_width = $Map.size.x
	Global.map_size = map_height
	Global.coop_size = $Coop.size.x
	Global.coop_origin = $Coop.position
	
	$BerryTimer.connect("timeout", Callable(self, "_spawn_random").bind(BerryBush))
	$Camera2D/PopGraph.connect("count_animals", _count_animals)
	
	for i in INITAL_RABBITS:
		_spawn_random(Rabbit)
	
	for i in INITIAL_BERRIES:
		_spawn_random(BerryBush)
	
	for i in INITIAL_FOXES:
		_spawn_random(Fox)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _count_animals():
	Global.fox_count = _count_child_in_group("foxes")
	Global.rabbit_count = _count_child_in_group("rabbits")

func _count_child_in_group(group):
	var count = 0
	for child in get_children():
		if child.is_in_group(group):
			count += 1
	return count

func _spawn_random(scene):
	var obj = scene.instantiate()
	var random_x = randf_range(-map_width/2, map_width/2)
	var random_y = randf_range(-map_height/2, map_height/2)
	obj.global_position = Vector2(random_x, random_y)
	add_child(obj)

func spawn_rabbit_at_vector(vector):
	var obj = Rabbit.instantiate()
	obj.global_position = vector
	call_deferred("add_child", obj)

func spawn_fox_at_vector(vector):
	var obj = Fox.instantiate()
	obj.global_position = vector
	call_deferred("add_child", obj)
