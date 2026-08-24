extends Node
class_name _SignalBus

@warning_ignore_start("unused_signal")
signal on_pause_game(paused: bool)

# Input
signal on_change_input_method(input_method: BindingSettings.InputMethod)

# Cursor
signal on_pointer_visible(visible: bool)
signal on_pointer_captured(captured: bool)
signal on_pointer_interaction_update(hint: Interactable.Hint, interactable: Interactable)
signal on_interactable_action_change(interactable: Interactable)
signal on_interactable_action_name_change(action: InteractableAction)
enum PointerSetting { SIZE, ALPHA, TEXT_SIZE }
signal on_update_pointer_setting(setting: PointerSetting, value: Variant)
signal on_abort_interaction()
signal on_pointer_over(col: CollisionObject3D)

# Settings
#signal on_update_input_mode(method: BindingHints.InputMode)
signal on_update_handedness(handedness: GeneralSettings.Handedness)
signal on_update_mouse_y_inverted(inverted: bool)
signal on_update_mouse_sensitivity(sensistivity: float)
signal on_update_joy_y_inverted(inverted: bool)
signal on_update_joy_sensitivity(sensistivity: float)
signal on_update_motion_sickness(motion_sickness: GeneralSettings.MotionSickness)
signal on_update_fov(fov: float)

# A11Y systems
signal on_subtitle(data: SubData)
signal on_clear_queued_subtitles(subs: Array[SubData])
signal on_clear_all_queued_subtitles()
signal on_toggle_subtitles(enabled: bool)
signal on_change_subtitles_size(size: int)
signal on_change_whisper_muting(mute_priority: int)

# FPS actions
signal on_inspect_object(obj: Node3D, affirmative_verb: String, affirmative_callback: Variant, decline_verb: String, decline_callback: Variant)
signal on_inspect_object_ready(obj: Node3D, cam: Camera3D)
signal on_complete_inspect_object(obj: Node3D)
enum CinematicMode { INITIAL, DYNAMIC_TARGET, DYNAMIC_OFFSET }
signal on_look_at_object(obj: Node3D, offset: Vector3, cinematic_follow: CinematicMode, ease_time: float, callback: Variant)
signal on_unlook_at_object(obj: Node3D, ease_time: float, callback: Variant)

# Rooms
signal on_enter_room(room: Room, direction: Vector2i)
signal on_leave_room(room: Room, correct: bool, direction: Vector2i)
