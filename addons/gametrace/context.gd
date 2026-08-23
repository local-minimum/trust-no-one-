class_name GameTraceContext
extends RefCounted
## Captures Godot engine and device context for analytics events.
## Maps to the EventContext fields expected by the Game Trace API.


static func capture() -> Dictionary:
	## Return a dictionary of auto-captured context fields.
	var version_info := Engine.get_version_info()
	var screen_size := DisplayServer.screen_get_size()
	var tz := Time.get_time_zone_from_system()

	return {
		"platform": OS.get_name(),
		"userAgent": "Godot/%s.%s.%s.%s" % [
			version_info.major, version_info.minor,
			version_info.patch, version_info.status,
		],
		"screenWidth": screen_size.x,
		"screenHeight": screen_size.y,
		"language": OS.get_locale_language(),
		"timezone": tz.get("name", str(tz.get("bias", 0))),
		"deviceType": _detect_device_type(),
		"sdkName": "godot",
		"sdkVersion": "0.1.0",
	}


static func _detect_device_type() -> String:
	var os_name := OS.get_name()
	if os_name in ["Android", "iOS"]:
		return "mobile"
	return "desktop"
