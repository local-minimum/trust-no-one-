extends Node3D

@export var _room: Room
@export var _deadends: Array[Node3D]
@export var _colliders: Dictionary[Node3D, Vector3]
@export var _halls: Array[Node3D]

@export var _end_bg: ColorRect
@export var _end_end_text: Control
@export var _end_thanks_text: Control


var _trapped: bool

func _enter_tree() -> void:
    _end_bg.visible = false
    _end_end_text.visible = false
    _end_thanks_text.visible = false

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
            var t: Tween = create_tween()
            var c: Color = _end_bg.color
            _end_bg.color = Color(c, 0)
            _end_bg.visible = true
            t.tween_property(_end_bg, "color", c, 1.0)
            await get_tree().create_timer(2).timeout

            _end_end_text.visible = true

            await get_tree().create_timer(4).timeout

            _end_thanks_text.visible = true

            await get_tree().create_timer(10).timeout

            AudioHub.clear_all_dialogues()
            AudioHub.clear_callbacks(AudioHub.Bus.MASTER)
            AudioHub.clear_callbacks(AudioHub.Bus.MUSIC)
            AudioHub.clear_callbacks(AudioHub.Bus.SFX)
            AudioHub.clear_callbacks(AudioHub.Bus.SFX_ALT)
            AudioHub.clear_callbacks(AudioHub.Bus.DIALGUE)

            get_tree().reload_current_scene()


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
