class_name BlinkController
extends Node

enum State {
	NONE,
	BLINK_COOLDOWN,
	BLINK,
}

@export_group("State Machine")
@export var state: State = State.NONE

@export_group("Blink Cooldown")
@export var blink_cooldown_duration: float = 4.0

@export_group("Blink")
@export var blink_duration: float = 1.0
@export var blink_time_scale_mult: float = 0.05

# Blink Cooldown
var _blink_cooldown_timer_tag: StringName
var _blink_cooldown_progress: Dictionary
var _blink_cooldown_progress_ratio: float

# Blink
var _blink_timer_tag: StringName
var _blink_progress: Dictionary
var _blink_progress_ratio: float

@onready var _timer: Kshan = $Kshan


func _ready() -> void:
	_connect_signals()
	
	_change_state(State.BLINK_COOLDOWN)


func _connect_signals() -> void:
	pass


func _physics_process(delta: float) -> void:
	_process_state(delta)


func _process_state(delta: float) -> void:
	match state:
		State.BLINK_COOLDOWN:
			_blink_cooldown_state(delta)
		State.BLINK:
			_blink_state(delta)


func _change_state(next_state: State) -> void:
	if state == next_state:
		return
	
	match state:
		State.BLINK_COOLDOWN:
			_exit_blink_cooldown_state()
		State.BLINK:
			_exit_blink_state()
	
	state = next_state
	
	match state:
		State.BLINK_COOLDOWN:
			_enter_blink_cooldown_state()
		State.BLINK:
			_enter_blink_state()


func _enter_blink_cooldown_state() -> void:
	_blink_cooldown_timer_tag = _timer.after(blink_cooldown_duration, func():
		_change_state(State.BLINK),
		&"blink_cooldown"
	)


func _blink_cooldown_state(_delta: float) -> void:
	_blink_cooldown_progress = _timer.get_progress(_blink_cooldown_timer_tag)
	_blink_cooldown_progress_ratio = _timer.get_progress_ratio(_blink_cooldown_timer_tag)
	GameEvents.emit_blink_cooldown_progress_updated(_blink_cooldown_progress, _blink_cooldown_progress_ratio)


func _exit_blink_cooldown_state() -> void:
	pass


func _enter_blink_state() -> void:
	_blink_timer_tag = _timer.after(blink_duration, func():
		_change_state(State.BLINK_COOLDOWN),
		&"blink"
	)
	_timer.set_unscaled(_blink_timer_tag, true)
	
	Engine.time_scale *= blink_time_scale_mult
	
	GameEvents.emit_blink_started()


func _blink_state(_delta: float) -> void:
	_blink_progress = _timer.get_progress(_blink_timer_tag)
	_blink_progress_ratio = _timer.get_progress_ratio(_blink_timer_tag)
	GameEvents.emit_blink_progress_updated(_blink_progress, _blink_progress_ratio)


func _exit_blink_state() -> void:
	Engine.time_scale /= blink_time_scale_mult
	
	GameEvents.emit_blink_ended()
