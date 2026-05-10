# Chicken Boss Easter Egg — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Adicionar um mini-boss secreto (ChickenBoss) escondido num canto da Fase 1; ao encontrá-lo a wave pausa, a luta começa, e ao vencer a wave retoma com 50 fragmentos de bônus.

**Architecture:** `ChickenBoss.gd` extende `GalinhaPodre.gd` e gerencia seu próprio trigger de proximidade; `WaveManager.gd` recebe sinais `boss_triggered`/`boss_defeated` e pausa/retoma a wave sem tocar na lógica de progressão de área; `World.gd` instancia o boss condicionalmente na área 1.

**Tech Stack:** Godot 4.6 GDScript, Area2D, CircleShape2D, CPUParticles2D (já em uso no projeto)

---

## Mapa de arquivos

| Arquivo | Ação | O que muda |
|---|---|---|
| `scripts/ChickenBoss.gd` | **Criar** | Script completo do boss secreto |
| `scripts/WaveManager.gd` | **Modificar** | +4 vars, +2 métodos, +2 guards |
| `scripts/World.gd` | **Modificar** | +`_spawn_chicken_boss()` + chamada condicional |

---

## Task 1: Criar `scripts/ChickenBoss.gd`

**Files:**
- Create: `scripts/ChickenBoss.gd`

- [ ] **Criar o arquivo com o script completo**

```gdscript
# scripts/ChickenBoss.gd
extends "res://scripts/GalinhaPodre.gd"

signal boss_triggered
signal boss_defeated

const BOSS_RADIUS    := 22.0
const TRIGGER_RADIUS := 120.0

var _triggered    := false
var _trigger_zone : Area2D

func _ready() -> void:
	MAX_HEALTH    = 200.0
	DAMAGE        = 25.0
	MOVE_SPEED    = 200.0
	xp_reward     = 80.0
	current_health = MAX_HEALTH
	super._ready()
	(_col_shape.shape as CircleShape2D).radius = BOSS_RADIUS
	_build_trigger_zone()
	set_physics_process(false)

func _build_trigger_zone() -> void:
	_trigger_zone = Area2D.new()
	_trigger_zone.collision_layer = 0
	_trigger_zone.collision_mask  = 1
	var tz_shape   := CollisionShape2D.new()
	var tz_circle  := CircleShape2D.new()
	tz_circle.radius = TRIGGER_RADIUS
	tz_shape.shape   = tz_circle
	_trigger_zone.add_child(tz_shape)
	_trigger_zone.body_entered.connect(_on_trigger_entered)
	add_child(_trigger_zone)

func _on_trigger_entered(body: Node) -> void:
	if _triggered or not body.is_in_group("player"):
		return
	_triggered = true
	_trigger_zone.set_deferred("monitoring", false)
	set_physics_process(true)
	boss_triggered.emit()

func _die() -> void:
	is_dead = true
	_player = null
	set_physics_process(false)
	_col_shape.set_deferred("disabled", true)
	ProgressionManager.add_xp(xp_reward)
	ProgressionManager.add_fragments(50)
	AudioManager.play_sfx("enemy_die")
	JuiceManager.spawn_blood(global_position, get_parent())
	JuiceManager.apply_hitstop(0.12)
	JuiceManager.add_trauma(0.5)
	boss_defeated.emit()
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(queue_free)

func _draw() -> void:
	if not is_dead:
		draw_circle(Vector2.ZERO, BOSS_RADIUS, Color(1.0, 0.85, 0.1, 0.95))
		draw_arc(Vector2.ZERO, BOSS_RADIUS + 4.0, 0.0, TAU, 32, Color(1.0, 0.6, 0.0, 0.6), 2.0)
	if is_dead or current_health >= MAX_HEALTH:
		return
	var x := -BAR_W / 2.0
	draw_rect(Rect2(x, BAR_Y, BAR_W, BAR_H), Color(0.15, 0.0, 0.0, 0.85))
	var fill := BAR_W * (current_health / MAX_HEALTH)
	draw_rect(Rect2(x, BAR_Y, fill, BAR_H), Color(1.0, 0.7, 0.0, 1.0))
```

- [ ] **Verificar parse do script no terminal (Godot headless)**

```
# Se não tiver Godot no PATH, apenas confirmar que o arquivo existe e tem sintaxe correta relendo
# A verificação real é rodar o jogo — Godot vai apontar erros de parse na saída
```

- [ ] **Commit**

```bash
git add scripts/ChickenBoss.gd
git commit -m "feat(easter-egg): cria ChickenBoss com trigger de proximidade e recompensa de 50 fragmentos"
```

---

## Task 2: Modificar `scripts/WaveManager.gd`

**Files:**
- Modify: `scripts/WaveManager.gd`

As mudanças são quatro blocos independentes. Aplicar na ordem abaixo.

- [ ] **Adicionar as 4 novas variáveis após a linha `var _frenzy_active := false`**

Localizar (linha ~39):
```gdscript
var _frenzy_active  := false
```
Substituir por:
```gdscript
var _frenzy_active       := false
var _chicken_boss_active := false
var _chicken_defeated    := false
var _saved_wave          := 0
var _saved_alive_count   := 0
```

- [ ] **Adicionar guard em `_process` para pausar o timer durante a luta com o boss secreto**

Localizar (linha ~167):
```gdscript
func _process(delta: float) -> void:
	if not _combat_active or _frenzy_active or _boss_alive:
		return
```
Substituir por:
```gdscript
func _process(delta: float) -> void:
	if not _combat_active or _frenzy_active or _boss_alive or _chicken_boss_active:
		return
```

- [ ] **Adicionar guard em `_check_wave_clear` para não limpar a wave enquanto o boss secreto estiver ativo**

Localizar (linha ~135):
```gdscript
func _check_wave_clear() -> void:
	if not is_inside_tree():
		return
	var alive := get_tree().get_nodes_in_group("active_enemies").size()
```
Substituir por:
```gdscript
func _check_wave_clear() -> void:
	if not is_inside_tree():
		return
	if _chicken_boss_active:
		return
	var alive := get_tree().get_nodes_in_group("active_enemies").size()
```

- [ ] **Adicionar os dois novos métodos ao final do arquivo (antes da última linha)**

Localizar o final do arquivo (última função `_on_boss_died`):
```gdscript
func _on_boss_died() -> void:
	_boss_alive = false
	var player := get_tree().get_first_node_in_group("player") if is_inside_tree() else null
	if player == null or player.is_dead:
		return
	area_cleared.emit()
```
Após esse bloco, adicionar:
```gdscript

func suspend_for_chicken_boss() -> void:
	_saved_wave        = current_wave
	_saved_alive_count = get_tree().get_nodes_in_group("active_enemies").size()
	_chicken_boss_active = true
	_combat_active       = false
	for enemy in get_tree().get_nodes_in_group("active_enemies"):
		enemy.queue_free()

func resume_after_chicken_boss() -> void:
	_chicken_boss_active = false
	_chicken_defeated    = true
	if _saved_alive_count == 0:
		wave_cleared.emit(_saved_wave)
		return
	var multiplier := pow(DIFFICULTY_CURVE, _saved_wave - 1)
	for i in _saved_alive_count:
		var is_knight  := _saved_wave >= 3 and i % 3 == 2
		var is_galinha := not is_knight and _saved_wave >= 2 and i % 4 == 3
		if is_knight:
			_spawn_knight(i, multiplier)
		elif is_galinha:
			_spawn_galinha(i, multiplier)
		else:
			_spawn_skeleton(i, multiplier)
	if _frenzy_active:
		for enemy in get_tree().get_nodes_in_group("active_enemies"):
			if enemy.has_method("apply_frenzy"):
				enemy.apply_frenzy()
	_alive_count   = _saved_alive_count
	_combat_active = true
```

- [ ] **Commit**

```bash
git add scripts/WaveManager.gd
git commit -m "feat(easter-egg): WaveManager suporta suspender/retomar wave para o ChickenBoss"
```

---

## Task 3: Modificar `scripts/World.gd`

**Files:**
- Modify: `scripts/World.gd`

- [ ] **Adicionar chamada condicional de spawn após a linha `_wave_manager.init(self)` em `_ready()`**

Localizar (linha ~37):
```gdscript
	_wave_manager.init(self)
	_wave_manager.wave_cleared.connect(_on_wave_cleared)
```
Substituir por:
```gdscript
	_wave_manager.init(self)
	if ProgressionManager.get_current_area() == 1:
		_spawn_chicken_boss()
	_wave_manager.wave_cleared.connect(_on_wave_cleared)
```

- [ ] **Adicionar o método `_spawn_chicken_boss()` no final de `World.gd` (antes do último método ou ao final do arquivo)**

Localizar o final do arquivo e adicionar:
```gdscript

func _spawn_chicken_boss() -> void:
	var boss = load("res://scripts/ChickenBoss.gd").new()
	# Isometric Vector2i(15, 108) → canto inferior-esquerdo da Fase 1, longe dos spawn zones (35-90)
	boss.position = Vector2(-1488.0, 984.0)
	boss.add_to_group("chicken_boss")
	boss.boss_triggered.connect(_wave_manager.suspend_for_chicken_boss)
	boss.boss_defeated.connect(_wave_manager.resume_after_chicken_boss)
	add_child(boss)
```

- [ ] **Commit**

```bash
git add scripts/World.gd
git commit -m "feat(easter-egg): World spawna ChickenBoss no canto inferior-esquerdo da Fase 1"
```

---

## Task 4: Verificação manual no jogo

- [ ] **Rodar o jogo na Fase 1 e confirmar que o boss existe**

  Abrir o jogo → iniciar partida → apertar `F11` para fullscreen → mover o player para a esquerda do mapa até a coordenada (-1488, 984). O boss deve aparecer como um círculo dourado com contorno laranja.

- [ ] **Verificar que o trigger funciona**

  Aproximar até ~120px do boss. Os inimigos da wave ativa devem desaparecer e o boss deve começar a perseguir o player.

- [ ] **Verificar que a luta funciona**

  Atacar o boss com melee (LMB) e skills (Q/E). A barra de vida dourada deve aparecer quando o boss toma dano. O boss deve morrer após receber ~200 de dano total.

- [ ] **Verificar a recompensa**

  Ao matar o boss, o contador de fragmentos no HUD deve aumentar em 50. Verificar também que os inimigos da wave anterior reaparecem (ou a wave avança se já estava com 0 inimigos).

- [ ] **Verificar que o boss NÃO aparece na Fase 2 e 3**

  Avançar para a Fase 2 (derrotar o boss principal da Fase 1) e confirmar que não há círculo dourado no mapa.

- [ ] **Commit final de verificação (se nenhuma correção foi necessária)**

```bash
git add -p  # só se houver algum ajuste menor
git commit -m "fix(easter-egg): ajustes pós-verificação manual"
```

---

## Notas de implementação

**Por que `set_physics_process(false)` em `_ready()`?**
O boss fica parado até ser encontrado — `GalinhaPodre._physics_process` (que faz o chase) só roda depois que `boss_triggered` dispara.

**Por que `_chicken_boss_active` antes de `queue_free` nos inimigos?**
O `tree_exited` de cada inimigo chama `_on_enemy_died` → `_check_wave_clear`. Se o flag não estiver setado antes do queue_free, a wave vai limpar prematuramente.

**Por que `call_deferred("monitoring", false)` no trigger zone?**
Evita o erro "Cannot change property during physics callback" ao desabilitar o trigger dentro de um callback de física.

**Posição do boss — `Vector2(-1488.0, 984.0)`:**
Coordenada isométrica `Vector2i(15, 108)` → `((15-108)*16, (15+108)*8)`. Os spawn zones da wave usam coords 35-90; esta posição está fora dessa faixa, no canto inferior-esquerdo do mapa 120×120.
