class_name ScreenshotController
extends Node


func _unhandled_input(event) -> void:
	if event.is_action_pressed(&"take_screenshot"):
		take_screenshot()


func take_screenshot() -> void:
	await RenderingServer.frame_post_draw
	
	var screenshot := get_viewport().get_texture().get_image()
	var timestamp := Time.get_datetime_string_from_system().replace(":", "-")
	var path := "user://%s.png" % timestamp
	
	screenshot.save_png(path)
	print("Screenshot was saved successfully at %s" % [path])
