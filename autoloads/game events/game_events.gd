extends Node


# Blink
signal blink_started()
signal blink_ended()

# HUD
signal blink_cooldown_progress_updated(progress: Dictionary, progress_ratio: float)
signal blink_progress_updated()

#region Blink

func emit_blink_started() -> void:
	blink_started.emit()


func emit_blink_ended() -> void:
	blink_ended.emit()

#endregion


#region HUD

func emit_blink_cooldown_progress_updated(progress: Dictionary, progress_ratio: float) -> void:
	blink_cooldown_progress_updated.emit(progress, progress_ratio)


func emit_blink_progress_updated(progress: Dictionary, progress_ratio: float) -> void:
	blink_progress_updated.emit(progress, progress_ratio)

#endregion
