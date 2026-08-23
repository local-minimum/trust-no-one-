class_name AudioSettings

const _DEBOUNCE_TIME = 0.5
const _AUDIO_ROOT_KEY: String = "audio"

static var _defaults: Dictionary
static var _last_volume: Dictionary

static func initialize() -> void:
    _store_defaults()
    _load_stored()

static func _load_stored() -> void:
    for bus: AudioHub.Bus in AudioHub.Bus.values():
        AudioHub.set_volume(bus, get_stored_volume(bus, AudioHub.get_volume(bus)))

static func reset_default() -> void:
    for bus: AudioHub.Bus in AudioHub.Bus.values():
        var key: String = _bus_storage_key(bus)
        if key.is_empty():
            continue
        store_volume(bus, _defaults.get(key, 1.0))

static func get_stored_volume(bus: AudioHub.Bus, default: float = 1.0) -> float:
    var key: String = _bus_storage_key(bus)
    if key.is_empty():
        return default

    return clampf(GameSettingsProvider.get_settingf(key, default), 0.0, 1.0)

static func store_volume(bus: AudioHub.Bus, volume: float) -> void:
    _last_volume[bus] = volume
    AudioHub.set_volume(bus, volume)

    var key: String = _bus_storage_key(bus)
    if key.is_empty():
        return

    await GameSettingsProvider.get_tree().create_timer(_DEBOUNCE_TIME).timeout
    if _last_volume.get(bus) == volume:
        GameSettingsProvider.set_settingf(key, volume)

static func _bus_storage_key(bus: AudioHub.Bus) -> String:
    var bus_name: Variant = AudioHub.Bus.find_key(bus)
    if bus_name is not String:
        push_warning("Could not resolve bus name for audio bus %s" % [bus])
        return ""

    return "%s.bus.%s" % [_AUDIO_ROOT_KEY, (bus_name as String).to_lower()]

static func _store_defaults() -> void:
    for bus: AudioHub.Bus in AudioHub.Bus.values():
        var key: String = _bus_storage_key(bus)
        if key.is_empty():
            continue
        var volume: float = AudioHub.get_volume(bus)
        _defaults[key] = volume
