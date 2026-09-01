class_name Cursor
extends Node2D

@export var rotation_speed: float = 0.5

var _rotation_direction: float = 0
var _previous_position: Vector2 = Vector2.ZERO

@onready var _sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	
	_previous_position = global_position


func _process(delta: float) -> void:
	global_position = get_global_mouse_position()
	
	# Effect
	var dx := global_position.x - _previous_position.x
	if dx > 0:
		_rotation_direction = 1
	elif dx < 0:
		_rotation_direction = -1
	
	_sprite.rotation += _rotation_direction * TAU * rotation_speed * delta
	
	_previous_position = global_position
