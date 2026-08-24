extends Node3D
class_name Room

enum Phase { PLACED, ENTERED, EXITED }

@export var doors: Array[RoomDoor]
@export var correct_door: RoomDoor
@export var correct_entry_offset: Vector2i
@export var _room_number: MeshInstance3D

var solved_times: int
var attempted_times: int
var solved: bool:
    get():
        return solved_times > 0

var _phase: Phase = Phase.PLACED
var _entry_door: RoomDoor

func _enter_tree() -> void:
    for door: RoomDoor in doors:
        if door.opened.connect(_handle_door_opened.bind(door)) != OK:
            push_error("Failed to connect door opened")
        if door.closed.connect(_handle_door_closed.bind(door)) != OK:
            push_error("Failed to connect door closed")

func neighbour_global_position(direction: Vector2i) -> Vector3:
    match direction:
        Vector2i(-1, 0):
            return global_position + Vector3(-12.0, 0.0, -6.0)
        Vector2i(1, 0):
            return global_position + Vector3(12.0, 0.0, 6.0)
        Vector2i(0, -1):
            return global_position + Vector3(6.0, 0.0, -12.0)
        Vector2i(0, 1):
            return global_position + Vector3(-6.0, 0.0, 12.0)
        _:
            push_error("%s not a valid direction from %s" % [direction, name])
            return global_position

func initiallize() -> void:
    _phase = Phase.PLACED
    _entry_door = null

func place_deadend(dead_end: Node3D, direction: Vector2i) -> void:
    if dead_end == null:
        push_error("Room %s has no dead-end" % [name])
        return

    match direction:
        Vector2i(0, 1):
            dead_end.global_position = global_position + Vector3(-6.0, 0.0, 9.5)
            dead_end.global_rotation = Vector3(0.0, -PI * 0.5, 0.0)
        Vector2i(0, -1):
            dead_end.global_position = global_position + Vector3(6.0, 0.0, -9.5)
            dead_end.global_rotation = Vector3(0.0, PI * 0.5, 0.0)
        Vector2i(1, 0):
            dead_end.global_position = global_position + Vector3(9.5, 0.0, 6.0)
            dead_end.global_rotation = Vector3(0.0, 0.0, 0.0)
        Vector2i(-1, 0):
            dead_end.global_position = global_position + Vector3(-9.5, 0.0, -6.0)
            dead_end.global_rotation = Vector3(0.0, PI, 0.0)
        _:
            push_error("Invalid door direction %s in room %s" % [direction, name])

func _door_direction(door: RoomDoor) -> Vector2i:
    var x: float = door.global_position.x - global_position.x
    var y: float = door.global_position.z - global_position.z
    if abs(y) > abs(x):
        return Vector2i(0, signi(int(y)))
    if x > 0:
        return Vector2i(1, 0)
    return Vector2i(-1, 0)

func _is_correct_door(door: RoomDoor) -> bool:
    if correct_door:
        return door == correct_door
    return _door_direction(door) - _door_direction(_entry_door) == correct_entry_offset;

func _handle_door_opened(_room_side: bool, door: RoomDoor) -> void:
    if _entry_door == null:
        _entry_door = door
        SignalBus.on_enter_room.emit(self, _door_direction(door))
        attempted_times += 1

func _handle_door_closed(room_side: bool, door: RoomDoor) -> void:
    if !room_side && _phase == Phase.PLACED:
        return

    _phase = Phase.ENTERED if room_side else Phase.EXITED
    if !room_side:
        var correct: bool = _is_correct_door(door)
        SignalBus.on_leave_room.emit(self, correct, _door_direction(door))
        if correct:
            solved_times += 1

func set_room_number(material: Material) -> void:
    (_room_number.mesh as QuadMesh).material = material
