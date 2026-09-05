class_name Main
extends Node
## The main scene.
##
## It is the current scene of the game at all times.
## It handles the game flow, [enum Screen]s, [enum Overlay]s and the pause state of the game.

## Emitted after the active screen has been swapped out for a new one.[br][br]
## [param previous_screen]: the screen that was active before the change.[br]
## [param next_screen]: the screen that is now active.
signal screen_changed(previous_screen: Screen, next_screen: Screen)
## Emitted after an overlay has been instantiated and pushed onto the overlay stack.[br][br]
## [param overlay]: the overlay type that was pushed.[br]
## [param instance]: the resulting node instance added to the tree.
signal overlay_pushed(overlay: Overlay, instance: Node)
## Emitted after an overlay has been removed from the overlay stack and freed.[br][br]
## [param overlay]: the overlay type that was popped.[br]
## [param instance]: the node instance that was removed.
signal overlay_popped(overlay: Overlay, instance: Node)

## Emitted when the game transitions from unpaused to paused (i.e. the first pause request is made).
signal paused()
## Emitted when the game transitions from paused to unpaused (i.e. the last pause request is released).
signal resumed()

## The set of screens the game can display. Only one screen is active at a time.
enum Screen {
	NONE,
	MAIN_MENU,
	ARENA,
	GAME_OVER,
}

## The set of overlays that can be stacked on top of the active screen.
enum Overlay {
	PAUSE_MENU,
	OPTIONS_MENU,
}

@export_group("Screen")
## Maps each [enum Screen] enum value to the [PackedScene] that should be instantiated for it.
@export var screen_scenes: Dictionary[Screen, PackedScene]
## The screen that is loaded automatically when the game starts.
@export var initial_screen: Screen

@export_group("Overlay")
## Maps each [enum Overlay] enum value to the [PackedScene] that should be instantiated for it.
@export var overlay_scenes: Dictionary[Overlay, PackedScene]
## Maps each [enum Overlay] enum value to whether pushing it should also request a game pause.
@export var overlay_pauses_screen: Dictionary[Overlay, bool]

## The currently active screen.
var _screen: Screen = Screen.NONE
## The instantiated node for the currently active screen.
var _screen_instance: Node = null
## Stack of currently pushed overlays, each entry is a [Dictionary] with an [enum Overlay] enum as the key and an instance as the value.
var _overlay_stack: Array[Dictionary] = []

## List of objects that have an active pause request. The game stays paused while this is non-empty.
var _pause_requesters: Array = []

## The node that holds a gameplay screen
@onready var _gameplay: Node2D = %Gameplay
## The node that holds a UI screen
@onready var _ui: Control = %UI
## The node that holds overlays
@onready var _overlays: CanvasLayer = %Overlays


func _ready() -> void:
	# Set reference
	G.main = self

	# Set process modes
	process_mode = Node.PROCESS_MODE_ALWAYS
	_gameplay.process_mode = Node.PROCESS_MODE_PAUSABLE
	_ui.process_mode = Node.PROCESS_MODE_PAUSABLE
	_overlays.process_mode = Node.PROCESS_MODE_ALWAYS

	# Initialize screen
	change_screen(initial_screen)


#region SCREEN

## Switches the active screen to [param next_screen], clearing any active overlays and
## unloading the previous screen first. Emits [signal screen_changed] on success.[br][br]
## [param next_screen]: the [enum Screen] enum value to switch to.
func change_screen(next_screen: Screen) -> void:
	var next_screen_instance := load_screen(next_screen)
	if not next_screen_instance:
		push_error("Failed to change screen to Screen.%s as it does not exist." % Screen.keys().get(next_screen))
		return

	clear_overlays()
	_unload_screen(_screen_instance)

	var previous_screen := _screen

	_screen = next_screen
	_screen_instance = next_screen_instance

	screen_changed.emit(previous_screen, next_screen)


## Instantiates the scene mapped to [param screen] and adds it under the appropriate
## parent (Gameplay or UI) based on its root node type. Returns the new instance,
## or null if no scene is mapped or the root type is invalid.[br][br]
## [param screen]: the [enum Screen] enum value to load.
func load_screen(screen: Screen) -> Node:
	var screen_scene := screen_scenes.get(screen) as PackedScene
	if not screen_scene:
		push_error("No scene mapped to Screen.%s." % Screen.keys().get(screen))
		return null

	var screen_instance := screen_scene.instantiate()

	var parent := _resolve_screen_parent(screen_instance)
	if not parent:
		push_error("Screen.%s root is of invalid type %s. Screen type must be Control, CanvasLayer, or Node2D." % [Screen.keys().get(screen), screen_instance.get_class()])
		screen_instance.queue_free()
		return null

	parent.add_child(screen_instance)

	return screen_instance


## Frees [param screen_instance] if it is a valid node currently in the tree.[br][br]
## [param screen_instance]: the screen node to remove and free.
func _unload_screen(screen_instance: Node) -> void:
	if screen_instance and is_instance_valid(screen_instance) and screen_instance.is_inside_tree():
		screen_instance.queue_free()


## Determines which container node a screen instance should be parented under,
## based on its type. Returns null if the type isn't supported.[br][br]
## [param screen_instance]: the instantiated screen root node to check.
func _resolve_screen_parent(screen_instance: Node) -> Node:
	if screen_instance is Control or screen_instance is CanvasLayer:
		return _ui
	elif screen_instance is Node2D:
		return _gameplay

	return null

## Returns the currently active screen.
func get_screen() -> Screen:
	return _screen

#endregion


#region OVERLAY

## Instantiates and pushes [param overlay] onto the overlay stack, optionally requesting
## a pause if configured in [member overlay_pauses_screen]. Emits [signal overlay_pushed]
## on success. Returns the new overlay instance, or null if it's already pushed or has no mapped scene.[br][br]
## [param overlay]: the [enum Overlay] enum value to push.
func push_overlay(overlay: Overlay) -> Node:
	for entry: Dictionary in _overlay_stack:
		if entry.id == overlay:
			push_error("Invalid push. Overlay.%s is already in the stack." % Overlay.keys().get(overlay))
			return null

	var overlay_scene := overlay_scenes.get(overlay) as PackedScene
	if not overlay_scene:
		push_error("No scene mapped to Overlay.%s." % Overlay.keys().get(overlay))
		return null

	var overlay_instance := overlay_scene.instantiate()
	_overlays.add_child(overlay_instance)

	if overlay_pauses_screen.get(overlay, false):
		request_pause(overlay_instance)

	_overlay_stack.append({ id = overlay, instance = overlay_instance })

	overlay_pushed.emit(overlay, overlay_instance)

	return overlay_instance


## Removes and frees the topmost overlay on the stack, releasing its pause request if it
## held one. Emits [signal overlay_popped]. Does nothing if the stack is empty.
func pop_overlay() -> void:
	if _overlay_stack.is_empty():
		push_error("Invalid pop. Overlay stack is empty.")
		return

	var entry: Dictionary = _overlay_stack.pop_back()
	var overlay: Overlay = entry.id
	var overlay_instance: Node = entry.instance

	if overlay_pauses_screen.get(overlay, false):
		release_pause(overlay_instance)

	overlay_instance.queue_free()

	overlay_popped.emit(overlay, overlay_instance)


## Pops all overlays currently on the stack, one at a time, until it's empty.
func clear_overlays() -> void:
	while has_overlays():
		pop_overlay()


## Returns the node instance of the topmost overlay on the stack, or null if the stack is empty.
func get_top_overlay() -> Node:
	return _overlay_stack.back().instance if not _overlay_stack.is_empty() else null


## Returns true if there is at least one overlay currently pushed.
func has_overlays() -> bool:
	return not _overlay_stack.is_empty()

#endregion


#region PAUSE

## Registers [param requester] as holding a pause request. The game pauses (and
## [signal paused] is emitted) when this is the first active request.[br][br]
## [param requester]: the object requesting the pause.
func request_pause(requester: Variant) -> void:
	if _pause_requesters.has(requester):
		push_warning("Requester %s already holds a pause request." % [requester])
		return

	_pause_requesters.append(requester)

	if _pause_requesters.size() == 1:
		get_tree().paused = true
		paused.emit()


## Releases [param requester]'s pause request. The game resumes (and [signal resumed]
## is emitted) once no requesters remain.[br][br]
## [param requester]: the object that previously called [method request_pause].
func release_pause(requester: Variant) -> void:
	if not _pause_requesters.has(requester):
		push_warning("Requester %s has no pause request." % [requester])
		return

	_pause_requesters.erase(requester)

	if _pause_requesters.is_empty():
		get_tree().paused = false
		resumed.emit()


## Returns true if the game is currently paused (i.e. at least one pause request is active).
func is_paused() -> bool:
	return not _pause_requesters.is_empty()

#endregion
