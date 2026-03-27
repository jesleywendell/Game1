extends Area2D

const SPEED := 400.0
const LIFETIME := 2.0

var direction := Vector2.RIGHT
var damage := 1.5
var source: Node = null
var _lifetime_timer := 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 6.0, Color.YELLOW)

func _physics_process(delta: float) -> void:
	position += direction * SPEED * delta
	_lifetime_timer += delta
	if _lifetime_timer >= LIFETIME:
		queue_free()

func _on_body_entered(body: Node) -> void:
	_hit(body)

func _hit(target: Node) -> void:
	if target == source:
		return
	if target.has_method("take_damage"):
		target.take_damage(damage, direction)
	elif target.has_method("receive_hit"):
		target.receive_hit(damage, direction)
	queue_free()
