extends Node3D
class_name Level

@export_file("*.mp3") var _music: String
@export_file("*.mp3") var _laugh: String

@export var _force_order: Array[Room]
@export var _easy_rooms: Array[Room]
@export var _medium_rooms: Array[Room]
@export var _hard_rooms: Array[Room]
@export var _pre_ending: Room
@export var _ending_up: Room
@export var _ending_down: Room
@export var _ending_left: Room
@export var _ending_right: Room
@export var _dead_end: Node3D
@export var _number_mats: Array[Material]

var _stage: int = 0:
    set(value):
        _rooms_visited += 1
        print_debug("Progress %s -> %s (%s)" % [_stage, value, _rooms_visited])
        if _stage == value:
            push_warning("Updating stage to same stage %s!" % value)
        _stage = value

var _rooms_visited: int
var _next_stage: int
var _current_room: Room
var _room_history: Array[Room]
var _first_room: bool = true

func _enter_tree() -> void:
    if SignalBus.on_enter_room.connect(_handle_enter_room) != OK:
        push_error("Failed to connect enter room")

    if SignalBus.on_leave_room.connect(_handle_exit_room) != OK:
        push_error("Failed to connect exit room")

func _ready() -> void:
    AudioHub.play_music(_music)
    _disable_all_rooms()

    var start_room: Room = _get_next_room(null, Vector2i.ZERO)
    start_room.global_position = Vector3.ZERO
    start_room.visible = true
    start_room.set_process(true)
    start_room.set_room_number(_number_mats[_stage])
    _room_history.append(start_room)


func _disable_room(room: Room) -> void:
    room.global_position = Vector3(0.0, -10.0, 0.0)
    room.visible = false
    room.set_process(false)

func _disable_all_rooms() -> void:
    for room: Room in _easy_rooms:
        _disable_room(room)
    for room: Room in _medium_rooms:
        _disable_room(room)
    for room: Room in _hard_rooms:
        _disable_room(room)

    _disable_room(_pre_ending)

func _get_next_room(current: Room, direction: Vector2i) -> Room:
    var options: Array[Room]
    var _rooms: Array[Room]

    if _stage < 2:
        _rooms = _easy_rooms
    elif _stage < 4:
        _rooms = _medium_rooms
    elif _stage == 5:
        _rooms = _easy_rooms if randf() < 0.5 else _medium_rooms
    elif _stage < 7:
        _rooms = _hard_rooms
    elif current == _pre_ending:
        match direction:
            Vector2i.UP:
                return _ending_up
            Vector2i.DOWN:
                return _ending_down
            Vector2i.LEFT:
                return _ending_left
            Vector2i.RIGHT:
                return _ending_right
            _:
                push_error("Illegal direction leaving %s to the %s" % [current, direction])
                return _pre_ending
    else:
        return _pre_ending

    if _rooms_visited < _force_order.size():
        return _force_order[_rooms_visited]

    for room: Room in _rooms:
        if room && room != current && !_room_history.has(room):
            options.append(room)

    if options.is_empty():
        for room: Room in _rooms:
            if room != current:
                _room_history.erase(room)
                options.append(room)

    if options.is_empty():
        return _rooms.pick_random()

    return options.pick_random()

func _handle_enter_room(room: Room, direction: Vector2i) -> void:
    if _current_room != room:
        print_debug("Enter room new room %s, current was %s" % [room, _current_room])
        if _current_room:
            _disable_room(_current_room)

        _current_room = room

        _room_history.append(_current_room)

        if _dead_end:
            _dead_end.visible = true
            _dead_end.set_process(true)
            room.place_deadend(_dead_end, direction)

        if !_first_room && _next_stage <= _stage:
            AudioHub.play_sfx(_laugh, 0.8, AudioHub.Bus.SFX)

        _first_room = false
        _stage = _next_stage
        room.set_room_number(_number_mats[_stage])

func _handle_exit_room(room: Room, correct: bool, direction: Vector2i) -> void:
    print_debug("Exiting room %s (current %s) correct=%s, stage=%s, next_stage=%s (before update)" % [room, _current_room, correct, _stage, _next_stage])
    if correct:
        _next_stage = _stage + 1
    else:
        _next_stage = 0

    var next: Room = _get_next_room(room, direction)
    if next == null:
        return

    if next == room:
        push_error("Trying to go back to same room!")

    next.global_position = room.neighbour_global_position(direction)
    next.visible = true
    next.set_process(true)
    next.initiallize()

    if _dead_end:
        _dead_end.visible = false
        _dead_end.set_process(false)
        _dead_end.global_position = room.global_position + Vector3(100.0, -10.0, 100.0)
