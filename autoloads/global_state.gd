class_name GlobalState

static var save_slot: int

const _KEY_VICIOUS: String = "vicious"
const _KEY_ENSAM: String = "ensam"
const _KEY_SIGNAL: String = "signal"

static var _provider: SaveStorageProvider

static func save(provider: SaveStorageProvider = null) -> bool:
    if provider == null:
        provider = _provider
    else:
        _provider = provider

    var payload: Dictionary = {
        #_KEY_VICIOUS: GlobalStateVicious.save(),

    }

    return provider.store_data(save_slot, payload)

static func reset(provider: SaveStorageProvider = null) -> bool:
    if provider == null:
        provider = _provider
    else:
        _provider = provider

    save_slot = 0

    #GlobalStateVicious.reset()

    return save(provider)

static func load(provider: SaveStorageProvider = null, slot: int = 0) -> void:
    if provider == null:
        provider = _provider
    else:
        _provider = provider

    save_slot = slot
    var data = provider.retrieve_data(slot)
    #GlobalStateVicious.load(data.get(_KEY_VICIOUS, {}))
