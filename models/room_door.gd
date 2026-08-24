extends Node3D
class_name RoomDoor

signal opened(room_side: bool)
signal closed(room_side: bool)

@export var room_area: Area3D
@export var hall_area: Area3D
@export var open_angle: float = -PI * 0.8
@export var transition_duration: float = 1.0

var _opened: bool = false
var _active_area: Area3D
var _tween: Tween

func _enter_tree() -> void:
    if room_area:
        if room_area.body_entered.connect(_enter_area.bind(room_area)) != OK:
            push_error("Failed to connect entered room area")
        if room_area.body_exited.connect(_exit_area.bind(room_area)) != OK:
            push_error("Failed to connect exited room area")
    if hall_area:
        if hall_area.body_entered.connect(_enter_area.bind(hall_area)) != OK:
            push_error("Failed to connect entered hall area")
        if hall_area.body_exited.connect(_exit_area.bind(hall_area)) != OK:
            push_error("Failed to connect exited hall area")

func _enter_area(_b: Node3D, a: Area3D) -> void:
    _active_area = a
    if !_opened:
        _opened = true
        if _tween && _tween.is_running():
            _tween.kill()
        _tween = create_tween()
        _tween.tween_property(self, "rotation:y", open_angle if a == hall_area else -open_angle, transition_duration);

        opened.emit(a == room_area)

func _exit_area(_b: Node3D, a: Area3D) -> void:
    if _active_area == a && _opened:
        _opened = false
        _active_area = null
        if _tween && _tween.is_running():
            _tween.kill()
        _tween = create_tween()
        _tween.tween_property(self, "rotation:y", 0.0, transition_duration);

        closed.emit(a == room_area)
