extends Node3D

@export var _start_room: Array[Room]
@export var _rooms: Array[Room]
@export var _dead_end: Node3D
@export var _number_mats: Array[Material]

var _stage: int = 0:
    set(value):
        print_debug("Progress %s -> %s" % [_stage, value])
        _stage = value
var _next_stage: int
var _current_room: Room

func _enter_tree() -> void:
    if SignalBus.on_enter_room.connect(_handle_enter_room) != OK:
        push_error("Failed to connect enter room")

    if SignalBus.on_leave_room.connect(_handle_exit_room) != OK:
        push_error("Failed to connect exit room")

func _ready() -> void:
    for room: Room in _rooms:
        room.global_position = Vector3(0.0, -10.0, 0.0)
        room.visible = false
        room.set_process(false)

    var start_room: Room = _start_room.pick_random()
    start_room.global_position = Vector3.ZERO
    start_room.visible = true
    start_room.set_process(true)
    start_room.set_room_number(_number_mats[_stage])

func _get_next_room(current: Room) -> Room:
    for room: Room in _rooms:
        if room && room != current:
            return room
    return null

func _handle_enter_room(room: Room, direction: Vector2i) -> void:
    if _current_room != room:
        if _current_room:
            _current_room.visible = false
            _current_room.set_process(false)

        _current_room = room

        if _dead_end:
            _dead_end.visible = true
            _dead_end.set_process(true)
            room.place_deadend(_dead_end, direction)

        _stage = _next_stage
        room.set_room_number(_number_mats[_stage])

func _handle_exit_room(room: Room, correct: bool, direction: Vector2i) -> void:
    if correct:
        _next_stage = _stage + 1
    else:
        _next_stage = 0

    var next: Room = _get_next_room(room)
    next.global_position = room.neighbour_global_position(direction)
    next.visible = true
    next.set_process(true)
    next.initiallize()

    if _dead_end:
        _dead_end.visible = false
        _dead_end.set_process(false)
        _dead_end.global_position = room.global_position + Vector3(100.0, -10.0, 100.0)
