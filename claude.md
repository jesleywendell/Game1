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
KnightCoxinha.tscn   → KnightCoxinha.gd
Projectile.tscn      → Projectile.gd
```

### Autoloads (registered in project.godot)
| Singleton | File | Purpose |
|-----------|------|---------|
| `JuiceManager` | `scripts/JuiceManager.gd` | Hit-stop, screen shake, blood particles, floating damage numbers |
| `TransitionScreen` | `scripts/TransitionScreen.gd` | Fade in/out between scenes |
| `ProgressionManager` | `scripts/ProgressionManager.gd` | XP, leveling, persistent upgrades, save/load |

### Key Scripts
| File | Role |
|------|------|
| `scripts/Player.gd` | CharacterBody2D — movement, dash, melee, iframes, reads stats from ProgressionManager |
| `scripts/SkillManager.gd` | Q (area burst) + E (projectile) with cooldowns |
| `scripts/Boar.gd` | Area2D enemy — chase AI, contact damage, health bar, drops XP |
| `scripts/KnightCoxinha.gd` | Area2D enemy — 8-dir walk, charge skill, states: idle/walk/skill_windup/skill_charge |
| `scripts/WaveManager.gd` | Wave spawning, difficulty scaling, wave-clear detection |
| `scripts/MapGenerator.gd` | Procedural forest map via FastNoiseLite |
| `scripts/HUD.gd` | Health bar, wave label, level label, level-up flash |
| `scripts/ProgressionManager.gd` | Autoload — XP, levels, skill points, permanent upgrades, save to .tres |
| `scripts/PlayerData.gd` | Resource class — serialized player save data |
| `scripts/UpgradePanel.gd` | CanvasLayer — upgrade selection UI on level up (pauses game) |
| `scripts/PauseMenu.gd` | CanvasLayer — ESC pause menu with resume/config/main menu |
| `scripts/JuiceManager.gd` | Autoload — all combat feedback |
| `scripts/TransitionScreen.gd` | Autoload — scene transition fades |
| `scripts/XpOrb.gd` | Area2D orb — magnetic to player, calls ProgressionManager.add_xp() |

---

## What's Built (Current State)

### Player (Player.gd)
- WASD movement (speed=200 base, scaled by ProgressionManager)
- Space dash (700px/s, 0.15s, 1s CD)
- LMB melee attack (damage=15 base + upgrades, duration=0.35s)
- Q/E skills via SkillManager
- Invincibility frames: 0.6s, sprite blinks during iframes
- Hit flash (modulate tween), knockback velocity on hit
- Camera2D zoom=2.0
- **Sprite:** `assets/protagonista/walk/azrael_walk.png` — 150×146 frames, 4 cols, 8 rows (N/NE/E/SE/S/SW/W/NW walk directions)
- **No idle/attack animations yet** — walk animation stops on frame 0 when standing still
- Stats driven by ProgressionManager via `_apply_stats()` — reconnects on `upgrade_applied` signal
- Signals: `health_changed(current, max)`, `died`

### Enemy — Boar (Boar.gd)
- Extends Area2D
- Sprite: `assets/critters/critters/boar/boar_SE_idle_strip.png` — 7 frames idle only
- Chase AI: detects player via group "player", moves toward if within 180px
- Contact damage: 10/s (scaled by WaveManager multiplier)
- Stats are `var` — WaveManager scales HP/DAMAGE/xp_reward per wave
- On death: calls `ProgressionManager.add_xp(xp_reward)`, blood + hitstop via JuiceManager
- Spawns 3 XP orbs on death

### Enemy — KnightCoxinha (KnightCoxinha.gd)
- Extends Area2D, 8-directional walk animation
- Sprite: `assets/enemies/knight_coxinha/walk/knight_coxinha_walk.png` — 181×181 frames, 6 cols × 8 rows
- States: `idle` / `walk` / `skill_windup` / `skill_charge`
- Chase: detect=230px, move=55px/s, stops at 24px
- **Charge skill:** 0.55s windup → dashes at 230px/s for 0.38s → deals 35 dmg on hit within 64px
- Skill cooldown: 6s, only triggers if player within 210px
- Base stats: HP=150, DAMAGE=20, xp_reward=65 (all scaled by WaveManager)
- On death: `ProgressionManager.add_xp(xp_reward)`, JuiceManager blood + hitstop
- Uses JuiceManager for trauma on charge land/end

### Wave System (WaveManager.gd)
- Loaded dynamically in World.gd `_ready()`, NOT an autoload
- Wave 1: all Boars
- Wave 2+: every 3rd enemy (index % 3 == 2) is a KnightCoxinha
- Spawns `int(4 * 1.18^(wave-1))` enemies per wave
- 16 hardcoded isometric spawn coordinates
- Tracks alive enemies: `tree_exited` signal + "active_enemies" group
- `call_deferred("_check_wave_clear")` to avoid frame-timing bug
- `is_inside_tree()` guard in `_check_wave_clear`
- Signals: `wave_started(wave_number)`, `wave_cleared(wave_number)`
- 2s delay between waves (World.gd `_on_wave_cleared`)

### Progression System (ProgressionManager.gd — autoload)
- Saves/loads `PlayerData` resource to `user://player_data.tres`
- XP formula: `required = 100 * level^1.5`
- On level up: `data.skill_points += 1`, emits `leveled_up(level)`
- `apply_upgrade(attribute)`: consumes 1 skill point, upgrades stat, emits `upgrade_applied`
- Upgrade bonuses: attack_damage +5, skill_damage +8, speed +15, max_health +20
- Methods: `add_xp(amount)`, `get_attack_damage(base)`, `get_skill_damage_bonus()`, `get_speed(base)`, `get_max_health(base)`
- `reset()` clears save data

### PlayerData (PlayerData.gd)
- `extends Resource` — serialized as .tres
- Fields: `level`, `current_xp`, `skill_points`, `attack_damage_upgrades`, `skill_damage_upgrades`, `speed_upgrades`, `max_health_upgrades`

### Upgrade Panel (UpgradePanel.gd)
- CanvasLayer layer=20, `PROCESS_MODE_ALWAYS`
- Shows on `leveled_up` signal — pauses game, shows 4 upgrade buttons
- Buttons: Dano do Ataque (+5), Dano das Skills (+8), Velocidade (+15), Vida Maxima (+20)
- Hides and unpauses when skill_points reach 0 after selection
- Must be added as child of World or as autoload to function

### Pause Menu (PauseMenu.gd)
- CanvasLayer layer=25, `PROCESS_MODE_ALWAYS`
- ESC toggles pause — opens/closes with fade tween
- Assets from `assets/pause/` (background + button images)
- Buttons: Continue, Config (stub), Return to Main Menu
- `_go_main()` uses TransitionScreen.fade_to()

### Map (MapGenerator.gd)
- FastNoiseLite seed=7, 44×34 tiles, 32×32px isometric
- Floor zones by noise: dark soil / mossy / green / rocky
- Border: tile_060/061
- Scatter: Bones, Plants, Broken_tree, Rock, Thorn, Dead_tree from `assets/forest/`
- Z-layer: floor(-10) → scatter(-8 to -2) → characters(0)
- Map modulate: `Color(0.55, 0.70, 0.55, 1.0)`

### Atmosphere (World.gd `_setup_atmosphere()`)
- CanvasLayer layer=1: dark ambient overlay + vignette shader (GLSL)
- CPUParticles2D fog drifting across map
- HUD CanvasLayer forced to layer=2

### HUD (HUD.gd)
- Health bar: TextureProgressBar (`bar_frame.png` + `bar_fill.png`)
- Wave label + Level label (programmatically created in _ready)
- Level-up flash: "LEVEL UP!" centered, fades after 0.8s
- Game over: label → 3s → scene reload

### Main Menu (MainMenu.gd)
- Background: `assets/tela_inicial/tela_de_inicio.png`
- Buttons: Iniciar → `TransitionScreen.fade_to("res://scenes/World.tscn")`
- Fade-in on load

### JuiceManager (autoload)
- `add_trauma(amount)` → perlin noise camera shake, quadratic falloff
- `apply_hitstop(duration, scale)` → Engine.time_scale
- `spawn_blood(pos, parent)` → CPUParticles2D red burst
- `spawn_damage_number(amount, pos, parent, is_player_hit)` → floating Label tween

### TransitionScreen (autoload)
- CanvasLayer layer=10
- `fade_to(scene_path)` → fade black 0.35s → load scene → fade in 0.45s

### Display
- 1920×1080 fullscreen, canvas_items stretch, expand aspect
- F11 toggles fullscreen (World.gd `_unhandled_input`)

---

## What's MISSING vs GDD MVP

**Read `gdd.md` section 7.3 for full MVP spec.**

### 🔴 Critical

**1. Skills cost HP** — Q costs 5 HP, E costs 3 HP (core narrative mechanic)
- Fix: in `SkillManager.use_q/use_e`, drain HP via a method that bypasses iframes
- Do NOT call `take_damage` — that triggers iframes and prevents stacking
- Add `drain_hp(amount)` to Player that skips the invincibility check

**2. Damage rebalance**
- GDD values: melee=1.0, Q=2.0, E=1.5 — designed around HP cost per use
- Current: melee=15, Q=25, E=20 — needs tuning once HP cost is in

**3. Enemy types: Skeleton + Rotten Chicken**
- GDD: Esqueleto (HP=30, dmg=10, speed=120) and Galinha Podre (HP=20, dmg=8, speed=160)
- Currently: Boar + KnightCoxinha (both not in GDD enemy list)
- Check with Mateus for sprite assets

### 🟠 High

**4. 90-second arena timer**
- Each wave: 90s limit → on timeout enemies get +50% dmg/speed (frenzy)
- HUD needs countdown display

**5. Hub scene**
- Hub Central with NPC offering permanent upgrades
- ProgressionManager already has the upgrade logic — just needs Hub.tscn + UI

**6. Area 1 victory screen**
- After Boss 1 (KnightCoxinha as final boss? or separate scene)
- Show run stats, transition to hub

### 🟡 Medium

**7. Audio** — SFX (attack metal, damage, skill echo, death, dash) + 1 ambient track

**8. Game Over screen** with run summary (enemies killed, XP, time, area reached)
- Currently: just a label + scene reload

**9. UpgradePanel wiring** — needs to be added as child node in World.tscn or instantiated in World.gd `_ready()`; unclear if currently connected

**10. PauseMenu wiring** — same issue, needs to be in scene tree

---

## Common Gotchas

- **Autoloads not recognized after external edit:** Godot editor → Project → Reload Current Project
- **WaveManager is NOT an autoload** — instantiated in World.gd `_ready()` via `load(...).new()`
- **Boar/KnightCoxinha stats are `var`** — WaveManager sets them per-instance
- **call_deferred for wave clear** — `tree_exited` fires before node is fully removed; check group size immediately gives wrong count
- **CanvasLayer layer order:** PauseMenu=25 > UpgradePanel=20 > TransitionScreen=10 > HUD=2 > Atmosphere=1
- **Isometric world position formula:** `Vector2((col - row) * 16.0, (col + row) * 8.0)`
- **Skill HP cost must bypass iframes** — add `drain_hp()` to Player that skips `_invincibility_timer` check; never call `take_damage` for self-damage
- **`get_tree().paused = true` freezes all nodes** — any UI shown during pause needs `process_mode = PROCESS_MODE_ALWAYS` or `PROCESS_MODE_WHEN_PAUSED`
- **ProgressionManager.add_xp called by enemies on death** — Boar and KnightCoxinha both call this in `_die()`; XP orbs ALSO call it via player. Check for double-counting.
- **Player._apply_stats() called on upgrade_applied** — connects in `_ready()`, safe to call multiple times

---

## Asset Locations

```
assets/protagonista/walk/azrael_walk.png              — 150×146 frames, 4 cols × 8 rows (N/NE/E/SE/S/SW/W/NW)
assets/enemies/knight_coxinha/walk/knight_coxinha_walk.png — 181×181 frames, 6 cols × 8 rows
assets/critters/critters/boar/boar_SE_idle_strip.png  — 41×25 frames, 7 cols idle
assets/isometric tileset/isometric tileset/separated images/tile_000..114.png
assets/life/bar_frame.png + bar_fill.png              — HUD health bar 220×70
assets/forest/                                         — scatter: Bones, Broken_tree, Dead_tree, Plant, Rock, Thorn
assets/tela_inicial/tela_de_inicio.png                — main menu background
assets/pause/background/Paused2.png                   — pause menu background
assets/pause/botoes/continue.png + config.png         — pause buttons
assets/pause/return_menu_principal.png                — pause menu button
```

---

## Workflow Convention

- **OpenCode** handles all routine implementation (scripts, boilerplate, well-specified features)
- **Claude** handles architecture, complex logic, reviewing OpenCode output, giving OpenCode prompts
- When giving implementation tasks: write complete OpenCode prompts with exact file names, explicit code blocks, and "do not touch .tscn files" constraint
- Never edit .tscn files via text — use Godot editor or script-based node creation in `_ready()`
- Give OpenCode prompts ONE task at a time with clear file targets
