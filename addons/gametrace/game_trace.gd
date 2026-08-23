extends Node
## Game Trace analytics SDK for Godot 4.x.
##
## Add this script as an Autoload (Project > Project Settings > Autoload) with
## the name "GameTrace". Then call GameTrace.initialize() in your main scene's
## _ready() to start tracking events.

## Emitted after a flush completes. The result dictionary contains:
## { success: bool, accepted: int } on success, or { success: bool, error: String } on failure.
signal flush_completed(result: Dictionary)

## Emitted each time an event is queued via track().
signal event_tracked(event_name: String)

## Emitted when an SDK error occurs.
signal error_occurred(message: String)

var _config: GameTraceConfig
var _transport: GameTraceTransport
var _queue: GameTraceEventQueue
var _client_id: String
var _session_id: String
var _initialized: bool = false
var _shutdown: bool = false


func initialize(config: GameTraceConfig) -> void:
    ## Set up the SDK with your project credentials. Call this once in _ready().
    if _initialized:
        if config.debug:
            print("[GameTrace] Already initialized")
        return

    _config = config

    if _config.api_key.is_empty() or _config.project_id.is_empty():
        var msg := "GameTrace: api_key and project_id are required"
        push_error(msg)
        error_occurred.emit(msg)
        return

    # Session ID — fresh each time the game starts
    _session_id = GameTraceUtils.generate_uuid()

    # Client ID — load from storage or generate a new one
    _client_id = GameTraceStorage.get_client_id()
    if _client_id.is_empty():
        _client_id = GameTraceUtils.generate_uuid()
        GameTraceStorage.set_client_id(_client_id)

    # Create transport and queue as child nodes
    _transport = GameTraceTransport.new()
    _transport.name = "GameTraceTransport"
    add_child(_transport)
    _transport.configure(_config)

    _queue = GameTraceEventQueue.new()
    _queue.name = "GameTraceEventQueue"
    add_child(_queue)
    _queue.configure(_config, _transport)
    _queue.flush_completed.connect(_on_flush_completed)

    _initialized = true

    if _config.debug:
        print("[GameTrace] Initialized — client=%s session=%s" % [_client_id, _session_id])


func track(event_name: String, properties: Dictionary = {}) -> void:
    ## Queue an analytics event. Events are batched and sent automatically.
    if not _initialized:
        push_warning("GameTrace: not initialized — call initialize() first")
        return
    if _shutdown:
        return

    var event: Dictionary = {
        "projectId": _config.project_id,
        "clientId": _client_id,
        "sessionId": _session_id,
        "eventName": event_name,
        "timestamp": GameTraceUtils.iso_timestamp(),
    }

    if not properties.is_empty():
        event["properties"] = properties

    if _config.auto_capture:
        var ctx := GameTraceContext.capture()
        if not _config.app_version.is_empty():
            ctx["appVersion"] = _config.app_version
        event["context"] = ctx

    _queue.push(event)
    event_tracked.emit(event_name)

    if _config.debug:
        print("[GameTrace] Tracked: %s" % event_name)


func identify(client_id: String) -> void:
    ## Override the auto-generated client ID with a known player identifier.
    ## The new ID is persisted and used for all subsequent events.
    if client_id.is_empty():
        return
    _client_id = client_id
    GameTraceStorage.set_client_id(_client_id)

    if _config and _config.debug:
        print("[GameTrace] Identified: %s" % _client_id)


func flush() -> void:
    ## Immediately send all queued events.
    ## Listen to the flush_completed signal for the result.
    if not _initialized or _shutdown:
        return
    _queue.flush()


func shutdown() -> void:
    ## Flush remaining events, stop timers, and prevent further tracking.
    ## This is called automatically when the game window is closed.
    if _shutdown:
        return
    _shutdown = true

    if _initialized and _queue:
        _queue.stop()
        _queue.flush()

    if _config and _config.debug:
        print("[GameTrace] Shut down")


func get_client_id() -> String:
    return _client_id


func get_session_id() -> String:
    return _session_id


func is_initialized() -> bool:
    return _initialized


func _notification(what: int) -> void:
    if what == NOTIFICATION_WM_CLOSE_REQUEST:
        shutdown()


func _on_flush_completed(result: Dictionary) -> void:
    flush_completed.emit(result)
