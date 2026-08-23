extends RayCast3D

@export var _special_collision_layer: int = 5

func _physics_process(_delta: float) -> void:
    if !is_colliding():
        _remove_special_looking()
        _handle_no_interaction()
        return

    var col: Object = get_collider()
    var interactable = Interactable.find_interactable_in_tree(col, true)
    if !interactable || interactable.disabled:
        if !interactable:
            _handle_special_looking_at(col)
        else:
            _remove_special_looking()
        _handle_no_interaction()
        return

    var dist: float = (get_collision_point() - global_position).length()
    var hint: Interactable.Hint = interactable.get_hint(dist)
    if hint == Interactable.Hint.NONE:
        _remove_special_looking()
        _handle_no_interaction()
        return

    _remove_special_looking()
    _handle_hinting(interactable, hint)

var _interactable: Interactable
var _hint: Interactable.Hint

func _handle_no_interaction() -> void:
    if _hint == Interactable.Hint.NONE:
        return

    _hint = Interactable.Hint.NONE
    _interactable = null

    SignalBus.on_pointer_interaction_update.emit(Interactable.Hint.NONE, null)

func _handle_hinting(interactable: Interactable, hint: Interactable.Hint) -> void:
    if _interactable == interactable && _hint == hint:
        return

    _hint = hint
    _interactable = interactable

    SignalBus.on_pointer_interaction_update.emit(hint, interactable)

var _last_special: CollisionObject3D:
    set(value):
        if value != _last_special:
            _last_special = value
            SignalBus.on_pointer_over.emit(value)

func _remove_special_looking() -> void:
    if _last_special == null:
        return

    _last_special = null

func _handle_special_looking_at(obj: Object) -> void:
    if obj is not CollisionObject3D:
        _last_special = null

    var col: CollisionObject3D = obj
    if col && col.get_collision_layer_value(_special_collision_layer):
        _last_special = col
    else:
        _last_special = null
