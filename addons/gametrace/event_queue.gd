class_name GameTraceEventQueue
extends Node
## Manages event batching and auto-flush scheduling.
## Events are queued locally and sent in batches via the transport layer.

signal flush_started()
signal flush_completed(result: Dictionary)

var _queue: Array[Dictionary] = []
var _config: GameTraceConfig
var _transport: GameTraceTransport
var _flush_timer: Timer
var _flushing: bool = false


func _ready() -> void:
    _flush_timer = Timer.new()
    _flush_timer.one_shot = false
    _flush_timer.timeout.connect(_on_flush_timer)
    add_child(_flush_timer)


func configure(config: GameTraceConfig, transport: GameTraceTransport) -> void:
    _config = config
    _transport = transport
    _transport.request_completed.connect(_on_transport_completed)
    _flush_timer.wait_time = config.flush_interval
    _flush_timer.start()


func push(event: Dictionary) -> void:
    ## Add an event to the queue. Drops oldest events if the queue is full.
    if _queue.size() >= _config.max_queue_size:
        _queue.pop_front()
        if _config.debug:
            print("[GameTrace] Queue full — dropped oldest event")

    _queue.append(event)

    if _queue.size() >= _config.batch_size:
        flush()


func flush() -> void:
    ## Send the next batch of queued events. No-op if already flushing or queue is empty.
    if _flushing or _queue.is_empty():
        return

    _flushing = true
    flush_started.emit()

    var count := mini(_config.batch_size, 100)
    count = mini(count, _queue.size())
    var batch: Array[Dictionary] = []
    for i in range(count):
        batch.append(_queue.pop_front())

    _transport.send({"events": batch})


func get_queue_size() -> int:
    return _queue.size()


func stop() -> void:
    ## Stop the auto-flush timer.
    if _flush_timer:
        _flush_timer.stop()


func _on_flush_timer() -> void:
    flush()


func _on_transport_completed(result: Dictionary) -> void:
    if not result.get("success", false):
        # Re-enqueue failed events at the front
        var failed_events: Array = result.get("events", [])
        for i in range(failed_events.size() - 1, -1, -1):
            _queue.push_front(failed_events[i])

    _flushing = false
    flush_completed.emit(result)
