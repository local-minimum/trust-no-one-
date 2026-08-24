extends RichTextLabel
class_name WigglyText

@export_multiline() var wiggly_text: String:
    set(value):
        if !value.contains("[b]"):
            wiggly_text = value
        text = value

@export_range(1, 20) var wave_length: int = 3
@export_range(0.01, 10.0) var speed: float = 1.0;

func _ready() -> void:
    bbcode_enabled = true
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

func _bold_wave() -> void:
    var parts: Array[String] = []
    parts.append(wiggly_text.substr(0, start_idx))
    var bold: bool = true
    var from: int = start_idx
    var l: int = wiggly_text.length()
    while from < l:
        if bold:
            parts.append("[b]%s[/b]" % wiggly_text.substr(from, wave_length))
        else:
            parts.append(wiggly_text.substr(from, wave_length))
        bold = !bold
        from += wave_length

    text = "".join(PackedStringArray(parts))
