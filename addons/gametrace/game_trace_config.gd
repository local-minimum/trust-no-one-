class_name GameTraceConfig
extends Resource
## Configuration for the GameTrace SDK.
## Create an instance, set your credentials, and pass it to GameTrace.initialize().

## Required. Your project's API key (found on the project detail page).
@export var api_key: String = ""

## Required. Your project ID (found on the project detail page).
@export var project_id: String = ""

## Seconds between automatic flush cycles. Default: 5.0
@export var flush_interval: float = 5.0

## Number of events per batch. A flush triggers when this count is reached. Default: 20
@export var batch_size: int = 20

## Maximum queued events. Oldest events are dropped when the queue is full. Default: 1000
@export var max_queue_size: int = 1000

## Automatically capture device/engine context with each event. Default: true
@export var auto_capture: bool = true

## Your game's build version string, e.g. "1.2.3". Sent with every event.
@export var app_version: String = ""

## API endpoint URL. Override for self-hosted or development servers.
@export var endpoint: String = "https://gametrace.io/api/v1/events"

## Log SDK activity to the Godot output console. Default: false
@export var debug: bool = false
