extends Node3D

@export var _room: Room
@export var _deadends: Array[Node3D]
@export var _colliders: Dictionary[Node3D, Vector3]
@export var _halls: Array[Node3D]

var _trapped: bool

func  _ready() -> void:
    for dead: Node3D in _deadends:
        dead.visible = false

    for door: RoomDoor in _room.find_children("", "RoomDoor"):
        if door.opened.connect(_handle_open.bind(door)) != OK:
            push_error("Failed to connedct door opened")
        if door.closed.connect(_handle_close.bind(door)) != OK:
            push_error("Failed to connect door closed")
        _all_doors.append(door)

var _all_doors: Array[RoomDoor]
var _checked_doors: Array[RoomDoor]

func _handle_open(room_side: bool, door: RoomDoor) -> void:
    if !room_side:
        return

    if !_checked_doors.has(door):
        _checked_doors.append(door)

        if _checked_doors.size() == _all_doors.size():
            push_error("End screen")

func _handle_close(room_side: bool, _door: RoomDoor) -> void:
    if _trapped || !room_side:
        return

    _trapped = true
    for dead: Node3D in _deadends:
        dead.visible = true

    for hall: Node3D in _halls:
        hall.visible = false

    for col: Node3D in _colliders:
        col.position = _colliders[col]
