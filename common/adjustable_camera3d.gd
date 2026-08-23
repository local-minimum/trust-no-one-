extends Camera3D

func _enter_tree() -> void:
    if SignalBus.on_update_fov.connect(_handle_new_fov) != OK:
        push_error("Failed to connect update fov")

func _ready() -> void:
    fov = VideoSettings.field_of_view

func _handle_new_fov(new_fov: float) -> void:
    fov = new_fov
