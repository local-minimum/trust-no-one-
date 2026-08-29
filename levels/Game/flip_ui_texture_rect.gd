@tool
extends TextureRect
class_name FlipUITextureRect

@export var textures: Array[Texture2D]
@export_range(0.01, 5.0) var view_time: float = 0.25


func _ready() -> void:
    if !textures.is_empty():
        texture = textures[0]
    remaining = view_time

var idx: int = 0
var remaining: float

func _process(delta: float) -> void:
    if !visible || textures.size() == 0:
        return

    remaining -= delta
    if remaining <= 0.0:
        remaining += view_time

        idx += 1
        idx %= textures.size()

        texture = textures[idx]

var _fade_tween: Tween

func fade_out(time: float) -> void:
    if _fade_tween && _fade_tween.is_running():
        _fade_tween.kill()

    if time > 1.0:
        await get_tree().create_timer(time - 1.0).timeout

    _fade_tween = create_tween()
    _fade_tween.tween_property(self, "modulate:a", 0.0, minf(1.0, time))
    _fade_tween.finished.connect(
        func () -> void:
            visible = false
            ,
    )
