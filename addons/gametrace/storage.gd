class_name GameTraceStorage
extends RefCounted
## Persistent storage for the GameTrace client ID using Godot's ConfigFile.
## Data is stored at user://gametrace.cfg so it persists across game launches.

const STORAGE_PATH := "user://gametrace.cfg"
const SECTION := "gametrace"
const CLIENT_ID_KEY := "client_id"


static func get_client_id() -> String:
	## Load the stored client ID, or return an empty string if not found.
	var config := ConfigFile.new()
	var err := config.load(STORAGE_PATH)
	if err != OK:
		return ""
	return config.get_value(SECTION, CLIENT_ID_KEY, "")


static func set_client_id(id: String) -> void:
	## Save the client ID to persistent storage.
	var config := ConfigFile.new()
	config.load(STORAGE_PATH)  # Load existing values (OK if file doesn't exist)
	config.set_value(SECTION, CLIENT_ID_KEY, id)
	config.save(STORAGE_PATH)
