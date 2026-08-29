class_name GeneralSettings

const _DEBOUNCE_TIME = 0.5

enum Handedness { LEFT, RIGHT }

static var subtitles: bool = true:
    set(value):
        subtitles = value

        SignalBus.on_toggle_subtitles.emit(value)

        if !_syncing:
            await GameSettingsProvider.get_tree().create_timer(_DEBOUNCE_TIME).timeout
            if subtitles == value:
                GameSettingsProvider.set_settingb(_SUBTITLES, value)

static var subtitles_size: int = 28:
    set(value):
        subtitles_size = value

        SignalBus.on_change_subtitles_size.emit(value)

        if !_syncing:
            await GameSettingsProvider.get_tree().create_timer(_DEBOUNCE_TIME).timeout
            if subtitles_size == value:
                GameSettingsProvider.set_settingi(_SUBTITLES_SIZE, value)

static var handedness: Handedness = Handedness.RIGHT:
    set(value):
        handedness = value

        SignalBus.on_update_handedness.emit(handedness)

        if !_syncing:
            await GameSettingsProvider.get_tree().create_timer(_DEBOUNCE_TIME).timeout
            if handedness == value:
                GameSettingsProvider.set_settingi(_HANDEDNESS, value)


static var mouse_inverted_y: bool:
    set(value):
        mouse_inverted_y = value
        SignalBus.on_update_mouse_y_inverted.emit(value)

        if !_syncing:
            await GameSettingsProvider.get_tree().create_timer(_DEBOUNCE_TIME).timeout
            if mouse_inverted_y == value:
                GameSettingsProvider.set_settingb(_MOUSE_INVERT_Y, value)


static var mouse_sensitivity: float = 0.8:
    set(value):
        mouse_sensitivity = value
        SignalBus.on_update_mouse_sensitivity.emit(value)

        if !_syncing:
            await GameSettingsProvider.get_tree().create_timer(_DEBOUNCE_TIME).timeout
            if mouse_sensitivity == value:
                GameSettingsProvider.set_settingf(_MOUSE_SENSITIVITY, value)

static var scaled_mouse_sensitivity: float:
    get():
        var val: float = mouse_sensitivity
        if val <= 1.0:
            return val * 0.02

        return pow(PI, val - 1.0) * 0.02


static var joy_sensitivity: float = 1.0:
    set(value):
        joy_sensitivity = value
        SignalBus.on_update_joy_sensitivity.emit(value)

        if !_syncing:
            await GameSettingsProvider.get_tree().create_timer(_DEBOUNCE_TIME).timeout
            if joy_sensitivity == value:
                GameSettingsProvider.set_settingf(_JOY_SENSITIVITY, value)

static var joy_inverted_y: bool:
    set(value):
        joy_inverted_y = value
        SignalBus.on_update_joy_y_inverted.emit(value)

        if !_syncing:
            await GameSettingsProvider.get_tree().create_timer(_DEBOUNCE_TIME).timeout
            if joy_inverted_y == value:
                GameSettingsProvider.set_settingb(_JOY_INVERT_Y, value)


static var scaled_joy_sensitivy: float:
    get():
        var sens: float = joy_sensitivity
        if sens <= 1.0:
            return sens * 0.75 * PI

        return pow(PI, sens - 1.0) * 0.75 * PI

static var motion_sickness: MotionSickness = MotionSickness.NO:
    set(value):
        motion_sickness = value
        SignalBus.on_update_motion_sickness.emit(motion_sickness)

        if !_syncing:
            await GameSettingsProvider.get_tree().create_timer(_DEBOUNCE_TIME).timeout
            if motion_sickness == value:
                GameSettingsProvider.set_settingi(_MOTION_SICKNESS, value)

static var reticle_size: int = 16:
    set(value):
        reticle_size = value
        SignalBus.on_update_pointer_setting.emit(SignalBus.PointerSetting.SIZE, value)

        if !_syncing:
            await GameSettingsProvider.get_tree().create_timer(_DEBOUNCE_TIME).timeout
            if reticle_size == value:
                GameSettingsProvider.set_settingi(_RETICLE_SIZE, value)

static var reticle_alpha: float = 1.0:
    set(value):
        reticle_alpha = value
        SignalBus.on_update_pointer_setting.emit(SignalBus.PointerSetting.ALPHA, value)

        if !_syncing:
            await GameSettingsProvider.get_tree().create_timer(_DEBOUNCE_TIME).timeout
            if reticle_alpha == value:
                GameSettingsProvider.set_settingf(_RETICLE_ALPHA, value)

static var reticle_text_size: int = 16:
    set(value):
        reticle_text_size = value
        SignalBus.on_update_pointer_setting.emit(SignalBus.PointerSetting.TEXT_SIZE, value)

        if !_syncing:
            await GameSettingsProvider.get_tree().create_timer(_DEBOUNCE_TIME).timeout
            if reticle_text_size == value:
                GameSettingsProvider.set_settingi(_RETICLE_TEXT_SIZE, value)

static var analytics_consent: Consent = Consent.NONE:
    set(value):
        analytics_consent = value
        if !_syncing:
            await GameSettingsProvider.get_tree().create_timer(_DEBOUNCE_TIME).timeout
            if analytics_consent == value:
                GameSettingsProvider.set_settingi(_CONCENT_ANALYTICS, value)

enum MotionSickness { IMPOSSIBLE = 0, NO = 1, SELDOM = 2, SOMETIMES = 3, YES = 4, VERY_SENSITIVE = 5, UNSET = -1 }
enum Consent { NONE, YES, NO }

const _GENERAL_ROOT: String = "general."
const _SUBTITLES: String = "%ssubtitles" % [_GENERAL_ROOT]
const _SUBTITLES_SIZE: String = "%subtitles.size" % [_GENERAL_ROOT]
const _HANDEDNESS: String = "%shandedness" % [_GENERAL_ROOT]
const _MOUSE_INVERT_Y: String = "%smouse.invert-y-axis" % [_GENERAL_ROOT]
const _MOUSE_SENSITIVITY: String = "%smouse.sensistivity" % [_GENERAL_ROOT]
const _JOY_SENSITIVITY: String = "%sjoy.sensistivity" % [_GENERAL_ROOT]
const _JOY_INVERT_Y: String = "%sjoy.invert-y-axis" % [_GENERAL_ROOT]
const _MOTION_SICKNESS: String = "%smotion-sickness" % [_GENERAL_ROOT]
const _RETICLE_SIZE: String = "%sreticle.size" % [_GENERAL_ROOT]
const _RETICLE_ALPHA: String = "%sreticle.alpha" % [_GENERAL_ROOT]
const _RETICLE_TEXT_SIZE: String = "%sreticle.text-size" % [_GENERAL_ROOT]
const _CONCENT_ANALYTICS: String = "%sanalytics-consent" % [_GENERAL_ROOT]

static var _syncing: bool = false

static var _defaults: Dictionary

static func initialize() -> void:
    _store_defaults()
    _sync()
    SignalBus.on_update_handedness.emit(handedness)
    SignalBus.on_update_mouse_y_inverted.emit(mouse_inverted_y)

static func reset_default() -> void:
    subtitles_size = clampi(DictionaryUtils.safe_geti(_defaults, _SUBTITLES_SIZE, 28), 14, 42)
    subtitles = DictionaryUtils.safe_getb(_defaults, _SUBTITLES, true)
    handedness = _int_to_handedness(DictionaryUtils.safe_geti(_defaults, _HANDEDNESS, Handedness.RIGHT))
    mouse_inverted_y = DictionaryUtils.safe_getb(_defaults, _MOUSE_INVERT_Y, false)
    mouse_sensitivity = clampf(DictionaryUtils.safe_getf(_defaults, _MOUSE_SENSITIVITY, 1.0), 0.0, 2.0)
    joy_sensitivity = clampf(DictionaryUtils.safe_getf(_defaults, _JOY_SENSITIVITY, 1.0), 0.0, 2.0)
    joy_inverted_y = DictionaryUtils.safe_getb(_defaults, _JOY_INVERT_Y, false)
    reticle_size = DictionaryUtils.safe_geti(_defaults, _RETICLE_SIZE, 16)
    reticle_alpha = DictionaryUtils.safe_getf(_defaults, _RETICLE_ALPHA, 1.0)
    reticle_text_size = DictionaryUtils.safe_geti(_defaults, _RETICLE_TEXT_SIZE, 16)
    analytics_consent = int_to_consent(DictionaryUtils.safe_geti(_defaults, _CONCENT_ANALYTICS, Consent.NONE))
    motion_sickness = int_to_motion_sickness(DictionaryUtils.safe_geti(_defaults, _MOTION_SICKNESS, MotionSickness.NO))

static func _store_defaults() -> void:
    _defaults[_SUBTITLES_SIZE] = subtitles_size
    _defaults[_SUBTITLES] = subtitles
    _defaults[_HANDEDNESS] = handedness
    _defaults[_MOUSE_INVERT_Y] = mouse_inverted_y
    _defaults[_MOUSE_SENSITIVITY] = mouse_sensitivity
    _defaults[_JOY_SENSITIVITY] = joy_sensitivity
    _defaults[_JOY_INVERT_Y] = joy_inverted_y
    _defaults[_MOTION_SICKNESS] = motion_sickness
    _defaults[_RETICLE_SIZE] = reticle_size
    _defaults[_RETICLE_ALPHA] = reticle_alpha
    _defaults[_RETICLE_TEXT_SIZE] = reticle_text_size
    _defaults[_CONCENT_ANALYTICS] = analytics_consent

static func _sync() -> void:
    _syncing = true

    subtitles_size = clampi(GameSettingsProvider.get_settingi(_SUBTITLES_SIZE, subtitles_size), 14, 42)
    subtitles = GameSettingsProvider.get_settingb(_SUBTITLES, subtitles)
    handedness = _int_to_handedness(GameSettingsProvider.get_settingi(_HANDEDNESS, handedness))
    mouse_inverted_y = GameSettingsProvider.get_settingb(_MOUSE_INVERT_Y, false)
    mouse_sensitivity = clampf(GameSettingsProvider.get_settingf(_MOUSE_SENSITIVITY, mouse_sensitivity), 0, 2.0)
    joy_sensitivity = clampf(GameSettingsProvider.get_settingf(_JOY_SENSITIVITY, joy_sensitivity), 0, 2.0)
    joy_inverted_y = GameSettingsProvider.get_settingb(_JOY_INVERT_Y, false)
    motion_sickness = int_to_motion_sickness(GameSettingsProvider.get_settingi(_MOTION_SICKNESS, motion_sickness))
    reticle_size = clampi(GameSettingsProvider.get_settingi(_RETICLE_SIZE, reticle_size), 2, 32)
    reticle_alpha = clampf(GameSettingsProvider.get_settingf(_RETICLE_ALPHA, reticle_alpha), 0.0, 1.0)
    reticle_text_size = clampi(GameSettingsProvider.get_settingi(_RETICLE_TEXT_SIZE, reticle_text_size), 8, 42)
    analytics_consent = int_to_consent(GameSettingsProvider.get_settingi(_CONCENT_ANALYTICS, analytics_consent))

    _syncing = false

static func _int_to_handedness(value: int) -> Handedness:
    match value:
        0: return Handedness.LEFT
        1: return Handedness.RIGHT
        _:
            push_error("%s is not a handedness" % value)
            return Handedness.RIGHT

static func int_to_motion_sickness(value: int) -> MotionSickness:
    match value:
        0: return MotionSickness.IMPOSSIBLE
        1: return MotionSickness.NO
        2: return MotionSickness.SELDOM
        3: return MotionSickness.SOMETIMES
        4: return MotionSickness.YES
        5: return MotionSickness.VERY_SENSITIVE
        -1: return MotionSickness.UNSET
        _:
            push_error("%s is not a motion sickness" % value)
            return MotionSickness.UNSET

static func int_to_consent(value: int) -> Consent:
    match value:
        0: return Consent.NONE
        1: return Consent.YES
        2: return Consent.NO
        _:
            push_error("%s is not a consent" % value)
            return Consent.NONE
