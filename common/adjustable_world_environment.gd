extends WorldEnvironment

func _enter_tree() -> void:
    if environment && !VideoSettings.adjustable_environments.has(environment):
        VideoSettings.adjustable_environments.append(environment)

func _ready() -> void:
    if environment:
        environment.adjustment_enabled = true
        environment.adjustment_brightness = VideoSettings.brightness

func _exit_tree() -> void:
    if environment:
        VideoSettings.adjustable_environments.erase(environment)
