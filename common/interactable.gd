extends Node3D
class_name Interactable

enum Hint { NONE, POINTER, INTERACTABLE}

@export var action: InteractableAction:
    get():
        return action
    set(value):
        var changing = action != value
        action = value
        if changing:
            SignalBus.on_interactable_action_change.emit(self)

@export var _pointer_distance: float = 10
@export var _interaction_distance: float = 1
@export var _focus_item: Node3D
@export var focus_distance: float = 0.2

var disabled: bool
var live: bool

var _focus_item_position: Vector3
var _focus_item_rotation: Vector3
var _focus_item_scale: Vector3

var _focus_item_tween: Tween

func interact() -> void:
    if action:
        action.perform(self)

func abort() -> void:
    if action:
        action.abort(self)

func _enter_tree() -> void:
    if SignalBus.on_pointer_captured.connect(_handle_pointer_captured) != OK:
        push_error("Failed to connect pointer captured")
    if SignalBus.on_abort_interaction.connect(_handle_abort_interaction) != OK:
        push_error("Failed to connect abort interaction")

func _handle_abort_interaction() -> void:
    if live:
        live = false
        abort()

func _handle_pointer_captured(captured: bool) -> void:
    if captured:
        live = false

func _kill_focus_item_tween() -> bool:
    if _focus_item_tween && _focus_item_tween.is_running():
        _focus_item_tween.kill()
        return true
    return false

func get_focus_item() -> Node3D:
    if !_focus_item:
        return null

    if !_kill_focus_item_tween():
        _focus_item_position = _focus_item.position
        _focus_item_rotation = _focus_item.rotation
        _focus_item_scale = _focus_item.scale

    return _focus_item

func return_focus_item(
    duration: float = 0.0,
    easing: Tween.EaseType = Tween.EaseType.EASE_IN,
    trans: Tween.TransitionType = Tween.TransitionType.TRANS_LINEAR,
) -> void:
    if !_focus_item:
        return

    var diff_pos: bool = _focus_item.position != _focus_item_position
    var diff_rot: bool = _focus_item.rotation != _focus_item_rotation
    var diff_scale: bool = _focus_item.scale != _focus_item_scale

    if duration <= 0.0 || !diff_pos && !diff_rot && !diff_scale:
        _restore_focus_item_transform()
        return

    _kill_focus_item_tween()

    _focus_item_tween = create_tween()
    _focus_item_tween.set_parallel()
    if diff_pos:
        _focus_item_tween.tween_property(_focus_item, "position", _focus_item_position, duration).set_ease(easing).set_trans(trans)
    if diff_rot:
        _focus_item_tween.tween_property(_focus_item, "rotation", _focus_item_rotation, duration).set_ease(easing).set_trans(trans)
    if diff_scale:
        _focus_item_tween.tween_property(_focus_item, "scale", _focus_item_scale, duration).set_ease(easing).set_trans(trans)

    if !_focus_item_tween.finished.connect(_restore_focus_item_transform):
        await get_tree().create_timer(duration).timeout
        _restore_focus_item_transform()

func _restore_focus_item_transform() -> void:
    if !_focus_item:
        return

    _focus_item.position = _focus_item_position
    _focus_item.rotation = _focus_item_rotation
    _focus_item.scale = _focus_item_scale

func get_hint(distance: float) -> Hint:
    if distance < _interaction_distance:
        return Hint.INTERACTABLE
    if distance < _pointer_distance:
        return Hint.POINTER
    return Hint.NONE

static func find_interactable_in_tree(node: Node, include_self: bool = false) -> Interactable:
    if node == null:
        return null

    if include_self && node is Interactable:
        return node

    return find_interactable_in_tree(node.get_parent(), true)


func _on_mouse_entered() -> void:
    if live:
        SignalBus.on_pointer_interaction_update.emit(Interactable.Hint.INTERACTABLE if action else Interactable.Hint.NONE, self)

func _on_mouse_exited() -> void:
    if live:
        SignalBus.on_pointer_interaction_update.emit(Interactable.Hint.NONE, self)
