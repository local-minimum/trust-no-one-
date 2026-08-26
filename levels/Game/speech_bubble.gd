extends MeshInstance3D
class_name SpeechBubble

@export_multiline() var wiggly_text: String:
    set(value):
        wiggly_text = value
        _bold_wave()

@export var label1: Label3D
@export var label2: Label3D
@export_range(1, 20) var wave_length: int = 3
@export_range(0.01, 10.0) var speed: float = 1.0;

var _inited: bool

func _ready() -> void:
    _inited = true
    _bold_wave()

var last_update: float
var start_idx: int = 0

func _process(delta: float) -> void:
    last_update += delta
    if last_update < 1.0 / speed:
        return

    last_update -= 1.0 / speed
    start_idx += 1
    start_idx %= (wave_length + 1)

    _bold_wave()


func _spacify(s: String) -> String:
    var ret: String = " ".repeat(s.length())
    var i: int = s.find("\n")
    while i > -1:
        ret[i] = '\n'
        i = s.find("\n", i + 1)
    return ret

func _bold_wave() -> void:
    if !_inited:
        return
    var parts1: Array[String] = []
    var parts2: Array[String] = []
    var bold: bool = false
    var from: int = start_idx
    var l: int = wiggly_text.length()
    var p: String = wiggly_text.substr(0, start_idx )
    parts1.append(p)
    parts2.append(_spacify(p))

    while from < l:
        p = wiggly_text.substr(from, wave_length)
        if bold:
            parts1.append(p)
            parts2.append(_spacify(p))
        else:
            parts2.append(p)
            parts1.append(_spacify(p))
        bold = !bold
        from += wave_length

    label1.text = "".join(PackedStringArray(parts1))
    label2.text = "".join(PackedStringArray(parts2))
