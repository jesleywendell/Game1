extends CharacterBody2D

@export var speed: float = 200.0

func _physics_process(_delta: float) -> void:
	var move_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = move_dir * speed
	move_and_slide()
