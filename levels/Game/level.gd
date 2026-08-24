extends Node3D

@export var _rooms: Array[Room]
@export var _dead_end: Node3D

var _stage: int = 0

func _enter_tree() -> void:
    if SignalBus.on_enter_room.connect(_handle_enter_room) != OK:
        push_error("Failed to connect enter room")

    if SignalBus.on_leave_room.connect(_handle_exit_room) != OK:
        push_error("Failed to connect exit room")

func _get_next_room(current: Room) -> Room:
    for room: Room in _rooms:
        if room && room != current:
            return room
    return null

func _handle_enter_room(room: Room, direction: Vector2i) -> void:
    for r: Room in _rooms:
        r.visible = room == r

    if _dead_end:
        _dead_end.visible = true
        room.place_deadend(_dead_end, direction)

func _handle_exit_room(room: Room, correct: bool, direction: Vector2i) -> void:
    if correct:
        _stage += 1
    else:
        _stage = 0

    var next: Room = _get_next_room(room)
    next.global_position = room.neighbour_global_position(direction)
    next.visible = true

    if _dead_end:
        _dead_end.visible = false
        _dead_end.global_position = room.global_position + Vector3(100.0, -10.0, 100.0)
