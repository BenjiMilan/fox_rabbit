extends Node2D

signal count_animals

const TIME_TO_MAX = 60

var rabbit_points = []
var fox_points = []
var ORIGIN
var MAX_POINT
var length_x
var length_y
var x_offset
var y_offset_rabbits
var y_offset_foxes
var delta
var time = 0
var rabbits
var foxes
var point_vector
var last_rabbit_point
var last_fox_point
var last_time

func _ready() -> void:
	var line_points = $Axis.get_points()
	ORIGIN = line_points[1]
	MAX_POINT = Vector2(line_points[2].x, line_points[0].y)
	length_x = abs(MAX_POINT.x - ORIGIN.x)
	length_y = abs(MAX_POINT.y - ORIGIN.y)
	last_rabbit_point = ORIGIN
	last_time = Time.get_unix_time_from_system()

func _process(delta: float) -> void:
	if $TimeSincePoint.is_stopped():
		$TimeSincePoint.start()
		queue_redraw()

func _draw() -> void:
	time = Time.get_unix_time_from_system() - last_time
	if time > TIME_TO_MAX:
		time = 0
		last_time = Time.get_unix_time_from_system()
		rabbit_points = [Vector2(ORIGIN.x, rabbit_points[-1].y)]
		fox_points = [Vector2(ORIGIN.x, fox_points[-1].y)]
	
	count_animals.emit()
	rabbits = Global.rabbit_count
	foxes = Global.fox_count
	x_offset = (length_x/TIME_TO_MAX) * time
	y_offset_rabbits = (length_y/250) * rabbits
	y_offset_foxes = (length_y/250) * foxes
	
	point_vector = Vector2(ORIGIN.x+x_offset, ORIGIN.y-y_offset_rabbits)
	rabbit_points.append(point_vector)
	last_rabbit_point = rabbit_points[0]
	for point in rabbit_points:
		draw_line(last_rabbit_point, point, Color.BEIGE, 3)
		last_rabbit_point = point
	
	point_vector = Vector2(ORIGIN.x+x_offset, ORIGIN.y-y_offset_foxes)
	fox_points.append(point_vector)
	last_fox_point = fox_points[0]
	for point in fox_points:
		draw_line(last_fox_point, point, Color.DARK_ORANGE, 3)
		last_fox_point = point
