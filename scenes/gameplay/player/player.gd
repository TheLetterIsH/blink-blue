class_name Player
extends CharacterBody2D

# State Machine
enum State {
	NONE,
	NORMAL,
	BLINK,
}

@export_group("State Machine")
@export var state: State = State.NONE

@export_group("Movement")
@export var move_speed: float = 160.0
@export var acceleration: float = 1152.0
@export var friction: float = 1408.0

@export_group("Aim")
@export var aim_speed: float = 20.0
var _aim_angle_lagged: float = 0.0

@export_group("Feel")
@export var max_tilt: float = PI * 0.15
@export var tilt_strength: float = 8.0

@export_group("Debug")
@export var debug_draw_aim_direction: bool = false

# Arena
var _arena_center := G.viewport_center
var _arena_player_bounds_radius := G.arena_player_bounds_radius

@onready var _sprites: Node2D = $Sprites
@onready var _shadow_sprite: Sprite2D = %ShadowSprite2D
@onready var _head_sprite: Sprite2D = %HeadSprite2D
@onready var _body_sprite: Sprite2D = %BodySprite2D
@onready var _hand_sprite: Sprite2D = %HandSprite2D
@onready var _hand_pivot: Node2D = %HandPivot


func _ready() -> void:
	_change_state(State.NORMAL)
	
	_connect_signals()


func _connect_signals() -> void:
	pass


func _process(delta: float) -> void:
	if debug_draw_aim_direction:
		queue_redraw()


func _physics_process(delta: float) -> void:
	_process_state(delta)


func _process_state(delta: float) -> void:
	match state:
		State.NORMAL:
			_normal_state(delta)


func _change_state(next_state: State) -> void:
	if state == next_state:
		return
	
	state = next_state
	
	match state:
		State.NORMAL:
			_changed_to_normal_state()


func _changed_to_normal_state() -> void:
	pass


func _normal_state(delta: float) -> void:
	# Movement
	var move_direction := _get_move_direction()
	
	if move_direction != Vector2.ZERO:
		velocity = velocity.move_toward(move_direction * move_speed, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	
	move_and_slide()
	
	# Bounds
	var offset := global_position - _arena_center
	if offset.length() > _arena_player_bounds_radius:
		global_position = _arena_center + offset.normalized() * _arena_player_bounds_radius
	
	# Aim
	var aim_direction := _get_aim_direction()
	var aim_angle := aim_direction.angle()
	_aim_angle_lagged = rotate_toward(_aim_angle_lagged, aim_angle, aim_speed * delta)
	_hand_pivot.rotation = _aim_angle_lagged
	
	# Effects
	var head_target_rotation := move_direction.x * max_tilt * 0.5
	var body_target_rotation := move_direction.x * max_tilt
	_head_sprite.rotation = lerp_angle(_head_sprite.rotation, head_target_rotation, tilt_strength * delta)
	_body_sprite.rotation = lerp_angle(_body_sprite.rotation, body_target_rotation, tilt_strength * delta)
	
	_hand_sprite.z_index = -1 if aim_direction.y < 0 else 1


func _get_move_direction() -> Vector2:
	var move_direction := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	return move_direction


func _get_aim_direction() -> Vector2:
	var mouse_position := get_global_mouse_position()
	var aim_direction := global_position.direction_to(mouse_position)
	return aim_direction


func _draw() -> void:
	if debug_draw_aim_direction:
		var a := to_local(_hand_sprite.global_position)
		var b := to_local(get_global_mouse_position())
		draw_line(a, b, Color.MAGENTA, 1.0)
