extends Area3D
class_name DialogTrigger

@export var dialog: SubbedAudio
@export var play_mode: AudioHub.QueueBehaviour
@export var one_shot: bool = true
@export var require_no_dialog: bool
@export var require_looking_at: CollisionObject3D

var played: bool

func _enter_tree() -> void:
    if body_entered.connect(_body_enter) != OK:
        push_error("Failed to connect body enter")
    if body_exited.connect(_body_exit) != OK:
        push_error("Failed to connect body exit")
    if require_looking_at:

        if SignalBus.on_pointer_over.connect(_handle_looking) != OK:
            push_error("Failed to connect handle looking")

var _looking: bool
var _inside: bool

func _handle_looking(focused: CollisionObject3D) -> void:
    _looking = focused == require_looking_at
    if _looking:
        _check_play()

func _body_enter(_body: Node3D) -> void:
    _inside = true
    _check_play()

func _body_exit(_boyd: Node3D) -> void:
    _inside = false

func _check_play() -> void:
    if !_inside || dialog == null || one_shot && played:
        return

    if require_no_dialog && AudioHub.dialogue_busy:
        return

    if require_looking_at && !_looking:
        return

    play()

## This plays the dialog no matter what
func play() -> void:
    played = true
    dialog.play(null, null, play_mode)
