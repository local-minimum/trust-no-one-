@tool
extends EditorPlugin


func _enter_tree() -> void:
	add_autoload_singleton("GameTrace", "res://addons/gametrace/game_trace.gd")


func _exit_tree() -> void:
	remove_autoload_singleton("GameTrace")
