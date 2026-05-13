extends CanvasLayer

var _canvas: Control
var _frame := 0

func _ready() -> void:
	layer = 3
	_canvas = Control.new()
	_canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_canvas)
	_canvas.draw.connect(_on_draw)

func _process(_delta: float) -> void:
	_frame = (_frame + 1) % 3
	if _frame != 0:
		return
	_canvas.queue_redraw()

func _on_draw() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	var player    := players[0] as Node2D
	var vp        := get_viewport().get_visible_rect().size
	var xform     := player.get_viewport().get_canvas_transform()
	var inset     := 32.0

	for enemy in get_tree().get_nodes_in_group("active_enemies"):
		if not is_instance_valid(enemy):
			continue
		var sp := xform * (enemy as Node2D).global_position

		# Already visible — no indicator needed
		if sp.x > inset and sp.x < vp.x - inset and sp.y > inset and sp.y < vp.y - inset:
			continue

		var dir  := (sp - vp * 0.5).normalized()
		var edge := _edge_pos(dir, vp, inset)
		var is_boss: bool = enemy.get("is_boss") == true

		if is_boss:
			_draw_arrow(edge, dir, 11.0, Color(1.00, 0.45, 0.05, 0.95))
			# Extra outer ring for boss to make it stand out
			_draw_arrow(edge, dir, 15.0, Color(1.00, 0.20, 0.00, 0.35))
		else:
			_draw_arrow(edge, dir, 9.0, Color(0.95, 0.15, 0.15, 0.82))

# Returns the point on the screen border in direction `dir` from screen centre
func _edge_pos(dir: Vector2, vp: Vector2, inset: float) -> Vector2:
	var half := vp * 0.5
	var t    := INF
	if abs(dir.x) > 1e-4:
		t = minf(t, (half.x - inset) / abs(dir.x))
	if abs(dir.y) > 1e-4:
		t = minf(t, (half.y - inset) / abs(dir.y))
	return half + dir * t

func _draw_arrow(pos: Vector2, dir: Vector2, size: float, color: Color) -> void:
	var perp := Vector2(-dir.y, dir.x)
	var tip  := pos + dir * size
	var bl   := pos - dir * (size * 0.55) + perp * (size * 0.82)
	var br   := pos - dir * (size * 0.55) - perp * (size * 0.82)
	_canvas.draw_colored_polygon(PackedVector2Array([tip, bl, br]), color)
	_canvas.draw_polyline(
		PackedVector2Array([tip, bl, br, tip]),
		Color(0.0, 0.0, 0.0, 0.55), 1.5, true
	)
