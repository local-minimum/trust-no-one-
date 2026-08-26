extends MeshInstance3D

@export var bubble: SpeechBubble
@export var detection_area: Area3D
@export_file("*.mp3") var speach_sound: String
@export_multiline() var texts: Array[String]
@export var speech_speed: float = 5.5

var _showing: bool
var talking: bool

func _enter_tree() -> void:
    if detection_area.body_entered.connect(_handle_body_enter) != OK:
        push_error("Failed to connect body entered")
    if detection_area.body_exited.connect(_handle_body_exit) != OK:
        push_error("Failed to connect body exited")

func _ready() -> void:
    bubble.visible = false
    set_process(false)

var text_idx: int = -1
var next_text: float

func _handle_body_enter(_b: Node3D) -> void:
    _showing = true
    if !bubble.visible:
        text_idx = -1
        _show_next_text(true)
        bubble.visible = true
        set_process(true)
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
        set_process(false)

func _show_next_text(force: bool = false) -> void:
    text_idx += 1
    if text_idx >= texts.size():
        text_idx = 0
    next_text = speech_speed
    if force || texts.size() > 1:
        bubble.wiggly_text = "" if texts.is_empty() else texts[text_idx]

func _process(delta: float) -> void:
    next_text -= delta
    if next_text <= 0.0:
        _show_next_text()
