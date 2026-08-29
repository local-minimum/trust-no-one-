@tool
extends CharacterBody3D
class_name HubPlayerCharacter

@export var cam: Camera3D
@export_file("*.mp3") var footfalls: Array[String]
@export var skew_vertical_look_sense: float = 1.0
@export var footfall_distance: float = 1.0
@export var allow_focus: bool
@export var allow_ducking: bool
@export var focus_effect: float = 0.5
@export var focus_fov_factor: float = 0.7
@export var focus_fov_ease_time: float = 0.3
@export var ui_sounds: FlipUITextureRect
@export var ui_no_music: FlipUITextureRect
@export var ui_no_sounds: FlipUITextureRect

var look_locked: bool

var _cinematic_reasons: Array[Node]
var cinematic: bool:
    get():
        return !_cinematic_reasons.is_empty()

func add_cinematic_reason(reason: Node) -> void:
    if _cinematic_reasons.has(reason):
        return
    _cinematic_reasons.append(reason)

func remove_cinematic_reason(reason: Node) -> void:
    _cinematic_reasons.erase(reason)

const UNDUCKING_MARGIN: float = 0.05

@export var character_height: float = 1.8:
    set(value):
        character_height = value
        if collider:
            collider.position.y = 0.5 * value
            collider_capsul_height = value
        if cam:
            cam.position.y = value - 0.2
        if duck_ray:
            duck_ray.position.y = value - duck_height + UNDUCKING_MARGIN
        if collider:
            collider.position.y = _default_collider_height - value * 0.5
            collider_capsul_height = _default_collider_capsul_height - value

@export var walk_speed: float = 2.0
@export var jump_velocity: float = 1.5
@export var duck_transition_msec: int = 700
@export var duck_speed_factor: float = 0.5

@export var collider: CollisionShape3D

@export var duck_ray: RayCast3D

@export var duck_height: float = 0.5:
    set(value):
        duck_height = value
        if duck_ray:
            duck_ray.position.y = character_height - duck_height + UNDUCKING_MARGIN
            duck_ray.target_position.y = value


var current_duck_height: float = 0:
    set(value):
        current_duck_height = value

        if collider:
            collider.position.y = _default_collider_height - value * 0.5
            collider_capsul_height = _default_collider_capsul_height - value

        if duck_ray:
            duck_ray.position.y = character_height - value + UNDUCKING_MARGIN
            duck_ray.target_position.y = value

        if cam:
            cam.position.y = _default_eye_height - value

const MOUSE_DEADZONE: float = 0.00
const MAX_PITCH_CAM: float = PI * 0.3

var _default_eye_height: float
var _default_collider_height: float
var _default_collider_capsul_height: float

enum DuckPhase { STANDING, DUCKING, DUCKED, UNDUCKING }
var _duck_phase: DuckPhase = DuckPhase.STANDING
var _duck_timer_t0: int
var duck_timer_progress: float:
    get():
        return clampf(float(Time.get_ticks_msec() - _duck_timer_t0) / float(duck_transition_msec), 0.0, 1.0)

func invert_duck_timer():
    var remain: int = roundi((1.0 - duck_timer_progress) * duck_transition_msec)
    _duck_timer_t0 = Time.get_ticks_msec() - remain

var collider_capsul_height: float:
    get():
        if !collider:
            return 0
        if collider.shape is CapsuleShape3D:
            return (collider.shape as CapsuleShape3D).height
        return 0

    set(value):
        if collider && collider.shape is CapsuleShape3D:
            (collider.shape as CapsuleShape3D).height = value

func _enter_tree() -> void:
    if !Engine.is_editor_hint():
        if SignalBus.on_pointer_interaction_update.connect(_handle_walking_sim_crosshair) != OK:
            push_error("Failed to connect walking sime interactable")
        if SignalBus.on_inspect_object.connect(_handle_inspect_object) != OK:
            push_error("Failed to connect inspect object")
        if SignalBus.on_complete_inspect_object.connect(_handle_complete_inspect_object) != OK:
            push_error("Failed to connect complete inspect object")
        if SignalBus.on_look_at_object.connect(_handle_look_at_object) != OK:
            push_error("Failed to connect look at object")
        if SignalBus.on_unlook_at_object.connect(_handle_unlook_at_object) != OK:
            push_error("Failed to connect unlook at object")

var _interactable: Interactable

func _handle_walking_sim_crosshair(hint: Interactable.Hint, interactable: Interactable) -> void:
    _interactable = interactable if hint == Interactable.Hint.INTERACTABLE else null

var _cam_tween: Tween

func _kill_tween(t: Tween) -> void:
    if t && t.is_running():
        t.kill()

func _handle_look_at_object(obj: Node3D, offset: Vector3, cinematic_follow: SignalBus.CinematicMode, ease_time: float = 1.0, callback: Variant = null) -> void:
    if !_cinematic_reasons.has(obj):
        _cinematic_reasons.append(obj)
    _kill_tween(_cam_tween)
    _cam_tween = create_tween()
    _cam_tween.set_parallel(true)

    match cinematic_follow:
        SignalBus.CinematicMode.INITIAL:
            _cam_tween.tween_property(cam, "global_position", obj.to_global(offset), ease_time).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
            _cam_tween.tween_method(
                QuaternionUtils.create_tween_static_lookat_method_non_rolling(cam, obj, offset),
                0.0,
                1.0,
                ease_time,
            )
        SignalBus.CinematicMode.DYNAMIC_TARGET:
            _cam_tween.tween_property(cam, "global_position", obj.to_global(offset), ease_time).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
            _cam_tween.tween_method(
                QuaternionUtils.create_tween_dynamic_lookat_method_non_rolling(cam, obj),
                0.0,
                1.0,
                ease_time,
            )
        SignalBus.CinematicMode.DYNAMIC_OFFSET:
            var origin: Vector3 = cam.global_position
            var rot_method: Callable = QuaternionUtils.create_tween_dynamic_lookat_method_non_rolling(cam, obj)
            _cam_tween.tween_method(
                func (progress: float) -> void:
                    cam.global_position = origin.lerp(obj.global_position + offset, progress)
                    rot_method.call(progress)
                    ,
                0.0,
                1.0,
                ease_time,
            )

    if callback is Callable:
        _cam_tween.finished.connect(callback as Callable)

func _handle_unlook_at_object(obj: Node3D, ease_time: float = 1.0, callback: Variant = null) -> void:
    _kill_tween(_cam_tween)
    _cam_tween = create_tween()
    var origin: Vector3 = cam.position
    var rot_method: Callable = QuaternionUtils.create_tween_rotation_progress_method(
        cam,
        cam.basis.get_rotation_quaternion(),
        Basis.IDENTITY.get_rotation_quaternion(),
        false,
    )

    _cam_tween.tween_method(
        func (progress: float) -> void:
            cam.position = origin.lerp(Vector3.UP * (_default_eye_height - current_duck_height), progress)
            rot_method.call(progress)
            ,
        0.0,
        1.0,
        ease_time
    )
    _cam_tween.finished.connect(
        func () -> void:
            _cinematic_reasons.erase(obj)
            if callback is Callable:
                (callback as Callable).call()
    )

var _inspected_root: Node3D

func _handle_inspect_object(obj: Node3D, _affirmative_verb: String, _affirmative_callback: Variant, _decline_verb: String, _decline_callback: Variant) -> void:
    if !_cinematic_reasons.has(obj):
        _cinematic_reasons.append(obj)

    var focus_distance: float = 0.25
    if obj is Interactable:
        var i: Interactable = obj
        _inspected_root = i.get_focus_item()
        focus_distance = i.focus_distance
    else:
        _inspected_root = obj


    if _inspected_root:
        var t: Tween = create_tween()
        t.set_parallel()

        var easing: Tween.EaseType = Tween.EaseType.EASE_OUT
        var trans: Tween.TransitionType = Tween.TransitionType.TRANS_BOUNCE
        var duration: float = 0.5

        var focus_pivot: Vector3 = cam.global_position + -cam.global_basis.z * focus_distance
        var target_basis: Basis = Basis(cam.global_basis.z, cam.global_basis.x, -cam.global_basis.y).rotated(cam.global_basis.y, 0.5 * PI)

        t.tween_property(_inspected_root, "global_position", focus_pivot, duration).set_ease(easing).set_trans(trans)
        t.tween_property(_inspected_root, "global_rotation", target_basis.get_euler(), duration).set_ease(easing).set_trans(trans)
        t.finished.connect(func () -> void:
            SignalBus.on_inspect_object_ready.emit(_inspected_root, cam)
        )


func _handle_complete_inspect_object(obj: Node3D) -> void:
    while _cinematic_reasons.has(obj):
        _cinematic_reasons.erase(obj)

    if _inspected_root == obj:
        _inspected_root = null

func _ready() -> void:
    if Engine.is_editor_hint():
        return

    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    if cam:
        _default_eye_height = cam.position.y
    if collider:
        _default_collider_height = collider.position.y
        _default_collider_capsul_height = collider_capsul_height

    duck_ray.enabled = false
    _last_pos = global_position

    ui_sounds.fade_out(10.0)

var _joy_look: Vector2
var _using_joy_look: bool
var _focusing: bool:
    set(value):
        var changed: bool = value != _focusing
        _focusing = value
        if changed && value:
            if _focusing_tween && _focusing_tween.is_running():
                _focusing_tween.kill()
            _focusing_tween = create_tween()
            _focusing_tween.tween_property(cam, "fov", VideoSettings.field_of_view * focus_fov_factor, focus_fov_ease_time).set_trans(Tween.TRANS_CIRC)
        elif changed:
            if _focusing_tween && _focusing_tween.is_running():
                _focusing_tween.kill()
            _focusing_tween = create_tween()
            _focusing_tween.tween_property(cam, "fov", VideoSettings.field_of_view, focus_fov_ease_time).set_trans(Tween.TRANS_CIRC)

var _focusing_tween: Tween

enum MuteState { NOTHING, MUSIC, ALL }
var _mute: MuteState = MuteState.NOTHING

func _input(event: InputEvent) -> void:
    if Engine.is_editor_hint():
        return

    GameSettings._input(event)

    if event.is_action_pressed(&"pause"):
        get_viewport().set_input_as_handled()
        SignalBus.on_pause_game.emit(true)

    if event.is_action_pressed(&"mute"):
        match _mute:
            MuteState.NOTHING:
                ui_sounds.visible = false
                ui_no_music.modulate = Color.WHITE
                ui_no_music.visible = true
                ui_no_music.fade_out(5.0)
                AudioHub.mute_bus(AudioHub.Bus.MUSIC)
                _mute = MuteState.MUSIC
            MuteState.MUSIC:
                ui_no_music.visible = false
                ui_no_sounds.modulate = Color.WHITE
                ui_no_sounds.visible = true
                ui_no_sounds.fade_out(5.0)
                AudioHub.mute_bus(AudioHub.Bus.MASTER)
                _mute = MuteState.ALL
            _:
                ui_sounds.modulate = Color.WHITE
                ui_sounds.visible = true
                ui_no_sounds.visible = false
                AudioHub.unmute_bus(AudioHub.Bus.MUSIC)
                AudioHub.unmute_bus(AudioHub.Bus.MASTER)
                ui_sounds.fade_out(5.0)
                _mute = MuteState.NOTHING

    if !cinematic:
        if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED && event is InputEventMouseButton:
            Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

        elif !look_locked && Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
            if event is InputEventMouseMotion:
                var m_event: InputEventMouseMotion = event
                var delta: Vector2 = m_event.relative
                var sense: float = GeneralSettings.scaled_mouse_sensitivity
                _process_rel_look(0.2 * Vector2(-delta.x * sense, delta.y * sense * skew_vertical_look_sense), GeneralSettings.mouse_inverted_y)


                _using_joy_look = false

                get_viewport().set_input_as_handled()

            else:
                var rel: Vector2 = Input.get_vector(&"player_look_right", &"player_look_left", &"player_look_up", &"player_look_down")
                var sense: float = GeneralSettings.scaled_joy_sensitivy
                _joy_look = Vector2(rel.x * sense, rel.y * sense * skew_vertical_look_sense)

                _using_joy_look = true

                get_viewport().set_input_as_handled()

        if allow_ducking && event.is_action_pressed(&"player_duck"):
            match _duck_phase:
                DuckPhase.STANDING:
                    _duck_timer_t0 = Time.get_ticks_msec()
                    _duck_phase = DuckPhase.DUCKING

                DuckPhase.DUCKED:
                    duck_ray.target_position.y = duck_height * 0.2
                    duck_ray.force_raycast_update()
                    if !duck_ray.is_colliding():
                        _duck_timer_t0 = Time.get_ticks_msec()
                        _duck_phase = DuckPhase.UNDUCKING

                DuckPhase.DUCKING:
                    duck_ray.target_position.y = duck_height
                    duck_ray.force_raycast_update()
                    if !duck_ray.is_colliding():
                        invert_duck_timer()
                        _duck_phase = DuckPhase.UNDUCKING

                DuckPhase.UNDUCKING:
                    invert_duck_timer()
                    _duck_phase = DuckPhase.DUCKING

        if event.is_action_pressed(&"player_interact"):
            if _interactable:
                _interactable.interact()

        if allow_focus:
            if !_focusing && event.is_action_pressed(&"player_focus"):
                _focusing = true
            elif _focusing && event.is_action_released(&"player_focus"):
                _focusing = false

func _process_rel_look(rel: Vector2, invert_y: bool) -> void:
        if abs(rel.x) > MOUSE_DEADZONE:
            rotate(up_direction, focus_effect * rel.x if _focusing else rel.x)
        if abs(rel.y) > MOUSE_DEADZONE:
            if _focusing:
                rel.y *= focus_effect
            if invert_y:
                cam.rotation = (cam.rotation - rel.y * Vector3.LEFT).clampf(-MAX_PITCH_CAM, MAX_PITCH_CAM)
            else:
                cam.rotation = (cam.rotation + rel.y * Vector3.LEFT).clampf(-MAX_PITCH_CAM, MAX_PITCH_CAM)

func _physics_process(delta: float) -> void:
    if Engine.is_editor_hint():
        return

    if cinematic:
        return

    # Add the gravity.
    if not is_on_floor():
        velocity += get_gravity() * delta

    else:
        # Handle jump.
        if Input.is_action_just_pressed("player_jump") && _duck_phase == DuckPhase.STANDING:
            velocity.y = jump_velocity

        match _duck_phase:
            DuckPhase.DUCKING:
                var progress: float = duck_timer_progress
                current_duck_height = lerpf(0.0, duck_height, progress)
                if progress == 1.0:
                    _duck_phase = DuckPhase.DUCKED

            DuckPhase.UNDUCKING:
                var progress: float = duck_timer_progress
                current_duck_height = lerpf(duck_height, 0.0, progress)

                if progress == 1.0:
                    _duck_phase = DuckPhase.STANDING
                else:
                    duck_ray.target_position.y = duck_height * minf(1.0 - progress, 0.2)
                    duck_ray.force_raycast_update()
                    if duck_ray.is_colliding():
                        _duck_phase = DuckPhase.DUCKING
                        invert_duck_timer()

    if _using_joy_look && _joy_look != Vector2.ZERO:
        _process_rel_look(_joy_look * delta, GeneralSettings.joy_inverted_y)


    var input_dir: Vector2 = Input.get_vector(&"player_strafe_left", &"player_strafe_right", &"player_forward", &"player_backward")
    var direction: Vector3 = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
    var speed: float = walk_speed if _duck_phase == DuckPhase.STANDING else walk_speed * duck_speed_factor
    if _focusing:
        speed *= focus_effect

    if direction:
        velocity.x = direction.x * speed
        velocity.z = direction.z * speed
    else:
        velocity.x = move_toward(velocity.x, 0, speed)
        velocity.z = move_toward(velocity.z, 0, speed)

    move_and_slide()

var _last_pos: Vector3
var _dist: float
var _next_footfall: int = 0

func _process(_delta: float) -> void:
    if Engine.is_editor_hint() || footfalls.is_empty():
        return

    if is_on_floor():
        _dist += _last_pos.distance_to(global_position)
        _last_pos = global_position
        if _dist > footfall_distance:
            _dist = 0
            AudioHub.play_sfx(footfalls[_next_footfall], randf_range(0.6, 0.8))
            _next_footfall += 1
            if _next_footfall >= footfalls.size():
                _next_footfall = 0
