class_name PseudoSaveSettings

const _DEBOUNCE_TIME = 0.5

enum Handedness { LEFT, RIGHT }

const _SAVE_ROOT = "save"
const _LVL_SELECT = "%s.lvl-select" % _SAVE_ROOT

static var _syncing: bool = false

static var show_level_select: bool = false:
    set(value):
        show_level_select = value

        SignalBus.on_toggle_subtitles.emit(value)

        if !_syncing:
            await GameSettingsProvider.get_tree().create_timer(_DEBOUNCE_TIME).timeout
            if show_level_select == value:
                GameSettingsProvider.set_settingb(_LVL_SELECT, value)

static var _defaults: Dictionary

static func initialize() -> void:
    _store_defaults()
    _sync()

static func reset_default() -> void:
    show_level_select = DictionaryUtils.safe_getb(_defaults, _LVL_SELECT, true)

static func _store_defaults() -> void:
    _defaults[_LVL_SELECT] = show_level_select


static func _sync() -> void:
    _syncing = true

    show_level_select = GameSettingsProvider.get_settingb(_LVL_SELECT, show_level_select)

    _syncing = false
