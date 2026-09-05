extends Node

signal input_type_changed(new_input_type: InputType)

enum InputType
{
	NONE, 
	KEYBOARD_AND_MOUSE,
	CONTROLLER,
}

@export var input_type: InputType = InputType.KEYBOARD_AND_MOUSE:
	set(value):
		if input_type == value:
			return
		
		input_type = value
		input_type_changed.emit(input_type)
	get:
		return input_type


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion or event is InputEventMouseButton or event is InputEventKey:
		input_type = InputType.KEYBOARD_AND_MOUSE
	elif event is InputEventJoypadMotion or event is InputEventJoypadButton:
		input_type = InputType.CONTROLLER
