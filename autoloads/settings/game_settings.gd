extends Node
class_name _GameSettings

var _considered_input_method: BindingSettings.InputMethod

func _enter_tree() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    GeneralSettings.initialize()
    AudioSettings.initialize()
    BindingSettings.initialize()
    VideoSettings.initialize()
    PseudoSaveSettings.initialize()

func reset_defaults() -> void:
    GeneralSettings.reset_default()
    AudioSettings.reset_default()
    BindingSettings.reset_default()
    VideoSettings.reset_default()
    PseudoSaveSettings.reset_default()

func _ready() -> void:
    _considered_input_method = BindingSettings.active_input_method
    GameAnalytics.initialize(_load_settings())

func _load_settings(file_path: String = "res://settings.json") -> Dictionary:
    if !FileAccess.file_exists(file_path):
        push_warning("Settings file '%s' does not exist" % file_path)
        return {}

    var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)

    if file == null:
        push_error("Could not open file at '%s' with read permissions" % file_path)
        return {}

    var json: JSON = JSON.new()
    if json.parse(file.get_line()) == OK:
        return json.data

    push_error("Failed to parse json in '%s'" % file_path)
    return {}


func _input(event: InputEvent) -> void:
    _unhandled_input(event)

func _unhandled_input(event: InputEvent) -> void:
    if BindingSettings.is_valid_action_event(event, BindingSettings.InputMethod.KEYBOARD_AND_MOUSE, true):
        _consider_switch_to(BindingSettings.InputMethod.KEYBOARD_AND_MOUSE)
    elif BindingSettings.is_valid_action_event(event, BindingSettings.InputMethod.JOYPAD):
        _consider_switch_to(BindingSettings.InputMethod.JOYPAD)

func _consider_switch_to(im: BindingSettings.InputMethod) -> void:
    if im == _considered_input_method:
        return

    _considered_input_method = im
    await get_tree().create_timer(0.1).timeout
    if im == _considered_input_method:
        BindingSettings.active_input_method = im
