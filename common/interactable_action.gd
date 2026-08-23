@abstract
extends Node
class_name InteractableAction

@export var action_name: String:
    set(value):
        action_name = value
        SignalBus.on_interactable_action_name_change.emit(self)

@abstract func perform(interactable: Interactable) -> void
@abstract func abort(interactable: Interactable) -> void
