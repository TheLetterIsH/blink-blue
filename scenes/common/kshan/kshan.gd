class_name Kshan
extends Node
## An advanced timer component.
## 
## It features multiple different timer types.

## Emitted whenever a timer ends, either naturally or if cancelled.
signal finished(tag: StringName)

const CHARACTERS: String = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"

var _timers: Dictionary[StringName, Dictionary] = {}
var _empty_callable: Callable = func(): pass
var _previous_frame_time: int = 0


func _ready() -> void:
	_previous_frame_time = Time.get_ticks_usec()


func _process(delta: float) -> void:
	var frame_time := Time.get_ticks_usec()
	var real_delta := (frame_time - _previous_frame_time) / 1_000_000.0
	_previous_frame_time = frame_time
	
	var tags := _timers.keys().duplicate()
	
	for tag: StringName in tags:
		var entry: Dictionary = _timers.get(tag)
		if !entry:
			continue
		
		var dt := real_delta if entry.get("unscaled", false) else delta
		entry.elapsed += dt
		
		match entry.type:
			&"run":
				entry.action.call()
			
			&"run_for":
				entry.action.call()
				if entry.elapsed > entry.delay:
					entry.after.call()
					_timers.erase(tag)
					finished.emit(tag)
			
			&"after":
				if entry.elapsed > entry.delay:
					entry.action.call()
					_timers.erase(tag)
					finished.emit(tag)
			
			&"cooldown":
				if entry.elapsed > entry.delay * entry.multiplier and entry.condition.call():
					entry.action.call()
					entry.elapsed = 0.0
					entry.delay = _resolve_delay(entry.unresolved_delay)
					if entry.times > 0:
						entry.times -= 1
						if entry.times <= 0:
							entry.after.call()
							_timers.erase(tag)
							finished.emit(tag)
			
			&"every":
				if entry.elapsed > entry.delay * entry.multiplier:
					entry.action.call()
					entry.elapsed -= entry.delay * entry.multiplier
					entry.index += 1
					entry.delay = _resolve_delay(entry.unresolved_delay)
					if entry.times > 0:
						entry.times -= 1
						if entry.times <= 0:
							entry.after.call()
							_timers.erase(tag)
							finished.emit(tag)
			
			&"every_step":
				if entry.elapsed > entry.delays[entry.index] * entry.multiplier:
					entry.action.call()
					entry.elapsed -= entry.delays[entry.index] * entry.multiplier
					entry.index += 1
					if entry.times > 0:
						entry.times -= 1
						if entry.times <= 0:
							entry.after.call()
							_timers.erase(tag)
							finished.emit(tag)


#region TIMERS

## Calls [param action] every frame until cancelled.
## [param after] triggers once the timer is cancelled.
func run(action: Callable, after: Callable = _empty_callable, tag: StringName = _generate_tag()) -> StringName:
	_timers[tag] = {
		type = &"run",
		elapsed = 0.0,
		action = action,
		after = after,
	}
	return tag


## Calls [param action] every frame for [param delay] seconds.
## [param after] triggers once time elapses.
func run_for(delay: Variant, action: Callable, after: Callable = _empty_callable, tag: StringName = _generate_tag()) -> StringName:
	_timers[tag] = {
		type = &"run_for",
		elapsed = 0.0,
		unresolved_delay = delay,
		delay = _resolve_delay(delay),
		action = action,
		after = after,
	}
	return tag


## Calls [param action] once after [param delay] ends.
func after(delay: Variant, action: Callable, tag: StringName = _generate_tag()) -> StringName:
	_timers[tag] = {
		type = &"after",
		elapsed = 0.0,
		unresolved_delay = delay,
		delay = _resolve_delay(delay),
		action = action,
	}
	return tag


## Calls [param action] [param times] times every [param delay] seconds but only if [param condition] is true.
## If [param condition] is false when the time elapses, it keeps checking [param condition] every frame until it becomes true.
## If [param times] is 0, the timer runs indefinitely.
## [param after] triggers once [param times] is exhausted.
func cooldown(delay: Variant, condition: Callable, action: Callable, times: int = 0, after: Callable = _empty_callable, tag: StringName = _generate_tag()) -> StringName:
	_timers[tag] = {
		type = &"cooldown",
		elapsed = 0.0,
		unresolved_delay = delay,
		delay = _resolve_delay(delay),
		condition = condition,
		action = action,
		times = times,
		after = after,
		multiplier = 1.0,
	}
	return tag


## Calls [param action] [param times] times every [param delay] seconds.
## If [param times] is 0, the timer runs indefinitely.
## If [param immediate] is true, [param action] is also called once immediately on timer registration.
## [param after] triggers once [param times] is exhausted.
func every(delay: Variant, action: Callable, times: int = 0, immediate: bool = false, after: Callable = _empty_callable, tag: StringName = _generate_tag()) -> StringName:
	_timers[tag] = {
		type = &"every",
		elapsed = 0.0,
		index = 0,
		unresolved_delay = delay,
		delay = _resolve_delay(delay),
		action = action,
		times = times,
		after = after,
		multiplier = 1.0,
	}
	if immediate:
		action.call()
	return tag


## Calls [param action] [param times] times every 'interval' seconds.
## The `interval` ramps from [param start_delay] to [param end_delay] based on the [param shape_method].
## The [param step_method] only reshapes the interior steps i.e., all but first and last steps.
## [param times] must always be >= 2.
## If [param immediate] is true, [param action] is also called once immediately on timer registration.
## [param after] triggers once [param times] is exhausted.
func every_step(start_delay: float, end_delay: float, times: int, action: Callable, immediate: bool = false, step_method: Callable = Callable(), after: Callable = _empty_callable, tag: StringName = _generate_tag()) -> StringName:
	if times < 2:
		push_error("The 'times' parameter must have a value >= 2.")
		return &""
	
	var step := (end_delay - start_delay) / float(times - 1)
	var delays: Array[float] = []
	delays.resize(times)
	for i in times:
		delays[i] = start_delay + i * step
	
	if step_method.is_valid():
		for i in range(1, times - 1):
			var normalized := i / float(times - 1)
			var eased: float = step_method.call(normalized)
			delays[i] = lerp(start_delay, end_delay, eased)
	
	_timers[tag] = {
		type = &"every_step",
		elapsed = 0.0,
		index = 0,
		delays = delays,
		action = action,
		times = times,
		after = after,
		multiplier = 1.0,
	}
	if immediate:
		action.call()
	return tag

#endregion


#region HELPERS

## Stops the timer with tag [param tag].
## If the timer is of type 'run', it also triggers its 'after'.
func cancel(tag: StringName) -> void:
	if not _timers.has(tag):
		push_error("Unknown tag '%s'." % tag)
		return
	
	var entry: Dictionary = _timers[tag]
	if entry.type == &"run":
		entry.after.call()
	
	_timers.erase(tag)
	finished.emit(tag)


## Resets the elapsed time of the timer with tag [param tag].
func reset(tag: StringName) -> void:
	if not _timers.has(tag):
		push_error("Unknown tag '%s'." % tag)
		return
	_timers[tag].elapsed = 0.0


## Sets whether the timer with tag [param tag] ignores 'Engine.time_scale'.
func set_unscaled(tag: StringName, value: bool = true) -> void:
	if not _timers.has(tag):
		push_error("Unknown tag '%s'." % tag)
		return
	
	_timers[tag].unscaled = value


## Returns whether the timer with tag [param tag] ignores 'Engine.time_scale'.
func get_unscaled(tag: StringName) -> bool:
	if not _timers.has(tag):
		push_error("Unknown tag '%s'." % tag)
		return false
	
	return _timers[tag].get("unscaled", false)


## Suspends the caller until the timer with tag [param tag] ends, either naturally or if cancelled.
## It is awaitable.
func wait_for(tag: StringName) -> void:
	while true:
		var finished_tag: StringName = await finished
		if finished_tag == tag:
			return


## Returns true if a timer with tag [param tag] is currently active.
func has_timer(tag: StringName) -> bool:
	return _timers.has(tag)


## Returns the tags of all currently active timers.
func get_active_tags() -> Array[StringName]:
	var tags: Array[StringName] = []
	tags.assign(_timers.keys())
	return tags


## Returns the type of the timer for tag.
## For example, &"every" or &"cooldown".
func get_type(tag: StringName) -> StringName:
	if not _timers.has(tag):
		push_error("Unknown tag '%s'." % tag)
		return &""
	
	return _timers[tag].type


## Returns the current 'delay' of a timer with tag [param tag].
## Valid for all timers except those of type 'run'.
func get_delay(tag: StringName) -> float:
	if not _timers.has(tag):
		push_error("Unknown tag '%s'." % tag)
		return -1.0
	
	var entry: Dictionary = _timers[tag]
	if entry.has("delay"):
		return entry.delay
	elif entry.has("delays"):
		return entry.delays[entry.index]
	else:
		push_error("Timer tagged '%s' of type '%s' does not have a 'delay'." % [tag, entry.type])
		return -1.0


## Returns the current iteration 'index' for a timer with tag [param tag].
## Only valid for timers of type 'every' or 'every_step'.
func get_times_index(tag: StringName) -> int:
	if not _timers.has(tag):
		push_error("Unknown tag '%s'." % tag)
		return -1
	
	var entry: Dictionary = _timers[tag]
	if not entry.has("index"):
		push_error("Timer tagged '%s' of type '%s' does not have an 'index'." % [tag, entry.type])
		return -1
	
	return entry.index


## Sets the delay [param multiplier] for a timer with tag [param tag].
## Only valid for timers of type 'cooldown', 'every', and 'every_step'.
func set_multiplier(tag: StringName, multiplier: float = 1.0) -> void:
	if not _timers.has(tag):
		push_error("Unknown tag '%s'." % tag)
		return
	
	var entry: Dictionary = _timers[tag]
	if not entry.has("multiplier"):
		push_error("Timer tagged '%s' of type '%s' does not have a 'multiplier'." % [tag, entry.type])
		return
	
	entry.multiplier = multiplier


## Returns the delay [param multiplier] for a timer with tag [param tag]. See [method set_multiplier].
func get_multiplier(tag: StringName) -> float:
	if not _timers.has(tag):
		push_error("Unknown tag '%s'." % tag)
		return -1.0
	
	var entry: Dictionary = _timers[tag]
	if not entry.has("multiplier"):
		push_error("Timer tagged '%s' of type '%s' does not have a 'multiplier'." % [tag, entry.type])
		return -1.0
	
	return entry.multiplier


## Returns 'elapsed' / 'delay' ratio for a timer with tag [param tag]. 
## The value will be between 0.0 and 1.0.
## Valid for all timers except those of type 'run'.
func get_progress_ratio(tag: StringName) -> float:
	if not _timers.has(tag):
		push_error("Unknown tag '%s'." % tag)
		return -1.0
 
	var entry: Dictionary = _timers[tag]
	if entry.has("delay"):
		return entry.elapsed / entry.delay
	elif entry.has("delays"):
		return entry.elapsed / entry.delays[entry.index]
	else:
		push_error("Timer tagged '%s' of type '%s' does not have a 'delay'." % [tag, entry.type])
		return -1.0


## Returns 'elapsed' and 'delay' for a timer with tag [param tag].
## The values are wrapped in a [Dictionary].
## Valid for all timers except those of type 'run'.
func get_progress(tag: StringName) -> Dictionary:
	if not _timers.has(tag):
		push_error("Unknown tag '%s'." % tag)
		return {}
 
	var entry: Dictionary = _timers[tag]
	if entry.has("delay"):
		return {elapsed = entry.elapsed, delay = entry.delay}
	elif entry.has("delays"):
		return {elapsed = entry.elapsed, delay = entry.delays[entry.index]}
	else:
		push_error("Timer tagged '%s' of type '%s' does not have a 'delay'." % [tag, entry.type])
		return {}

#endregion


#region PRIVATE HELPERS

## Resolves the [param delay] to a float.
## If [param delay] is an [Array], it returns a random float between the two values.
## If [param delay] is a [float], it simply returns that value.
func _resolve_delay(delay: Variant) -> float:
	if delay is Array:
		return randf_range(delay[0], delay[1])
	return float(delay)


## Generates a random 8-character StringName.
## Guaranteed to be unique among currently active timers.
func _generate_tag() -> StringName:
	var tag: StringName
	while true:
		var s := ""
		for i in 8:
			s += CHARACTERS[randi() % CHARACTERS.length()]
		tag = StringName(s)
		if not _timers.has(tag):
			break
	return tag

#endregion
