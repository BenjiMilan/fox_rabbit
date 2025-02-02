extends Camera2D

var CAMERA_SPEED = 5000

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	_zoom()
	_pan(delta)

func _zoom():
	if Input.is_action_just_pressed("camera_zoom_in"):
		zoom = zoom * 1.1
	
	if Input.is_action_just_pressed("camera_zoom_out"):
		zoom = zoom * 0.9

func _pan(delta):
	if Input.is_action_pressed("camera_move_up"):
		position.y -= CAMERA_SPEED * delta
	
	if Input.is_action_pressed("camera_move_down"):
		position.y += CAMERA_SPEED * delta
	
	if Input.is_action_pressed("camera_move_right"):
		position.x += CAMERA_SPEED * delta
	
	if Input.is_action_pressed("camera_move_left"):
		position.x -= CAMERA_SPEED * delta
