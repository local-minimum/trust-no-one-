extends CanvasLayer


@export var title: Control
@export var player: HubPlayerCharacter

var _done: bool

func _ready() -> void:
    player.look_locked = true

func _input(event: InputEvent) -> void:
    if _done:
        return

    if (
        event.is_action("player_forward") ||
        event.is_action("player_backward") ||
        event.is_action("player_strafe_left") ||
        event.is_action("player_strafe_right")
    ):
        _done = true
        player.look_locked = false
        var t: Tween = create_tween()
        t.tween_property(title, "modulate:a", 0.0, 1.0)
        t.finished.connect(
            func() -> void:
                title.visible = false
                ,
        )
