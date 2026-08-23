class_name BindingSettings

enum InputMethod { KEYBOARD_AND_MOUSE, JOYPAD }

static var active_input_method: InputMethod = InputMethod.KEYBOARD_AND_MOUSE:
    set(value):
        if active_input_method != value:
            active_input_method = value
            SignalBus.on_change_input_method.emit(value)

const CONTROLLER_BTN_LABELS: Dictionary[JoyButton, String] = {
    JoyButton.JOY_BUTTON_A: "A",
    JoyButton.JOY_BUTTON_B: "B",
    JoyButton.JOY_BUTTON_X: "X",
    JoyButton.JOY_BUTTON_Y: "Y",
    JoyButton.JOY_BUTTON_LEFT_SHOULDER: "LB",
    JoyButton.JOY_BUTTON_RIGHT_SHOULDER: "RB",
    JoyButton.JOY_BUTTON_LEFT_STICK: "L3",
    JoyButton.JOY_BUTTON_RIGHT_STICK: "R3",
    JoyButton.JOY_BUTTON_DPAD_DOWN: "DPAD ↓",
    JoyButton.JOY_BUTTON_DPAD_LEFT: "DPAD ←",
    JoyButton.JOY_BUTTON_DPAD_UP: "DPAD ↑",
    JoyButton.JOY_BUTTON_DPAD_RIGHT: "DPAD →",
    JoyButton.JOY_BUTTON_START: "START",
    JoyButton.JOY_BUTTON_GUIDE: "SELECT",
    JoyButton.JOY_BUTTON_BACK: "BACK"
}

const CONTROLLER_AXIS_LABELS: Dictionary[JoyAxis, Array] = {
    JoyAxis.JOY_AXIS_LEFT_X: ["L←", "L→"],
    JoyAxis.JOY_AXIS_LEFT_Y: ["L↑", "L↓"],
    JoyAxis.JOY_AXIS_RIGHT_X: ["R←", "R→"],
    JoyAxis.JOY_AXIS_RIGHT_Y: ["R↓", "R↑"],
    JoyAxis.JOY_AXIS_TRIGGER_LEFT: ["LT"],
    JoyAxis.JOY_AXIS_TRIGGER_RIGHT: ["RT"],
}

const MOUSE_LABELS: Dictionary[MouseButton, String] = {
    MouseButton.MOUSE_BUTTON_LEFT: "LMB",
    MouseButton.MOUSE_BUTTON_RIGHT: "RMB",
    MouseButton.MOUSE_BUTTON_MIDDLE: "MMB",
    MouseButton.MOUSE_BUTTON_XBUTTON1: "MX1",
    MouseButton.MOUSE_BUTTON_XBUTTON2: "MX2",
    MouseButton.MOUSE_BUTTON_WHEEL_DOWN: "MW↓",
    MouseButton.MOUSE_BUTTON_WHEEL_UP: "MW↑",
    MouseButton.MOUSE_BUTTON_WHEEL_LEFT: "MW←",
    MouseButton.MOUSE_BUTTON_WHEEL_RIGHT: "MW→",
}

const _EVT_KEY_TYPE: String = "type"
const _EVT_TYPE_KEYB: String = "key"
const _EVT_TYPE_MOUSEB: String = "mouse"
const _EVT_TYPE_JOYB: String = "joy"
const _EVT_TYPE_JOYA: String = "joy-axis"
const _EVT_TYPE_UNBOUND: String = "unbound"

const _BINDINGS_ROOT_KEY: String = "bindings"

static var _defaults: Dictionary
static var _active: Dictionary

static func initialize() -> void:
    _store_defaults()
    _load_stored()

static func reset_default() -> void:
    for key: String in GameSettingsProvider.get_all_keys().filter(_create_stored_bindings_key_filt()):
        GameSettingsProvider.remove_setting(key)

    for action: StringName in _defaults:
        InputMap.action_erase_events(action)
        for event: InputEvent in _defaults[action]:
            InputMap.action_add_event(action, event)

    _active = {}

static func reset_input_method(input_method: InputMethod) -> void:
    var im_key: String = _input_method_key(input_method)
    var actions: Array[String] = []
    for key: String in GameSettingsProvider.get_all_keys().filter(_create_stored_bindings_key_filt()):
        var key_parts: PackedStringArray = key.split(".", true, 4)
        var action: String = key_parts[1]
        var raw_im: String = key_parts[2]
        if raw_im == im_key:
            GameSettingsProvider.remove_setting(key)

            if InputMap.has_action(action) && !actions.has(action):
                actions.append(action)

    for action: String in actions:
        var all_events: Array[InputEvent] = InputMap.action_get_events(action)
        var per_im: Dictionary[InputMethod, Array] = {
            InputMethod.KEYBOARD_AND_MOUSE: all_events.filter(is_valid_action_event.bind(InputMethod.KEYBOARD_AND_MOUSE)),
            InputMethod.JOYPAD: all_events.filter(is_valid_action_event.bind(InputMethod.JOYPAD)),
        }
        per_im[input_method] = _defaults.get(action, []).filter(is_valid_action_event.bind(input_method))

        _active[action] = per_im

        InputMap.action_erase_events(action)
        for s: InputMethod in per_im:
            for evt: InputEvent in per_im[s]:
                if evt && evt is not InputEventAction:
                    InputMap.action_add_event(action, evt)

static func key_event_to_text(kevt: InputEventKey) -> String:
    if kevt.physical_keycode:
        return OS.get_keycode_string(kevt.physical_keycode)
    else:
        return OS.get_keycode_string(kevt.keycode)

static func mouse_event_to_text(mevt: InputEventMouseButton) -> String:
    if BindingSettings.MOUSE_LABELS.has(mevt.button_index):
        return BindingSettings.MOUSE_LABELS[mevt.button_index]
    else:
        push_warning("Mouse button index %s name unknown" % [mevt.button_index])
        return "Mouse %s" % mevt.button_index

static func joy_btn_event_to_text(jevt: InputEventJoypadButton) -> String:
    if BindingSettings.CONTROLLER_BTN_LABELS.has(jevt.button_index):
        return BindingSettings.CONTROLLER_BTN_LABELS.get(jevt.button_index)
    else:
        push_warning("Joy button index %s name unknown" % [jevt.button_index])
        return "Btn %s" % [jevt.button_index]


static func joy_axis_event_to_text(jevt: InputEventJoypadMotion) -> String:
    if BindingSettings.CONTROLLER_AXIS_LABELS.has(jevt.axis):
        var opts: Array = BindingSettings.CONTROLLER_AXIS_LABELS.get(jevt.axis)
        if opts.size() == 1:
            return opts[0]
        else:
            return opts[0 if jevt.axis_value < 0.0 else 1]
    else:
        push_warning("Joy axis index %s name is unknown" % [jevt.axis])
        return "Axis %s%s" % [jevt.axis, "-" if jevt.axis_value < 0.0 else "+"]

static func _load_stored() -> void:
    var overrides: Dictionary[String, Dictionary] = _collect_stored_overrides()
    _update_bindings_with_stored_overrides(overrides)

static func _create_stored_bindings_key_filt() -> Callable:
    var filter_start: String = "%s." % [_BINDINGS_ROOT_KEY]
    var filt: Callable = func (key: String) -> bool: return key.begins_with(filter_start)
    return filt

static func _collect_stored_overrides() -> Dictionary[String, Dictionary]:
    var data: Dictionary[String, Dictionary] = {}

    for key: String in GameSettingsProvider.get_all_keys().filter(_create_stored_bindings_key_filt()):
        var key_parts: PackedStringArray = key.split(".", true, 4)
        var idx: int = int(key_parts[3])
        var action: String = key_parts[1]
        var raw_im: String = key_parts[2]
        var param: String = key_parts[4]
        if param.is_empty():
            push_warning("Bindings key '%s' lacks parameter name" % [key])
            continue
        if raw_im != "mnk" && raw_im != "joy":
            push_warning("Bindings key '%s' has invalid input method '%s'" % [key, raw_im])
            continue
        if !InputMap.has_action(action):
            push_warning("Bindings key '%s' has non-existing action '%s'" % [key, action])
            continue

        var im: InputMethod = InputMethod.KEYBOARD_AND_MOUSE if raw_im == "mnk" else InputMethod.JOYPAD
        var value: Variant = GameSettingsProvider.get_setting(key)
        if !data.has(action):
            data[action] = {}

        var action_data: Dictionary = data[action]
        if !action_data.has(im):
            action_data[im] = []

        var im_actions: Array = action_data[im]
        while im_actions.size() <= idx:
            im_actions.append({})

        im_actions[idx][param] = value

    return data

static func _update_bindings_with_stored_overrides(data: Dictionary[String, Dictionary]) -> void:
    for action: String in data:
        var to_load: Array[Dictionary] = []
        for im: InputMethod in data[action]:
            var idx: int = -1
            for raw_evt: Dictionary in data[action][im]:
                idx += 1
                if raw_evt.is_empty():
                    continue

                var evt: InputEvent = _deserialize_event(raw_evt)
                if evt == null:
                    push_warning("Failed to deserialize %s into an event for '%s' (%s)" % [raw_evt, action, InputMethod.find_key(im)])
                    continue
                to_load.append({"im": im, "idx": idx, "event": evt})

        var all_events: Array[InputEvent] = InputMap.action_get_events(action)
        var per_im: Dictionary[InputMethod, Array] = {
            InputMethod.KEYBOARD_AND_MOUSE: all_events.filter(is_valid_action_event.bind(InputMethod.KEYBOARD_AND_MOUSE)),
            InputMethod.JOYPAD: all_events.filter(is_valid_action_event.bind(InputMethod.JOYPAD)),
        }


        for tl: Dictionary in to_load:
            var idx: int = tl['idx']
            var im: InputMethod = tl['im']
            while per_im[im].size() <= idx:
                per_im[im].append(null)
            per_im[im][idx] = tl['event']

        _active[action] = per_im

        InputMap.action_erase_events(action)
        for im: InputMethod in per_im:
            for evt: InputEvent in per_im[im]:
                if evt && evt is not InputEventAction:
                    InputMap.action_add_event(action, evt)

static func _input_method_key(im: InputMethod) -> String:
    match im:
        InputMethod.KEYBOARD_AND_MOUSE:
            return "mnk"
        InputMethod.JOYPAD:
            return "joy"
        _:
            return "unknown"

static func _deserialize_event(data: Dictionary) -> InputEvent:
    match data.get(_EVT_KEY_TYPE, null):
        _EVT_TYPE_UNBOUND:
            return InputEventAction.new()

        _EVT_TYPE_KEYB:
            var key: int = DictionaryUtils.safe_geti(data, "key", -1)
            if key < 0:
                return null
            var evt: InputEventKey = InputEventKey.new()
            evt.keycode = key as Key
            return evt

        _EVT_TYPE_MOUSEB:
            var idx: int = DictionaryUtils.safe_geti(data, "index", -1)
            if idx < 0:
                return null

            var evt: InputEventMouseButton = InputEventMouseButton.new()
            evt.button_index = idx as MouseButton

            return evt

        _EVT_TYPE_JOYB:
            var idx: int = DictionaryUtils.safe_geti(data, "index", -1)
            if idx < 0:
                return

            var evt: InputEventJoypadButton = InputEventJoypadButton.new()
            evt.button_index = idx as JoyButton

            return evt

        _EVT_TYPE_JOYA:
            var axis: int = DictionaryUtils.safe_geti(data, "axis", -1)
            var value: float = DictionaryUtils.safe_getf(data, "value", 0.0)
            if axis < 0 || value == 0:
                return null

            var evt: InputEventJoypadMotion = InputEventJoypadMotion.new()
            evt.axis = axis as JoyAxis
            evt.axis_value = -1.0 if value < 0.0 else 1.0
            return evt

    return null

static func _serialize_event(evt: InputEvent) -> Dictionary[String, Variant]:
    if evt == null:
        return { _EVT_KEY_TYPE: _EVT_TYPE_UNBOUND }

    if evt is InputEventKey:
        var kevt: InputEventKey = evt

        return {
            _EVT_KEY_TYPE: _EVT_TYPE_KEYB,
            "key": kevt.keycode,
        }

    if evt is InputEventMouseButton:
        var mevt: InputEventMouseButton = evt
        return {
            _EVT_KEY_TYPE: _EVT_TYPE_MOUSEB,
            "index": mevt.button_index,
        }

    if evt is InputEventJoypadButton:
        var jevt: InputEventJoypadButton = evt
        return {
            _EVT_KEY_TYPE: _EVT_TYPE_JOYB,
            "index": jevt.button_index,
        }

    if evt is InputEventJoypadMotion:
        var jevt: InputEventJoypadMotion = evt
        return {
            _EVT_KEY_TYPE: _EVT_TYPE_JOYA,
            "axis": jevt.axis,
            "value": jevt.axis_value,
        }

    return {}

static func get_binding(im: InputMethod, action: String, idx: int) -> InputEvent:
    if _active.has(action):
        var a_bindings: Array = _active[action][im]
        if a_bindings.size() > idx:
            var binding: InputEvent = a_bindings[idx]
            if binding is InputEventAction:
                return null
            return binding
        return null

    if !InputMap.has_action(action):
        return null

    var per_im: Dictionary[InputMethod, Array] = _add_default_binds_to_active(action)

    var bindings: Array = per_im[im]
    if bindings.size() > idx:
        return bindings[idx]
    return null

static func get_first_binding(im: InputMethod, action: String) -> InputEvent:
    var evt: InputEvent = get_binding(im, action, 0)
    if evt:
        return evt

    if _active.has(action):
        for e: InputEvent in _active[action][im]:
            if e && e is not InputEventAction:
                return e

    return null

static func _add_default_binds_to_active(action: String) -> Dictionary[InputMethod, Array]:
    var all_events: Array[InputEvent] = InputMap.action_get_events(action)
    var per_im: Dictionary[InputMethod, Array] = {
        InputMethod.KEYBOARD_AND_MOUSE: all_events.filter(is_valid_action_event.bind(InputMethod.KEYBOARD_AND_MOUSE)),
        InputMethod.JOYPAD: all_events.filter(is_valid_action_event.bind(InputMethod.JOYPAD)),
    }
    _active[action] = per_im
    return per_im

static func store_changed_binding(im: InputMethod, action: String, idx: int, evt: InputEvent) -> void:
    var key: String = "%s.%s.%s.%s." % [_BINDINGS_ROOT_KEY, action, _input_method_key(im), idx]
    for s_key: String in GameSettingsProvider.get_all_keys().filter(_create_stored_bindings_key_filt()):
        if s_key.begins_with(key):
            GameSettingsProvider.remove_setting(s_key)

    var data: Dictionary[String, Variant] = _serialize_event(evt)
    for data_key: String in data:
        var val: Variant = data[data_key]
        GameSettingsProvider.set_setting(key + data_key, val)

    if _active.has(action):
        var bindings: Array = _active[action][im]
        _replace_or_extend_active_bindings(bindings, idx, evt)
    else:
        var per_im: Dictionary[InputMethod, Array] = _add_default_binds_to_active(action)
        _replace_or_extend_active_bindings(per_im[im], idx, evt)

static func _replace_or_extend_active_bindings(bindings: Array, idx: int, evt: InputEvent) -> void:
    if bindings.size() > idx:
        bindings[idx] = evt
    else:
        while bindings.size() < idx:
            bindings.append(null)
        bindings.append(evt)

static func _store_defaults() -> void:
    for action: StringName in InputMap.get_actions():
        _defaults[action] = InputMap.action_get_events(action)

static func is_valid_action_event(evt: InputEvent, im: InputMethod, include_mouse_motion: bool = false) -> bool:
    if im == BindingSettings.InputMethod.JOYPAD:
        return evt is InputEventJoypadButton || evt is InputEventJoypadMotion
    elif im == BindingSettings.InputMethod.KEYBOARD_AND_MOUSE:
        return evt is InputEventKey || evt is InputEventMouseButton || (include_mouse_motion && evt is InputEventMouseMotion)

    return false
