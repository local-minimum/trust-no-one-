class_name GameAnalytics

static func initialize(settings: Dictionary) -> void:
    if DictionaryUtils.safe_getb(settings, "analytics", false, false):
        var key: String = DictionaryUtils.safe_gets(settings, "analytics.api_key")
        var project_id: String = DictionaryUtils.safe_gets(settings, "analytics.project_id")
        if key.is_empty() || project_id.is_empty():
            return

        var config = GameTraceConfig.new()
        config.api_key = key
        config.project_id = project_id
        config.auto_capture = false
        GameTrace.initialize(config)
        GameTrace.identify("player")
        print_debug("Analytics ready")
    else:
        push_warning("No analytics configured")

static func track(event: String, payload: Dictionary = {}) -> void:
    if GeneralSettings.analytics_consent == GeneralSettings.Consent.YES && !event.is_empty() && GameTrace.is_initialized():
        GameTrace.track(event, payload)
