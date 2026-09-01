class_name Arena
extends Node2D

@export_category("Bounds")
@export var bounds_radius: float = G.arena_bounds_radius
@export var bounds_segments: int = 16
@export var bounds_outline_thickness: float = 2.0
@export var bounds_decoration_thickness: float = 4.0
@export var bounds_decoration_outline_thickness: float = 8.0

# Bounds
@onready var bounds: Node2D = %Bounds
@onready var bounds_polygon: Polygon2D = %BoundsPolygon
@onready var bounds_outline_polygon: Polygon2D = %BoundsOutlinePolygon
@onready var bounds_decoration_polygon: Polygon2D = %BoundsDecorationPolygon
@onready var bounds_decoration_outline_polygon: Polygon2D = %BoundsDecorationOutlinePolygon


func _ready() -> void:
	# Position bounds
	bounds.global_position = G.viewport_center
	
	# Build bounds
	var points := PackedVector2Array()
	var points_outline := PackedVector2Array()
	
	for i in range(bounds_segments):
		var angle := TAU * i / bounds_segments
		points.append(Vector2(cos(angle), sin(angle)) * bounds_radius)
		points_outline.append(Vector2(cos(angle), sin(angle)) * (bounds_radius + bounds_outline_thickness))
	
	bounds_polygon.polygon = points
	bounds_outline_polygon.polygon = points_outline
	
	var points_decoration := PackedVector2Array()
	var points_decoration_outline := PackedVector2Array()
	
	for j in range(bounds_segments):
		var angle := TAU * j / (bounds_segments)
		points_decoration.append(Vector2(cos(angle), sin(angle)) * (bounds_radius + bounds_decoration_thickness))
		points_decoration_outline.append(Vector2(cos(angle), sin(angle)) * (bounds_radius + bounds_decoration_outline_thickness))
	
	bounds_decoration_polygon.polygon = points_decoration
	bounds_decoration_outline_polygon.polygon = points_decoration_outline


func _process(delta: float) -> void:
	bounds_decoration_polygon.rotation += TAU * 0.01 * delta
	bounds_decoration_outline_polygon.rotation -= TAU * 0.01 * delta
