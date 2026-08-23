extends Node
class_name MetricsAndAnalyticsConsent

@export var yes_btn: Button
@export var no_btn: Button

var callback: Variant

func _ready() -> void:
    yes_btn.grab_focus()

func _on_yes_pressed() -> void:
    GeneralSettings.analytics_consent = GeneralSettings.Consent.YES
    if callback is Callable:
        callback.call()

func _on_no_pressed() -> void:
    GeneralSettings.analytics_consent = GeneralSettings.Consent.NO
    if callback is Callable:
        callback.call()
