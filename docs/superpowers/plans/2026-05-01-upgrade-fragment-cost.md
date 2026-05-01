# Upgrade Fragment Cost — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Substituir `skill_points` gratuitos por custos em fragmentos da alma com escalada quadrática por tipo de upgrade, e remover a loja do hub.

**Architecture:** A fórmula `custo = base + escala × n²` fica em `ProgressionManager` como método `get_upgrade_cost(attribute)`. `UpgradePanel` consulta esse método para exibir custos e habilitar/desabilitar botões. `apply_upgrade()` passa a chamar `spend_fragments()` em vez de decrementar `skill_points`.

**Tech Stack:** Godot 4.6, GDScript

---

## Mapa de arquivos

| Arquivo | Mudança |
|---|---|
| `scripts/PlayerData.gd` | Remover `skill_points` e `dash_cd_upgrades` |
| `scripts/ProgressionManager.gd` | Adicionar constantes de custo + `get_upgrade_cost()`, atualizar `apply_upgrade()`, remover métodos do hub |
| `scripts/UpgradePanel.gd` | Exibir fragmentos/custos, desabilitar botões, botão Fechar |
| `scripts/Player.gd` | Remover chamada a `get_dash_cd_reduction()` |
| `scripts/Hub.gd` | Remover seção da loja (shop panel) |

---

## Task 1: Limpar PlayerData.gd

**Files:**
- Modify: `scripts/PlayerData.gd`

- [ ] **Step 1: Remover campos obsoletos**

Abrir `scripts/PlayerData.gd` e deixar o arquivo assim:

```gdscript
extends Resource
class_name PlayerData

@export var level: int = 1
@export var current_xp: float = 0.0
@export var attack_damage_upgrades: int = 0
@export var skill_damage_upgrades: int = 0
@export var speed_upgrades: int = 0
@export var max_health_upgrades: int = 0
@export var soul_fragments: int = 0
```

Campos removidos: `skill_points`, `dash_cd_upgrades`.

- [ ] **Step 2: Commit**

```bash
git add scripts/PlayerData.gd
git commit -m "refactor(data): remove skill_points e dash_cd_upgrades de PlayerData"
```

---

## Task 2: Atualizar ProgressionManager.gd

**Files:**
- Modify: `scripts/ProgressionManager.gd`

- [ ] **Step 1: Substituir o conteúdo completo do arquivo**

```gdscript
extends Node

const SAVE_PATH   := "user://player_data.tres"
const BASE_XP     := 100.0
const XP_EXPONENT := 1.5

const ATTACK_DMG_BONUS := 5.0
const SKILL_DMG_BONUS  := 8.0
const SPEED_BONUS      := 15.0
const MAX_HEALTH_BONUS := 20.0

# Custo quadratico por tipo: custo(n) = base + escala * n^2
# n = upgrades ja comprados daquele tipo
const UPGRADE_BASE := {
	"attack_damage": 10,
	"skill_damage":  12,
	"speed":         8,
	"max_health":    6,
}
const UPGRADE_SCALE := {
	"attack_damage": 5,
	"skill_damage":  6,
	"speed":         4,
	"max_health":    3,
}

signal xp_changed(current: float, required: float)
signal leveled_up(new_level: int)
signal upgrade_applied
signal fragments_changed(total: int)

var data: PlayerData

func _ready() -> void:
	_load()

func _load() -> void:
	if ResourceLoader.exists(SAVE_PATH):
		data = ResourceLoader.load(SAVE_PATH) as PlayerData
	if data == null:
		data = PlayerData.new()

func save() -> void:
	ResourceSaver.save(data, SAVE_PATH)

func reset() -> void:
	data = PlayerData.new()
	save()

func xp_required(level: int) -> float:
	return BASE_XP * pow(level, XP_EXPONENT)

func add_xp(amount: float) -> void:
	data.current_xp += amount
	var required := xp_required(data.level)
	while data.current_xp >= required:
		data.current_xp -= required
		data.level += 1
		required = xp_required(data.level)
		leveled_up.emit(data.level)
	xp_changed.emit(data.current_xp, xp_required(data.level))
	save()

func get_upgrade_count(attribute: String) -> int:
	match attribute:
		"attack_damage": return data.attack_damage_upgrades
		"skill_damage":  return data.skill_damage_upgrades
		"speed":         return data.speed_upgrades
		"max_health":    return data.max_health_upgrades
	return 0

func get_upgrade_cost(attribute: String) -> int:
	var n := get_upgrade_count(attribute)
	return UPGRADE_BASE[attribute] + UPGRADE_SCALE[attribute] * n * n

func apply_upgrade(attribute: String) -> void:
	var cost := get_upgrade_cost(attribute)
	if not spend_fragments(cost):
		return
	match attribute:
		"attack_damage": data.attack_damage_upgrades += 1
		"skill_damage":  data.skill_damage_upgrades  += 1
		"speed":         data.speed_upgrades         += 1
		"max_health":    data.max_health_upgrades    += 1
	upgrade_applied.emit()
	save()

func get_attack_damage(base: float) -> float:
	return base + data.attack_damage_upgrades * ATTACK_DMG_BONUS

func get_skill_damage_bonus() -> float:
	return data.skill_damage_upgrades * SKILL_DMG_BONUS

func get_speed(base: float) -> float:
	return base + data.speed_upgrades * SPEED_BONUS

func get_max_health(base: float) -> float:
	return base + data.max_health_upgrades * MAX_HEALTH_BONUS

func add_fragments(amount: int) -> void:
	data.soul_fragments += amount
	save()
	fragments_changed.emit(data.soul_fragments)

func spend_fragments(amount: int) -> bool:
	if data.soul_fragments < amount:
		return false
	data.soul_fragments -= amount
	save()
	fragments_changed.emit(data.soul_fragments)
	return true

func get_fragments() -> int:
	return data.soul_fragments
```

- [ ] **Step 2: Verificar que a fórmula bate com a tabela do spec**

Confirmar mentalmente:
- `get_upgrade_cost("attack_damage")` com n=0 → 10 + 5×0 = **10** ✓
- `get_upgrade_cost("attack_damage")` com n=1 → 10 + 5×1 = **15** ✓
- `get_upgrade_cost("max_health")` com n=2 → 6 + 3×4 = **18** ✓

- [ ] **Step 3: Commit**

```bash
git add scripts/ProgressionManager.gd
git commit -m "feat(progression): sistema de custo quadratico de fragmentos para upgrades"
```

---

## Task 3: Atualizar UpgradePanel.gd

**Files:**
- Modify: `scripts/UpgradePanel.gd`

- [ ] **Step 1: Substituir o conteúdo completo do arquivo**

```gdscript
extends CanvasLayer

const UPGRADES := [
	{"key": "attack_damage", "label": "Dano do Ataque",  "desc": "+5 dano"},
	{"key": "skill_damage",  "label": "Dano das Skills", "desc": "+8 dano"},
	{"key": "speed",         "label": "Velocidade",      "desc": "+15 vel"},
	{"key": "max_health",    "label": "Vida Maxima",     "desc": "+20 vida"},
]

var _title: Label
var _frag_label: Label
var _buttons: Array[Button] = []

func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	hide()
	ProgressionManager.leveled_up.connect(_on_leveled_up)

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.82)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	bg.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(bg)

	var root := CenterContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(root)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	vbox.process_mode = Node.PROCESS_MODE_ALWAYS
	root.add_child(vbox)

	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 36)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.modulate = Color(1.0, 0.88, 0.2)
	vbox.add_child(_title)

	_frag_label = Label.new()
	_frag_label.add_theme_font_size_override("font_size", 18)
	_frag_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_frag_label.modulate = Color(0.6, 0.9, 1.0)
	vbox.add_child(_frag_label)

	var sep := Control.new()
	sep.custom_minimum_size = Vector2(0, 12)
	vbox.add_child(sep)

	for upgrade in UPGRADES:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(360, 68)
		btn.add_theme_font_size_override("font_size", 20)
		btn.process_mode = Node.PROCESS_MODE_ALWAYS
		btn.pressed.connect(_on_upgrade_chosen.bind(upgrade["key"]))
		vbox.add_child(btn)
		_buttons.append(btn)

	var sep2 := Control.new()
	sep2.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(sep2)

	var close_btn := Button.new()
	close_btn.custom_minimum_size = Vector2(200, 48)
	close_btn.add_theme_font_size_override("font_size", 16)
	close_btn.text = "Fechar"
	close_btn.modulate = Color(0.7, 0.7, 0.7)
	close_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	close_btn.pressed.connect(_close)
	vbox.add_child(close_btn)

func _refresh() -> void:
	_title.text = "NIVEL %d" % ProgressionManager.data.level
	var frags := ProgressionManager.get_fragments()
	_frag_label.text = "Fragmentos da Alma: %d" % frags

	for i in _buttons.size():
		var key: String = UPGRADES[i]["key"]
		var cost := ProgressionManager.get_upgrade_cost(key)
		var can_afford := frags >= cost
		var btn := _buttons[i]
		btn.text = "%s  (%s)  —  %d fragmentos" % [
			UPGRADES[i]["label"],
			UPGRADES[i]["desc"],
			cost,
		]
		btn.disabled = not can_afford
		btn.modulate = Color(1, 1, 1) if can_afford else Color(1, 0.35, 0.35)

func _on_leveled_up(_new_level: int) -> void:
	_refresh()
	get_tree().paused = true
	show()

func _on_upgrade_chosen(attribute: String) -> void:
	ProgressionManager.apply_upgrade(attribute)
	_close()

func _close() -> void:
	get_tree().paused = false
	hide()
```

- [ ] **Step 2: Commit**

```bash
git add scripts/UpgradePanel.gd
git commit -m "feat(ui): UpgradePanel mostra custos em fragmentos e desabilita botoes inacessiveis"
```

---

## Task 4: Remover get_dash_cd_reduction de Player.gd

**Files:**
- Modify: `scripts/Player.gd`

- [ ] **Step 1: Localizar e corrigir a linha de dash_cooldown**

Em `scripts/Player.gd` linha ~73, trocar:

```gdscript
dash_cooldown = maxf(0.3, _base_dash_cooldown - _temp_dash_cd_bonus - ProgressionManager.get_dash_cd_reduction())
```

Por:

```gdscript
dash_cooldown = maxf(0.3, _base_dash_cooldown - _temp_dash_cd_bonus)
```

- [ ] **Step 2: Commit**

```bash
git add scripts/Player.gd
git commit -m "refactor(player): remove dependencia de get_dash_cd_reduction removido do ProgressionManager"
```

---

## Task 5: Remover loja do Hub.gd

**Files:**
- Modify: `scripts/Hub.gd`

- [ ] **Step 1: Localizar a constante UPGRADE_DEFS e o método de shop**

Procurar por `UPGRADE_DEFS`, `_open_shop`, `_refresh_shop`, `buy_hub_upgrade` em `Hub.gd`.

- [ ] **Step 2: Remover ou neutralizar o shop**

Apagar o array `UPGRADE_DEFS`, o método `_open_shop()` (ou equivalente), o método `_refresh_shop()`, e qualquer botão que chame `_open_shop`. Se o Hub tiver outros painéis (NPC de diálogo, etc.), mantê-los intactos.

Se o Hub inteiro for somente a loja, apagar o arquivo `Hub.gd` e verificar se `Hub.tscn` existe:

```bash
# verificar
ls scenes/ | grep -i hub
```

Se `Hub.tscn` existir e não for usado por nenhuma outra cena, pode deixar desconectado (não referenciado por nenhum autoload ou World.gd) — não precisa deletar o arquivo agora.

- [ ] **Step 3: Commit**

```bash
git add scripts/Hub.gd
git commit -m "refactor(hub): remove loja de upgrades permanentes substituida pelo sistema de fragmentos no level-up"
```

---

## Task 6: Verificação manual no Godot

- [ ] **Step 1: Abrir o projeto no Godot**

Recarregar o projeto: `Project → Reload Current Project` (necessário após edições externas em .gd).

- [ ] **Step 2: Verificar ausência de erros no console**

No Output do Godot, confirmar que não há erros de `skill_points`, `dash_cd_upgrades`, `get_dash_cd_reduction`, `buy_hub_upgrade`.

- [ ] **Step 3: Testar o fluxo de level-up**

1. Adicionar fragmentos temporários via console do Godot ou editar `soul_fragments` no save
2. Jogar e ganhar XP suficiente para subir de nível
3. Confirmar que o painel abre centralizado
4. Confirmar que os custos aparecem corretamente nos botões
5. Confirmar que botões sem fragmentos suficientes aparecem em vermelho e desabilitados
6. Confirmar que clicar num upgrade gasta os fragmentos e fecha o painel
7. Confirmar que clicar "Fechar" fecha o painel sem gastar fragmentos
8. Subir de nível sem fragmentos — confirmar que todos os botões ficam desabilitados e só o "Fechar" funciona

- [ ] **Step 4: Verificar escalada de custo**

Comprar o mesmo upgrade 3 vezes e confirmar que o custo sobe a cada vez (ex: Velocidade: 8 → 12 → 24).

- [ ] **Step 5: Commit final de verificação (se necessário)**

```bash
git add -A
git commit -m "chore: ajustes pos-verificacao do sistema de fragmentos"
```
