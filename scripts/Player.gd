extends CharacterBody2D

# ─────────────────────────────────────────────
#  Configuração
# ─────────────────────────────────────────────
@export var speed: float = 200.0

# Vetores de direção em espaço de TELA para projeção isométrica 2:1
# A câmera isométrica faz W/S/A/D moverem em diagonais na tela
const DIR_NW := Vector2(-2.0, -1.0)  # W  → cima-esquerda
const DIR_SE := Vector2( 2.0,  1.0)  # S  → baixo-direita
const DIR_SW := Vector2(-2.0,  1.0)  # A  → baixo-esquerda
const DIR_NE := Vector2( 2.0, -1.0)  # D  → cima-direita

# ─────────────────────────────────────────────
#  Loop de física
# ─────────────────────────────────────────────
func _physics_process(_delta: float) -> void:
	var move_dir := Vector2.ZERO

	if Input.is_action_pressed("move_up"):    move_dir += DIR_NW
	if Input.is_action_pressed("move_down"):  move_dir += DIR_SE
	if Input.is_action_pressed("move_left"):  move_dir += DIR_SW
	if Input.is_action_pressed("move_right"): move_dir += DIR_NE

	if move_dir != Vector2.ZERO:
		velocity = move_dir.normalized() * speed
	else:
		velocity = Vector2.ZERO

	move_and_slide()
