@tool
extends BaseButton
class_name ContainerButton

@export var background_panel: Panel
@export var labels: Array[Label] = []

var _focused: bool
var _hovered: bool
var _pressed: bool

func _ready() -> void:
    _update_style()

func _enter_tree() -> void:
    _connect_children_resize()

    if Engine.is_editor_hint():
        return

    if child_entered_tree.connect(_handle_add_child) != OK:
        push_error("Failed to connect add child")
    if child_exiting_tree.connect(_handle_remove_child) != OK:
        push_error("Failed to connect remove child")
    if focus_entered.connect(_focus.bind(true)) != OK:
        push_error("Failed to connect focus enter")
    if focus_exited.connect(_focus.bind(false)) != OK:
        push_error("Failed to connect focus exit")
    if mouse_entered.connect(_hover.bind(true)) != OK:
        push_error("Failed to connect mouse entered")
    if mouse_exited.connect(_hover.bind(false)) != OK:
        push_error("Failed to connect mouse exited")
    if button_down.connect(_press.bind(true)) != OK:
        push_error("Failed to connect button down")
    if button_up.connect(_press.bind(false)) != OK:
        push_error("Failed to connect button up")

func _press(btn_pressed: bool) -> void:
    _pressed = btn_pressed
    _update_style()

func _hover(btn_hovered: bool) -> void:
    _hovered = btn_hovered
    _update_style()

func _focus(btn_focused: bool) -> void:
    _focused = btn_focused
    _update_style()

func _update_style() -> void:
    if background_panel:
        _style_child(background_panel, "Panel")
    for label: Label in labels:
        _style_child(label, "Label")

func _style_child(child: Control, base: String) -> void:
    var t: Theme = find_theme(child)
    if !t:
        push_warning("%s of %s lacks explicit theme so cannot be managed" % [child, self])
        return

    if disabled && t.is_type_variation("ContainerButton%sDisabled" % [base], base):
        child.theme_type_variation = "ContainerButton%sDisabled" % [base]
    elif _pressed && t.is_type_variation("ContainerButton%sPressed" % [base], base):
        child.theme_type_variation = "ContainerButton%sPressed" % [base]
    elif _hovered && t.is_type_variation("ContainerButton%sHover" % [base], base):
        child.theme_type_variation = "ContainerButton%sHover" % [base]
    elif _focused && t.is_type_variation("ContainerButton%sFocus" % [base], base):
        child.theme_type_variation = "ContainerButton%sFocus" % [base]
    elif t.is_type_variation("ContainerButton%sNormal" % [base], base):
        child.theme_type_variation = "ContainerButton%sNormal" % [base]
    else:
        child.theme_type_variation = ""

func _handle_remove_child(node: Node) -> void:
    if node is not Control:
        return
    var child: Control = node
    if child.resized.is_connected(_handle_resize):
        child.resized.disconnect(_handle_resize)

func _handle_add_child(node: Node) -> void:
    if node is not Control:
        return

    var child: Control = node
    if child.resized.is_connected(_handle_resize):
        return

    if child.resized.connect(_handle_resize) != OK:
        push_error("Failed to connect %s resize" % [child.name])

func _connect_children_resize() -> void:
    for child: Node in get_children():
        if child is not Control:
            continue
        var item: Control = child
        if item.resized.is_connected(_handle_resize):
            continue

        if item.resized.connect(_handle_resize) != OK:
            push_error("Failed to connect resize")

var _resizing: bool
func _handle_resize() -> void:
    if _resizing:
        return
    _resizing = true
    var r: Rect2
    for child: Node in get_children():
        if child is not Control:
            continue

        var ctrl: Control = child
        if r.size.length_squared() == 0.0:
            r = ctrl.get_global_rect()
        else:
            r = r.merge(ctrl.get_global_rect())

        custom_minimum_size = r.size
    _resizing = false


static func find_theme(node: Node) -> Theme:
    while node:
        if node is Control:
            var control: Control = node
            if control.theme:
               return control.theme
        node = node.get_parent()
    return null
