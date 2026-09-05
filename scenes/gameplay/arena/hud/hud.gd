class_name HUD
extends Control

@onready var _blink_bar: TextureProgressBar = %BlinkBar


func _ready() -> void:
	_connect_signals()


func _connect_signals() -> void:
	GameEvents.blink_cooldown_progress_updated.connect(_on_blink_cooldown_progress_updated)
	GameEvents.blink_progress_updated.connect(_on_blink_progress_updated)


func _on_blink_cooldown_progress_updated(progress: Dictionary, progress_ratio: float) -> void:
	_blink_bar.value = 1.0 - progress_ratio


func _on_blink_progress_updated(progress: Dictionary, progress_ratio: float) -> void:
	_blink_bar.value = progress_ratio
