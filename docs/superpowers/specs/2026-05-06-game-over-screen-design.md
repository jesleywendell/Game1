# Game Over Screen — Design Spec

**Date:** 2026-05-06  
**File target:** `scripts/World.gd` — rewrite `_show_game_over_overlay()`

---

## Goal

Replace the current text-only game over overlay (ColorRect + generic Labels/Buttons) with a proper image-based screen using the assets in `assets/game_over/`.

---

## Assets

| File | Role |
|------|------|
| `assets/game_over/background/Tela_Gameover_Sembotoes.png` | Full-screen background image (no buttons baked in) |
| `assets/game_over/buttons/try_again.png` | Button: restart run |
| `assets/game_over/buttons/return_hub.png` | Button: return to Hub (keep progress) |
| `assets/game_over/buttons/main_menu.png` | Button: go to Main Menu |

---

## Node Tree (built in script, no .tscn)

```
CanvasLayer (layer=30, PROCESS_MODE_ALWAYS)
  └── Control (PRESET_FULL_RECT)
        ├── TextureRect (background, PRESET_FULL_RECT, EXPAND_FIT_WIDTH_PROPORTIONAL)
        └── VBoxContainer (PRESET_CENTER, alignment=CENTER, separation=24)
              ├── Label (Inimigos derrotados)
              ├── Label (Fragmentos coletados)
              ├── Label (Tempo)
              ├── Label (Onda alcançada)
              ├── Control (spacer, min_size=Vector2(0,20))
              ├── TextureButton (try_again)
              ├── TextureButton (return_hub)
              └── TextureButton (main_menu)
```

---

## Stats Labels

- Font size: 22, color: `Color(0.92, 0.88, 0.75)` (parchment/creme)
- Horizontal alignment: CENTER
- Shadow: `Color(0,0,0,0.8)`, offset `Vector2(2,2)`
- Content: same strings already tracked in `World.gd`
  - `"Inimigos derrotados: %d" % _enemies_killed`
  - `"Fragmentos coletados: %d" % maxi(0, frags_earned)`
  - `"Tempo: %dm %02ds" % [minutes, seconds]`
  - `"Onda alcançada: %d" % _wave_manager.current_wave`

---

## Button Behaviors

| Button | Action |
|--------|--------|
| `try_again` | `ProgressionManager.reset_level()` → `get_tree().paused = false` → `get_tree().reload_current_scene()` |
| `return_hub` | `get_tree().paused = false` → `TransitionScreen.fade_to("res://scenes/Hub.tscn")` — **no reset**, keeps fragments earned |
| `main_menu` | `get_tree().paused = false` → `TransitionScreen.fade_to("res://scenes/MainMenu.tscn")` |

---

## TextureButton Setup

Each button:
- `texture_normal` = loaded from `assets/game_over/buttons/<name>.png`
- `ignore_texture_size = true`, `stretch_mode = KEEP_ASPECT_CENTERED`
- `custom_minimum_size = Vector2(280, 64)`
- Modulate on hover: tween to `Color(1.2, 1.2, 1.2)` (brightness +20%) via `mouse_entered`/`mouse_exited`

---

## Fade-in Animation

On overlay creation: start `modulate.a = 0.0`, tween to `1.0` over `0.6s` so the transition isn't jarring.

---

## What Changes in `World.gd`

- Delete entire body of `_show_game_over_overlay()` and replace
- All stats variables (`_enemies_killed`, `frags_earned`, `elapsed_sec`, etc.) are already computed — just pass them into the new node construction
- No other files touched
- No `.tscn` files edited
