class_name GameMenuButton
extends Button

signal activated

var _tween: Tween

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		pivot_offset = size / 2.0

func _ready() -> void:
	mouse_entered.connect(_on_hover)
	mouse_exited.connect(_on_unhover)
	button_down.connect(_on_press)
	button_up.connect(_on_release)

func _on_hover() -> void:
	_animate(Vector2(1.05, 1.05), Color(1.3, 1.3, 1.3), 0.12)

func _on_unhover() -> void:
	_animate(Vector2(1.0, 1.0), Color(1.0, 1.0, 1.0), 0.10)

func _on_press() -> void:
	_kill_tween()
	_tween = create_tween()
	_tween.tween_property(self, "scale", Vector2(0.95, 0.95), 0.05).set_ease(Tween.EASE_OUT)

func _on_release() -> void:
	_kill_tween()
	_tween = create_tween()
	_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.08).set_ease(Tween.EASE_OUT)
	_tween.tween_callback(func(): activated.emit())

func _animate(target_scale: Vector2, target_color: Color, duration: float) -> void:
	_kill_tween()
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(self, "scale", target_scale, duration).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "modulate", target_color, duration)

func _kill_tween() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
