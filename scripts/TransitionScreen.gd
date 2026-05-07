extends CanvasLayer

var _rect: ColorRect
var _is_transitioning := false

func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rect = ColorRect.new()
	_rect.color = Color(0.0, 0.0, 0.0, 0.0)
	_rect.anchors_preset = Control.PRESET_FULL_RECT
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_rect)

func fade_to(scene_path: String) -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	var tween := create_tween()
	tween.tween_property(_rect, "color:a", 1.0, 0.35).set_ease(Tween.EASE_IN)
	tween.tween_callback(func():
		get_tree().paused = false
		get_tree().change_scene_to_file(scene_path)
	)
	tween.tween_interval(0.1)
	tween.tween_property(_rect, "color:a", 0.0, 0.45).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func(): _is_transitioning = false)
