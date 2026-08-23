class_name VideoSettings

const _VIDEO_ROOT_KEY: String = "video."
const _WINDOW_MODE: String = "%swindow_mode" % [_VIDEO_ROOT_KEY]
const _BORDERLESS: String = "%sborderless" % [_VIDEO_ROOT_KEY]
const _SCREEN: String = "%sscreen" % [_VIDEO_ROOT_KEY]
const _RESOLUTION_SCALING: String = "%sresolution_scaling" % [_VIDEO_ROOT_KEY]
const _BRIGHTNESS: String = "%sbrightness" % [_VIDEO_ROOT_KEY]
const _CONTRAST: String = "%scontrast" % [_VIDEO_ROOT_KEY]
const _SATURATION: String= "%ssaturation" % [_VIDEO_ROOT_KEY]
const _FIELD_OF_VIEW: String ="%sfov" % [_VIDEO_ROOT_KEY]

const _DEFAULT_WINDOW_MODE: DisplayServer.WindowMode = DisplayServer.WindowMode.WINDOW_MODE_EXCLUSIVE_FULLSCREEN

const _DEBOUNCE_TIME: float = 0.5

static var _syncing: bool

static var window_mode: DisplayServer.WindowMode:
    get():
        return DisplayServer.window_get_mode()
    set(value):
        DisplayServer.window_set_mode(value)
        if !_syncing:
            GameSettingsProvider.set_settingi(_WINDOW_MODE, value)

static var borderless: bool:
    get():
        return DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_BORDERLESS)
    set(value):
        DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, value)
        if !_syncing:
            GameSettingsProvider.set_settingb(_BORDERLESS, value)

static var screen: int:
    get():
        return DisplayServer.window_get_current_screen()
    set(value):
        DisplayServer.window_set_current_screen(value)
        if !_syncing:
            GameSettingsProvider.set_settingi(_SCREEN, value)

static var resolution_scale: float:
    get():
        return _window.get_viewport().scaling_3d_scale
    set(value):
        _window.scaling_3d_scale = value
        if !_syncing:
            await GameSettingsProvider.get_tree().create_timer(_DEBOUNCE_TIME).timeout
            if field_of_view == value:
                GameSettingsProvider.set_settingf(_RESOLUTION_SCALING, value)

static var field_of_view: float = 75.0:
    set(value):
        field_of_view = value
        SignalBus.on_update_fov.emit(value)
        if !_syncing:
            await GameSettingsProvider.get_tree().create_timer(_DEBOUNCE_TIME).timeout
            if field_of_view == value:
                GameSettingsProvider.set_settingf(_FIELD_OF_VIEW, value)

static var brightness: float:
    get():
        return clampf(GameSettingsProvider.get_settingf(_BRIGHTNESS, 1.0), 0.0, 2.0)

    set(value):
        for env: Environment in adjustable_environments:
            env.adjustment_brightness = value
        await GameSettingsProvider.get_tree().create_timer(_DEBOUNCE_TIME).timeout
        if field_of_view == value:
            GameSettingsProvider.set_settingf(_BRIGHTNESS, value)

static var contrast: float:
    get():
        return clampf(GameSettingsProvider.get_settingf(_CONTRAST, 1.0), 0.0, 2.0)

    set(value):
        for env: Environment in adjustable_environments:
            env.adjustment_contrast = value
        await GameSettingsProvider.get_tree().create_timer(_DEBOUNCE_TIME).timeout
        if field_of_view == value:
            GameSettingsProvider.set_settingf(_CONTRAST, value)

static var saturation: float:
    get():
        return clampf(GameSettingsProvider.get_settingf(_SATURATION, 1.0), 0.0, 2.0)

    set(value):
        for env: Environment in adjustable_environments:
            env.adjustment_saturation = value
        await GameSettingsProvider.get_tree().create_timer(_DEBOUNCE_TIME).timeout
        if field_of_view == value:
            GameSettingsProvider.set_settingf(_SATURATION, value)

static var adjustable_environments: Array[Environment]

static var _window: Window:
    get():
        var id: int = DisplayServer.window_get_attached_instance_id()
        return instance_from_id(id)

static func initialize() -> void:
    _syncing = true
    window_mode = _to_window_mode(GameSettingsProvider.get_settingi(_WINDOW_MODE, -1), _DEFAULT_WINDOW_MODE)
    borderless = GameSettingsProvider.get_settingb(_BORDERLESS, window_mode == DisplayServer.WindowMode.WINDOW_MODE_MAXIMIZED)

    var raw_screen: int = GameSettingsProvider.get_settingi(_SCREEN, screen)
    if raw_screen >= 0 && raw_screen < DisplayServer.get_screen_count():
        screen = raw_screen

    resolution_scale = clampf(GameSettingsProvider.get_settingf(_RESOLUTION_SCALING, resolution_scale), 0.5, 2.0)
    field_of_view = clampf(GameSettingsProvider.get_settingf(_FIELD_OF_VIEW, field_of_view), 30.0, 110.0)
    _syncing = false

static func reset_default() -> void:
    for key: String in GameSettingsProvider.get_all_keys():
        if key.begins_with(_VIDEO_ROOT_KEY):
            GameSettingsProvider.remove_setting(key)

    _syncing = true
    DisplayServer.window_set_mode(_DEFAULT_WINDOW_MODE)
    resolution_scale = 1.0
    field_of_view = 75.0
    brightness = 1.0
    saturation = 1.0
    contrast = 1.0
    _syncing = false

static func _to_window_mode(raw: int, default: DisplayServer.WindowMode) -> DisplayServer.WindowMode:
    match raw:
        -1: return default
        0: return DisplayServer.WindowMode.WINDOW_MODE_WINDOWED
        1: return DisplayServer.WindowMode.WINDOW_MODE_WINDOWED # We ignore minimized for windowed
        2: return DisplayServer.WindowMode.WINDOW_MODE_MAXIMIZED
        3: return DisplayServer.WindowMode.WINDOW_MODE_FULLSCREEN
        4: return DisplayServer.WindowMode.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
        _:
            push_error("Window mode %s not known, falling back to default" % [raw])
            return default
