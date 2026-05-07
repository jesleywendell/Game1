# Game Over Screen Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the text-only game over overlay in `World.gd` with the image assets from `assets/game_over/`, showing stats (enemies killed, fragments, time, wave) and three functional image buttons.

**Architecture:** Rewrite `_show_game_over_overlay()` in `World.gd` to build a `CanvasLayer` (layer=30) with a `TextureRect` background and a centered `VBoxContainer` containing 4 stat labels and 3 `TextureButton`s. Add a private `_make_go_button()` helper to avoid repetition. No `.tscn` files touched.

**Tech Stack:** Godot 4.6 GDScript

---

### Task 1: Add `_make_go_button()` helper to `World.gd`

**Files:**
- Modify: `scripts/World.gd` — add one new private method after `_show_game_over_overlay()`

- [ ] **Step 1: Open `scripts/World.gd` and locate the end of `_show_game_over_overlay()`**

  The function ends around line 165 (just before `func _on_boss_spawned()`). Add the new method immediately after it.

- [ ] **Step 2: Insert `_make_go_button()` into `World.gd`**

  Paste this block after the closing `}` of `_show_game_over_overlay()` (before `func _on_boss_spawned()`):

  ```gdscript
  func _make_go_button(texture_path: String, callback: Callable) -> TextureButton:
  	var btn := TextureButton.new()
  	btn.texture_normal = load(texture_path)
  	btn.ignore_texture_size = true
  	btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
  	btn.custom_minimum_size = Vector2(280, 64)
  	btn.pressed.connect(callback)
  	btn.mouse_entered.connect(func():
  		var t := btn.create_tween()
  		t.tween_property(btn, "modulate", Color(1.3, 1.3, 1.3), 0.1)
  	)
  	btn.mouse_exited.connect(func():
  		var t := btn.create_tween()
  		t.tween_property(btn, "modulate", Color.WHITE, 0.1)
  	)
  	return btn
  ```

---

### Task 2: Rewrite `_show_game_over_overlay()` in `World.gd`

**Files:**
- Modify: `scripts/World.gd:82-165` — delete entire function body, replace with new implementation

- [ ] **Step 1: Delete the current body of `_show_game_over_overlay()`**

  The current body runs from line 83 (`get_tree().paused = true`) to line 165 (`vbox.add_child(btn_menu)`). Delete everything between the opening `{` and closing `}` of the function, keeping the function signature `func _show_game_over_overlay() -> void:`.

- [ ] **Step 2: Paste the new implementation**

  Replace the deleted body with:

  ```gdscript
  func _show_game_over_overlay() -> void:
  	get_tree().paused = true
  	var elapsed_sec: int = int((Time.get_ticks_msec() - _run_start_time) / 1000)
  	var minutes: int = elapsed_sec / 60
  	var seconds: int = elapsed_sec % 60
  	var frags_earned := ProgressionManager.get_fragments() - _fragments_at_start

  	var cl := CanvasLayer.new()
  	cl.layer = 30
  	cl.process_mode = Node.PROCESS_MODE_ALWAYS
  	add_child(cl)

  	# Root control — covers full screen, used for fade-in
  	var root := Control.new()
  	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
  	root.modulate.a = 0.0
  	cl.add_child(root)

  	# Background image
  	var bg := TextureRect.new()
  	bg.texture = load("res://assets/game_over/background/Tela_Gameover_Sembotoes.png")
  	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
  	bg.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
  	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
  	root.add_child(bg)

  	# Stats + buttons container, centered with a slight downward offset
  	# to sit below the GAME OVER title baked into the background image
  	var vbox := VBoxContainer.new()
  	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
  	vbox.add_theme_constant_override("separation", 16)
  	vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
  	vbox.custom_minimum_size = Vector2(320, 0)
  	vbox.position += Vector2(0, 80)
  	root.add_child(vbox)

  	# Stat labels
  	var stats: Array[String] = [
  		"Inimigos derrotados: %d"  % _enemies_killed,
  		"Fragmentos coletados: %d" % maxi(0, frags_earned),
  		"Tempo: %dm %02ds"         % [minutes, seconds],
  		"Onda alcançada: %d"       % _wave_manager.current_wave,
  	]
  	for s in stats:
  		var lbl := Label.new()
  		lbl.text = s
  		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  		lbl.add_theme_font_size_override("font_size", 22)
  		lbl.add_theme_color_override("font_color", Color(0.92, 0.88, 0.75))
  		lbl.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.8))
  		lbl.add_theme_constant_override("shadow_offset_x", 2)
  		lbl.add_theme_constant_override("shadow_offset_y", 2)
  		vbox.add_child(lbl)

  	var spacer := Control.new()
  	spacer.custom_minimum_size = Vector2(0, 20)
  	vbox.add_child(spacer)

  	# Image buttons
  	vbox.add_child(_make_go_button(
  		"res://assets/game_over/buttons/try_again.png",
  		func():
  			ProgressionManager.reset_level()
  			get_tree().paused = false
  			get_tree().reload_current_scene()
  	))
  	vbox.add_child(_make_go_button(
  		"res://assets/game_over/buttons/return_hub.png",
  		func():
  			get_tree().paused = false
  			TransitionScreen.fade_to("res://scenes/Hub.tscn")
  	))
  	vbox.add_child(_make_go_button(
  		"res://assets/game_over/buttons/main_menu.png",
  		func():
  			get_tree().paused = false
  			TransitionScreen.fade_to("res://scenes/MainMenu.tscn")
  	))

  	# Fade in the whole overlay
  	var tween := root.create_tween()
  	tween.tween_property(root, "modulate:a", 1.0, 0.6)
  ```

---

### Task 3: Verify and commit

**Files:** none (verification only)

- [ ] **Step 1: Run the game in Godot and die (let an enemy kill the player)**

  Expected:
  - Background image `Tela_Gameover_Sembotoes.png` fades in over 0.6s, centered, filling the screen
  - 4 stat lines appear over the image: inimigos, fragmentos, tempo, onda
  - 3 image buttons visible: try_again, return_hub, main_menu
  - Hovering a button brightens it slightly

- [ ] **Step 2: Test each button**

  | Button | Expected behavior |
  |--------|-------------------|
  | try_again | Reloads `World.tscn` from wave 1 (progression reset) |
  | return_hub | Transitions to `Hub.tscn`; fragments earned in the run are kept |
  | main_menu | Transitions to `MainMenu.tscn` |

- [ ] **Step 3: Adjust `vbox.position += Vector2(0, 80)` if needed**

  If the stat labels overlap with text in the background image, increase the Y offset. If the buttons fall off-screen, decrease it. Typical range: 60–120.

- [ ] **Step 4: Commit**

  ```bash
  git add scripts/World.gd
  git commit -m "feat(ui): substitui tela de game over por assets de imagem com botões funcionais"
  ```
