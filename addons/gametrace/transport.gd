class_name GameTraceTransport
extends Node
## Handles HTTP communication with the Game Trace API.
## Uses Godot's HTTPRequest node for async, non-blocking requests.

const DEFAULT_ENDPOINT = "https://gametrace.io/api/v1/events"

signal request_completed(result: Dictionary)

var _config: GameTraceConfig
var _http_request: HTTPRequest
var _pending_payload: Dictionary


func _ready() -> void:
	_http_request = HTTPRequest.new()
	_http_request.request_completed.connect(_on_request_completed)
	add_child(_http_request)


func configure(config: GameTraceConfig) -> void:
	_config = config


func send(payload: Dictionary) -> void:
	## Send a batch payload to the API. Emits request_completed when done.
	if not _config:
		push_error("GameTraceTransport: not configured")
		request_completed.emit({"success": false, "error": "Transport not configured"})
		return

	_pending_payload = payload
	var json_string := JSON.stringify(payload)
	var headers := PackedStringArray([
		"Content-Type: application/json",
		"X-API-Key: %s" % _config.api_key,
	])

	var url: String = _config.endpoint if not _config.endpoint.is_empty() else DEFAULT_ENDPOINT
	var err := _http_request.request(url, headers, HTTPClient.METHOD_POST, json_string)
	if err != OK:
		if _config.debug:
			print("[GameTrace] HTTP request failed to start: %s" % error_string(err))
		request_completed.emit({
			"success": false,
			"error": "Request failed: %s" % error_string(err),
			"events": payload.get("events", []),
		})


func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS:
		if _config and _config.debug:
			print("[GameTrace] Request error (result=%d)" % result)
		request_completed.emit({
			"success": false,
			"error": "HTTP error (result=%d)" % result,
			"events": _pending_payload.get("events", []),
		})
		return

	if response_code < 200 or response_code >= 300:
		var error_text := body.get_string_from_utf8()
		if _config and _config.debug:
			print("[GameTrace] API error %d: %s" % [response_code, error_text])
		request_completed.emit({
			"success": false,
			"error": "HTTP %d: %s" % [response_code, error_text],
			"events": _pending_payload.get("events", []),
		})
		return

	var response_text := body.get_string_from_utf8()
	var json := JSON.new()
	var parse_err := json.parse(response_text)
	var accepted := 0

	if parse_err == OK and json.data is Dictionary:
		accepted = json.data.get("accepted", 0)

	if _config and _config.debug:
		print("[GameTrace] Flush OK — accepted %d events" % accepted)

	request_completed.emit({"success": true, "accepted": accepted})
