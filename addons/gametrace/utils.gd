class_name GameTraceUtils
extends RefCounted
## Utility functions for UUID generation and timestamp formatting.


static func generate_uuid() -> String:
    ## Generate a v4 UUID string.
    var rng := RandomNumberGenerator.new()
    rng.randomize()
    var bytes := PackedByteArray()
    bytes.resize(16)
    for i in range(16):
        bytes[i] = rng.randi_range(0, 255)
    # Set version (4) and variant (10xx) bits
    bytes[6] = (bytes[6] & 0x0f) | 0x40
    bytes[8] = (bytes[8] & 0x3f) | 0x80
    var hex := bytes.hex_encode()
    return "%s-%s-%s-%s-%s" % [
        hex.substr(0, 8),
        hex.substr(8, 4),
        hex.substr(12, 4),
        hex.substr(16, 4),
        hex.substr(20, 12),
    ]


static func iso_timestamp() -> String:
    ## Return the current UTC time as an ISO 8601 string.
    var dt := Time.get_datetime_dict_from_system(true)
    return "%04d-%02d-%02dT%02d:%02d:%02dZ" % [
        dt.year, dt.month, dt.day,
        dt.hour, dt.minute, dt.second,
    ]
