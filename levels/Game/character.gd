extends MeshInstance3D

@export var bubble: Node3D
@export var detection_area: Area3D
@export_file("*.mp3") var speach_sound: String

var _showing: bool
var talking: bool

func _enter_tree() -> void:
    if detection_area.body_entered.connect(_handle_body_enter) != OK:
        push_error("Failed to connect body entered")
    if detection_area.body_exited.connect(_handle_body_exit) != OK:
        push_error("Failed to connect body exited")

func _ready() -> void:
    bubble.visible = false

func _handle_body_enter(_b: Node3D) -> void:
    _showing = true
    if !bubble.visible:
        bubble.visible = true
        if speach_sound && !talking:
            talking = true
            AudioHub.play_dialogue(speach_sound, null, _speach_over, AudioHub.QueueBehaviour.IGNORE_QUEUE)

func _speach_over(_success: bool) -> void:
    talking = false

func _handle_body_exit(_b: Node3D) -> void:
    _showing = false
    await get_tree().create_timer(0.5).timeout
    if !_showing:
        bubble.visible = false
