extends Node

var main: Main

# Viewport
var viewport_size: Vector2i = Vector2i(640.0, 360.0)
var viewport_center: Vector2 = viewport_size * 0.5
var viewport_bounds: Dictionary[String, int] = {
	top = 0,
	bottom = viewport_size.y,
	left = 0,
	right = viewport_size.x,
}

# Arena
var arena_bounds_radius: float = 164.0
var arena_player_bounds_radius: float = arena_bounds_radius * 0.9
