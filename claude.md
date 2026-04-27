# OATHBREAKER — Claude Context File

> Read this before doing anything. It contains the full project state, architecture, what's built, and what's missing vs the GDD.

---

## Project Identity

- **Game name:** OATHBREAKER (project folder is called Game1)
- **Engine:** Godot 4.6 GDScript, GL Compatibility renderer
- **Genre:** Action RPG 2D isometric, dark fantasy roguelite
- **University project:** iCEV — Engenharia de Software, Introdução ao Desenvolvimento de Jogos
- **GDD:** `gdd.md` in repo root — read it for full design spec
- **Branch:** `develop`

---

## Team

| Name | Role |
|------|------|
| Guilherme Ancheschi | Developer |
| Jesley Wendell | Developer |
| Lara Bezerra | Creative Director |
| Mateus Pessoa | Graphic Designer |
| Víctor Portelada | QA |

---

## Architecture Overview

### Scene Tree
```
MainMenu.tscn        → MainMenu.gd, MenuButton.gd
World.tscn           → World.gd
  ├── MapGenerator   → MapGenerator.gd
  ├── Player         → Player.gd, SkillManager.gd
  └── HUD            → HUD.gd
Boar.tscn            → Boar.gd
Projectile.tscn      → Projectile.gd
```

### Autoloads (registered in project.godot)
| Singleton | File | Purpose |
|-----------|------|---------|
| `JuiceManager` | `scripts/JuiceManager.gd` | Hit-stop, screen shake, blood particles, floating damage numbers |
| `TransitionScreen` | `scripts/TransitionScreen.gd` | Fade in/out between scenes |

### Key Scripts
| File | Role |
|------|------|
| `scripts/Player.gd` | CharacterBody2D — movement, dash, melee, iframes, XP/leveling |
| `scripts/SkillManager.gd` | Q (area burst) + E (projectile) with cooldowns |
| `scripts/Boar.gd` | Area2D enemy — chase AI, contact damage, health bar |
| `scripts/WaveManager.gd` | Wave spawning, difficulty scaling, wave-clear detection |
| `scripts/MapGenerator.gd` | Procedural forest map via FastNoiseLite |
| `scripts/HUD.gd` | Health bar, wave label, level label, level-up flash |
| `scripts/JuiceManager.gd` | Autoload — all combat feedback |
| `scripts/TransitionScreen.gd` | Autoload — scene transition fades |
| `scripts/XpOrb.gd` | Area2D orb — magnetic to player, grants XP |

---

## What's Built (Current State)

### Player (Player.gd)
- WASD movement (speed=200), Space dash (700px/s, 0.15s, 1s CD)
- LMB melee attack (damage=15, duration=0.35s, hitbox at 28px)
- Q skill → SkillManager.use_q() area burst (damage=25, 3s CD)
- E skill → SkillManager.use_e() projectile (damage=20, 2s CD)
- Invincibility frames: 0.6s after hit, sprite blinks
- Hit flash (modulate tween), knockback on hit
- Camera2D zoom=2.0
- XP system: current_xp, current_level, xp_to_next (scales ×1.4/level)
- On level up: +15 max_health, +3 attack_damage, +20 heal, emits `level_up`
- Signals: `health_changed(current, max)`, `died`, `level_up(level)`

### Enemy — Boar (Boar.gd)
- Extends Area2D (NOT CharacterBody2D — no physics sliding)
- Idle animation from `assets/critters/critters/boar/boar_SE_idle_strip.png`
- Chase AI: detects player via group "player", moves directly toward if within 180px, stops at 20px
- Contact damage: 10/s when player overlaps
- Stats are `var` (not `const`) so WaveManager can scale per wave
- Hit flash + knockback (position += direction * 18) on take_damage
- On death: blood particles + hitstop via JuiceManager, fade out, queue_free
- Spawns 3 XP orbs on death
- z_index updates dynamically for isometric depth sorting

### Wave System (WaveManager.gd)
- Loaded dynamically by World.gd, NOT an autoload
- `start_next_wave()`: spawns `int(4 * 1.18^(wave-1))` boars
- 16 hardcoded spawn coordinates (isometric map positions)
- Difficulty scales HP and DAMAGE per wave via multiplier
- Tracks alive enemies via `tree_exited` signal + "active_enemies" group
- `call_deferred("_check_wave_clear")` to avoid frame-timing bug
- Signals: `wave_started(wave_number)`, `wave_cleared(wave_number)`
- 2 second delay between waves (in World.gd `_on_wave_cleared`)

### Map (MapGenerator.gd)
- FastNoiseLite, seed=7, 44×34 tiles, 32×32px isometric
- Floor zones: dark soil (noise<-0.15), mossy (noise<0.15), green (noise<0.45), rocky (noise≥0.45)
- Border: tile_060/061
- Scatter: Bones, Plants, Broken_tree, Rock, Thorn, Dead_tree from `assets/forest/`
- Z-layer: floor(-10) → scatter(-8 to -2) → characters(0)
- Map modulate: `Color(0.55, 0.70, 0.55, 1.0)` (greenish tint)

### Atmosphere (World.gd `_setup_atmosphere()`)
- CanvasLayer layer=1 with dark ambient overlay + vignette shader
- CPUParticles2D fog drifting across map
- HUD CanvasLayer forced to layer=2 so atmosphere renders below it

### HUD (HUD.gd)
- Health bar: TextureProgressBar with `bar_frame.png` + `bar_fill.png`
- Wave label: "Wave N" bottom-left, flashes on wave change
- Level label: "Lv. N" below wave label
- Level-up flash: "LEVEL UP!" centered, fades after 0.8s
- Game over: label shows → 3s → scene reload

### Main Menu (MainMenu.gd)
- Background: `assets/tela_inicial/tela_de_inicio.png`
- Buttons: Iniciar (→ TransitionScreen.fade_to World), Configurações, Créditos, Sair
- Fade-in on load

### JuiceManager (autoload)
- `add_trauma(amount)` → perlin noise-based camera shake with quadratic falloff
- `apply_hitstop(duration, scale)` → Engine.time_scale briefly
- `spawn_blood(pos, parent)` → CPUParticles2D one-shot red burst
- `spawn_damage_number(amount, pos, parent, is_player_hit)` → floating Label tween
- Called from: Player.take_damage, Boar.take_damage, Boar._die()

### TransitionScreen (autoload)
- CanvasLayer layer=10, ColorRect full screen
- `fade_to(scene_path)` → fade black (0.35s) → change scene → fade in (0.45s)
- Used by MainMenu._start_game()

### Display
- 1920×1080, fullscreen (mode=4), canvas_items stretch, expand aspect
- F11 toggles fullscreen (handled in World.gd `_unhandled_input`)

---

## What's MISSING vs GDD MVP

These are required for the university delivery. **Read gdd.md section 7.3 for full MVP spec.**

### 🔴 Critical (core mechanics)

**1. Skills cost HP (narrative mechanic)**
- GDD: Q (Golpe Sagrado) costs 5 HP per use, E (Lança Divina) costs 3 HP
- Currently: skills cost nothing
- Fix: in `SkillManager.use_q()` and `use_e()`, call `player.take_damage(5)` / `player.take_damage(3)` with no direction (no knockback, no iframes — it's self-damage)
- This is the core narrative tension: powers are corrupted, they drain the caster

**2. Damage rebalance around HP cost**
- GDD damage values: melee=1.0, Q=2.0, E=1.5 (low because skills drain player HP)
- Current values: melee=15, Q=25, E=20 (tuned without HP cost, too high for GDD balance)
- Needs rebalancing once HP cost is in

**3. Fragmentos de Alma (soul fragments) — not XP orbs**
- GDD: enemies drop 1-3 Fragmentos de Alma (permanent currency, kept on death)
- Currently: enemies drop XP orbs that grant XP for leveling
- These are different systems — fragments are permanent, XP is temporary
- Need both or replace XP with fragments depending on design decision

**4. Enemy types: Skeleton + Rotten Chicken**
- GDD specifies Esqueleto (HP=30, dmg=10, speed=120) and Galinha Podre (HP=20, dmg=8, speed=160)
- Currently only Boar exists (which is not in GDD enemy list)
- Assets may not exist yet — check with Mateus (Graphic Designer)

### 🟠 High (game loop)

**5. 1-of-3 upgrade card selection between arenas**
- GDD: after each arena cleared, player picks 1 of 3 random upgrades
- Options: +10% dano, +15 HP máximo, -0.2s dash CD, habilidade bônus, velocidade +10%
- UI: 3 PanelContainer cards, `get_tree().paused = true` while choosing
- Cards must have `process_mode = PROCESS_MODE_WHEN_PAUSED`

**6. 90-second arena timer**
- GDD: each wave has 90s limit
- On timeout: remaining enemies get +50% damage and speed (frenzy mode)
- HUD needs a timer display

**7. Hub scene**
- GDD: Hub Central with 1 NPC offering permanent upgrades
- Upgrades: Força (+3 dmg, 15 fragments), Vitalidade (+10 HP, 12 fragments), Agilidade (-0.1s dash CD, 20 fragments)
- Max 5 upgrades per attribute
- Requires new scene: Hub.tscn

### 🟡 Medium (polish)

**8. Audio**
- GDD: SFX for attack (metal lance sound), damage received, ability use (reverb + distortion), enemy death, dash
- 1 ambient dark fantasy track
- No audio currently implemented

**9. Area 1 victory screen**
- After defeating Boss 1, show victory + run stats
- GDD: area victory → upgrade selection → next area or hub

**10. Game Over screen with run summary**
- GDD: show enemies killed, fragments collected, total time, area reached
- Currently: just a label + scene reload (no stats)

---

## Common Gotchas

- **Autoloads not recognized after editing project.godot externally:** Godot editor must be reloaded (Project → Reload Current Project). Autoloads ARE correctly registered in project.godot.
- **WaveManager is NOT an autoload** — it's instantiated dynamically in World.gd `_ready()` via `load("res://scripts/WaveManager.gd").new()`
- **Boar stats are `var` not `const`** — WaveManager sets them per-instance for difficulty scaling
- **call_deferred for wave clear check** — enemy `tree_exited` fires before node is fully removed; checking group size immediately gives wrong count
- **CanvasLayer layer ordering:** HUD=2, Atmosphere=1, World=0 (base)
- **Isometric world position formula:** `Vector2((col - row) * 16.0, (col + row) * 8.0)` — use this for spawning anything on the map grid
- **Skill HP cost must bypass iframes** — when implementing, call a separate `drain_hp()` method that skips the invincibility check, or use a flag. Otherwise player iframes prevent the HP drain.
- **`get_tree().paused = true` freezes all nodes** — upgrade card UI must set `process_mode = PROCESS_MODE_WHEN_PAUSED`

---

## Asset Locations

```
assets/protagonista/azrael_sprites_transparent.png   — 4-dir × 3 rows, 64×70 frames
assets/critters/critters/boar/boar_SE_idle_strip.png — boar idle, 7 frames, 41×25
assets/isometric tileset/isometric tileset/separated images/tile_000..114.png
assets/life/bar_frame.png + bar_fill.png             — HUD health bar 220×70
assets/forest/                                        — scatter: Bones, Broken_tree, Dead_tree, Plant, Rock, Thorn
assets/tela_inicial/tela_de_inicio.png               — main menu background
```

---

