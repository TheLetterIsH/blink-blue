extends Node


func get_arena() -> Arena:
	return get_tree().get_first_node_in_group(&"arena")


func get_player() -> Player:
	return get_tree().get_first_node_in_group(&"player")


func get_hud() -> HUD:
	return get_tree().get_first_node_in_group(&"hud")
