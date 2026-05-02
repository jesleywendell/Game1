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
Hub.tscn             → Hub.gd
Credits.tscn         → Credits.gd
PauseMenu.tscn       → PauseMenu.gd
HUD.tscn             → HUD.gd (standalone scene)
UpgradePanel.tscn    → UpgradePanel.gd
Boar.tscn            → Boar.gd
KnightCoxinha.tscn   → KnightCoxinha.gd
Projectile.tscn      → Projectile.gd
```
Skeleton and GalinhaPodre have no .tscn — they are spawned purely via script by WaveManager.

### Autoloads (registered in project.godot)
| Singleton | File | Purpose |
|-----------|------|---------|
| `JuiceManager` | `scripts/JuiceManager.gd` | Hit-stop, screen shake, blood particles, floating damage numbers |
| `TransitionScreen` | `scripts/TransitionScreen.gd` | Fade in/out between scenes |
| `AudioManager` | `scripts/AudioManager.gd` | SFX playback + ambient loop (gracefully no-ops when audio files missing) |
| `ProgressionManager` | `scripts/ProgressionManager.gd` | XP, leveling, fragments, persistent upgrades, save/load, area tracking |

### Key Scripts
| File | Role |
|------|------|
| `scripts/Player.gd` | CharacterBody2D — movement, dash, melee, iframes, health regen, reads stats from ProgressionManager |
| `scripts/SkillManager.gd` | Q (AoE slash ring) + E (fire bullet projectile) with cooldowns |
| `scripts/Boar.gd` | Area2D enemy — chase AI, contact damage, health bar, drops XP (legacy, no longer spawned by WaveManager) |
| `scripts/Skeleton.gd` | Area2D enemy — 8-dir walk + spear weapon, chase AI, frenzy support. Spawned dynamically (no .tscn) |
| `scripts/GalinhaPodre.gd` | Area2D enemy — fast chase, green circle placeholder (no sprite asset yet). Spawned dynamically (no .tscn) |
| `scripts/KnightCoxinha.gd` | Area2D enemy — 8-dir walk, charge skill, boss phase 2 at 50% HP. States: idle/walk/skill_windup/skill_charge |
| `scripts/WaveManager.gd` | Wave spawning, 3-area scaling, enemy type rotation (skeleton/knight/galinha), boss waves, frenzy timer |
| `scripts/MapGenerator.gd` | Procedural isometric terrain — 3 area phases (forest → cursed land → undead cemetery), scatter props, border colliders |
| `scripts/HUD.gd` | Health bar, XP bar, wave timer, skill cooldown overlays, frenzy warning label |
| `scripts/ProgressionManager.gd` | Autoload — XP, levels, fragment economy, 4 upgrade types (quadratic cost formula), save/load, area tracking |
| `scripts/PlayerData.gd` | Resource class — serialized player save data (level, XP, upgrades, soul_fragments, current_area) |
| `scripts/UpgradePanel.gd` | CanvasLayer — level-up upgrade selection with fragment costs, disables unaffordable buttons |
| `scripts/ArenaUpgradePanel.gd` | CanvasLayer — area-clear upgrade card picker (4 cards: damage/health/speed/dash) |
| `scripts/PauseMenu.gd` | CanvasLayer — ESC pause menu with resume/config/main menu, image-based buttons |
| `scripts/Hub.gd` | Node2D — isometric hub map with NPC "Mercador" (fragment display), exit portal to World |
| `scripts/MainMenu.gd` | Node2D — main menu with fade transitions to World/Credits/Quit |
| `scripts/Credits.gd` | Node2D — image-based credits screen |
| `scripts/TutorialManager.gd` | Node — 5-step first-run tutorial overlay (WASD → space → mouse → Q → E) |
| `scripts/JuiceManager.gd` | Autoload — all combat feedback: screen shake, hitstop, blood particles, damage numbers |
| `scripts/TransitionScreen.gd` | Autoload — black fade-in/fade-out between scenes |
| `scripts/AudioManager.gd` | Autoload — loads/plays SFX and ambient from `assets/audio/`, silently skips missing files |
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

### Enemy — Boar (Boar.gd, legacy — no longer spawned by WaveManager)
- Extends Area2D
- Sprite: `assets/critters/critters/boar/boar_SE_idle_strip.png` — 7 frames idle only
- Chase AI: detects player via group "player", moves toward if within 15000px (effectively always)
- Contact damage with damage cooldown
- Stats are `var` — WaveManager scales HP/DAMAGE/xp_reward per wave
- On death: calls `ProgressionManager.add_xp(xp_reward)`, blood + hitstop via JuiceManager
- No frenzy support

### Enemy — Skeleton (Skeleton.gd, 178 lines)
- Extends Area2D, spawned dynamically by WaveManager (no .tscn)
- Sprite: `assets/enemies/skeleton/Skeleton.png` — 64×64 frames, 8 rows (directions), 7-8 frames each
- Weapon visual: `assets/items/spear/spear_00.png` attached, flips left/right by direction
- 8-directional walk animation via SpriteFrames built at runtime
- Chase: detect=200px, stop at 18px, damage cooldown
- Base stats: HP=30, DAMAGE=10, speed=120, xp_reward=20
- Frenzy: 1.5x damage/speed + red tint on arena timeout
- On death: XP + fragmentos (1-3), blood, hitstop, screen shake, fade-out, queue_free

### Enemy — GalinhaPodre (GalinhaPodre.gd, 111 lines)
- Extends Area2D, spawned dynamically by WaveManager (no .tscn)
- **No sprite asset** — uses `_draw()` green circle (r=12) as placeholder + health bar widget
- Fast chase: detect=220px, stop at 12px, damage cooldown
- Base stats: HP=20, DAMAGE=8, speed=160, xp_reward=15
- Frenzy: 1.5x damage/speed + red tint on arena timeout
- Z-index based on Y position for isometric depth sorting
- On death: same as skeleton (XP, fragments, blood, hitstop, fade, queue_free)

### Enemy — KnightCoxinha (KnightCoxinha.gd, 242 lines)
- Extends Area2D, 8-directional walk animation
- Sprite: `assets/enemies/knight_coxinha/walk/knight_coxinha_walk.png` — 181×181 frames, 6 cols × 8 rows
- States: `idle` / `walk` / `skill_windup` / `skill_charge`
- Chase: detect=380px, move=55px/s, stops at 24px
- **Charge skill:** dash attack at 230px/s for 0.38s, deals 35 dmg, 340px range, 6s cooldown
- **Boss mode:** `is_boss` flag → phase 2 at sub-50% HP (1.6x speed, cooldown halved)
- Base stats: HP=150, DAMAGE=20, speed=55, xp_reward=65 (all scaled by WaveManager)
- On death: `ProgressionManager.add_xp(xp_reward)`, JuiceManager blood + hitstop

### Wave System (WaveManager.gd)
- Loaded dynamically in World.gd `_ready()`, NOT an autoload
- **3 area phases** with escalating difficulty (static `current_area` on WaveManager)
  - Area 1 (Forest): boar + knight, standard scaling
  - Area 2 (Cursed Land): 2x enemy count, knights from wave 1
  - Area 3 (Undead Cemetery): rotating spawns (knight/galinha/skeleton)
- 3 waves per area + boss wave on wave 3
- Enemy type rotation: skeleton → knight → galinha (weighted by wave index)
- 16 hardcoded isometric spawn coordinates
- Tracks alive enemies: `tree_exited` signal + "active_enemies" group
- Arena timer: 90s per wave → frenzy mode (+50% dmg/speed) on timeout
- `call_deferred("_check_wave_clear")` to avoid frame-timing bug
- `is_inside_tree()` guard in `_check_wave_clear`
- Signals: `wave_started(wave_number)`, `wave_cleared(wave_number)`
- 2s delay between waves (World.gd `_on_wave_cleared`)

### Progression System (ProgressionManager.gd — autoload)
- Saves/loads `PlayerData` resource to `user://player_data.tres`
- XP formula: `required = 100 * level^1.5`
- On level up: emits `leveled_up(level)` → UpgradePanel opens
- **Fragment economy (no skill_points):** up to 5 upgrades per attribute, quadratic cost: `base[attr] + scale[attr] * n^2`
  - Attack damage: base=10, scale=5 | Skill damage: base=12, scale=6
  - Speed: base=8, scale=4 | Max health: base=6, scale=3
- `apply_upgrade(attribute)`: calls `spend_fragments(cost)` → increments upgrade counter → emits `upgrade_applied`
- `get_upgrade_cost(attribute)` returns current cost for display
- Methods: `add_xp()`, `add_fragments()`, `spend_fragments()`, `get_fragments()`
- Tracks `current_area` for map phase switching
- `reset()` clears save data

### PlayerData (PlayerData.gd)
- `extends Resource` — serialized as .tres
- Fields: `level`, `current_xp`, `attack_damage_upgrades`, `skill_damage_upgrades`, `speed_upgrades`, `max_health_upgrades`, `soul_fragments`, `current_area`
- No `skill_points` or `dash_cd_upgrades` (removed in fragment cost refactor)

### Upgrade Panel (UpgradePanel.gd)
- CanvasLayer layer=20, `PROCESS_MODE_ALWAYS`
- Shows on `leveled_up` signal — pauses game, shows 4 upgrade buttons with fragment costs
- Buttons: Dano do Ataque (+5), Dano das Skills (+8), Velocidade (+15), Vida Maxima (+20)
- Displays current soul fragment balance at top
- Disables buttons player can't afford (text turns red)
- "Fechar" button always visible to skip upgrade without spending
- 1 upgrade per level-up; closes + unpauses after selection

### Arena Upgrade Panel (ArenaUpgradePanel.gd)
- CanvasLayer — appears after clearing an arena area
- 4 upgrade cards: +10% damage, +15 HP max, +10% speed, -0.2s dash cooldown
- Temporary buffs (lost on death/area transition)

### Hub (Hub.gd)
- Node2D — isometric hub map with decorative buildings, tombstones, vegetation
- NPC "Mercador" — displays current soul fragment balance
- Exit portal transitions to World (combat arena)
- No shop — upgrades happen exclusively via level-up fragment system

### Tutorial (TutorialManager.gd)
- Node — first-run tutorial overlay for new players
- 5 sequential steps: WASD movement → space dash → mouse aim → Q skill → E skill
- Each step waits for player to perform the action before advancing
- Persists completion state (only shows once)

### Credits (Credits.gd)
- Node2D — image-based credits screen
- Accessible from main menu

### Audio (AudioManager.gd — autoload)
- Manages SFX playback with polyphony (8 simultaneous players)
- References: sfx_attack, sfx_dash, sfx_damage_player, sfx_player_die, sfx_skill_q, sfx_skill_e, sfx_hp_drain, sfx_enemy_die, sfx_boss_phase2, ambient_forest
- All `load()` calls guarded by `ResourceLoader.exists()` — gracefully silent when audio files missing
- **No .ogg files present in `assets/audio/` yet** — game runs fine without them

### Pause Menu (PauseMenu.gd)
- CanvasLayer layer=25, `PROCESS_MODE_ALWAYS`
- ESC toggles pause — opens/closes with fade tween
- Assets from `assets/pause/` (background + button images)
- Buttons: Continue, Config (stub), Return to Main Menu
- `_go_main()` uses TransitionScreen.fade_to()

### Map (MapGenerator.gd)
- FastNoiseLite, 44×34 tiles, 32×32px isometric
- **3 area phases** determined by `ProgressionManager.data.current_area`:
  - **Area 1 — Floresta Podre (Rotten Forest):** dark wet soil + moss + mud puddles, border rocks, scatter: bones/plants/rocks/thorns/broken trees
  - **Area 2 — Cursed Land:** cursed tileset assets, diamond-shaped border colliders, position clamping on enemies
  - **Area 3 — Undead Cemetery:** undead tileset, cemetery environment, tombstones
- Floor zones by noise value: dark soil / mossy / green / rocky (area 1)
- Z-layer: floor(-10) → scatter(-8 to -2) → characters(0)
- Map modulate: `Color(0.55, 0.70, 0.55, 1.0)` — dark greenish corruption
- Scatter uses deterministic per-tile seeding (`col * 31 + row * 97`)
- Border colliders prevent player/enemy escape

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

**2. GalinhaPodre sprite asset** — enemy is functional but renders as green circle via `_draw()`
- Needs a proper pixel art sprite sheet from Mateus
- Drop into `assets/enemies/` and update `_draw()`/`_setup_animation()` in GalinhaPodre.gd

### 🟠 High

**3. Audio files** — `AudioManager` autoload is wired, but no `.ogg` files exist in `assets/audio/`
- All SFX and ambient references are in place — just need actual audio files
- See `assets_checklist.md` for the full list

**4. Player idle/attack animations** — walk animation exists (8-dir), but idle stops on frame 0 and no attack animation
- Sprite sheet: `assets/protagonista/walk/azrael_walk.png` — walk only, no idle/attack frames

### 🟡 Medium

**5. Game Over screen** with run summary (enemies killed, XP, time, area reached)
- Currently: game-over label → 3s delay → scene reload

**6. Area 1 boss victory screen** — after defeating area boss, show stats/transition

**7. Pause menu Config button** — exists as stub (no config screen implemented)

---

## Common Gotchas

- **Autoloads not recognized after external edit:** Godot editor → Project → Reload Current Project
- **WaveManager is NOT an autoload** — instantiated in World.gd `_ready()` via `load(...).new()`
- **Skeleton and GalinhaPodre have no .tscn** — spawned via `Skeleton_SCRIPT.new()` / `GALINHA_SCRIPT.new()` in WaveManager
- **Boar is unused** — `_spawn_boar()` exists in WaveManager but is never called; all waves use skeleton/knight/galinha
- **Boar/KnightCoxinha/Skeleton/GalinhaPodre stats are `var`** — WaveManager sets them per-instance
- **call_deferred for wave clear** — `tree_exited` fires before node is fully removed; check group size immediately gives wrong count
- **CanvasLayer layer order:** PauseMenu=25 > UpgradePanel=20 > ArenaUpgradePanel (TBD) > TransitionScreen=10 > HUD=2 > Atmosphere=1
- **Isometric world position formula:** `Vector2((col - row) * 16.0, (col + row) * 8.0)`
- **Skill HP cost must bypass iframes** — add `drain_hp()` to Player that skips `_invincibility_timer` check; never call `take_damage` for self-damage
- **`get_tree().paused = true` freezes all nodes** — any UI shown during pause needs `process_mode = PROCESS_MODE_ALWAYS` or `PROCESS_MODE_WHEN_PAUSED`
- **ProgressionManager.add_xp called by enemies on death** — Skeleton, KnightCoxinha, GalinhaPodre all call this in `_die()`
- **Player._apply_stats() called on upgrade_applied** — connects in `_ready()`, safe to call multiple times
- **Fragments (not skill_points) for upgrades** — `apply_upgrade()` calls `spend_fragments(cost)` with quadratic cost; `get_upgrade_cost(attribute)` returns current price
- **3 map phases via `current_area`** — MapGenerator reads `ProgressionManager.data.current_area` to determine tileset/scatter; area transitions handled in World.gd
- **GalinhaPodre has no sprite** — renders as green circle via `_draw()`; adding a sprite requires updating `_setup_animation()` and removing `_draw()` body rendering
- **AudioManager silently skips missing files** — all `load()` calls wrapped in `ResourceLoader.exists()`; game never crashes from missing audio

---

## Asset Locations

```
assets/protagonista/walk/azrael_walk.png              — 150×146 frames, 4 cols × 8 rows (N/NE/E/SE/S/SW/W/NW)
assets/enemies/knight_coxinha/walk/knight_coxinha_walk.png — 181×181 frames, 6 cols × 8 rows
assets/enemies/skeleton/Skeleton.png                  — 64×64 frames, 8 rows × 7-8 cols
assets/enemies/skeleton/Skeleton.png.import
assets/items/spear/spear_00.png                       — skeleton weapon visual
assets/critters/critters/boar/boar_SE_idle_strip.png  — 41×25 frames, 7 cols idle (legacy)
assets/isometric tileset/isometric tileset/separated images/tile_000..114.png
assets/life/bar_frame.png + bar_fill.png              — HUD health bar 220×70
assets/xp/xp_background.png + xp_bar_fill.png         — HUD XP bar
assets/forest/                                         — scatter: Bones (18), Broken_tree (7), Dead_tree (3), Plant (5), Rock (5), Thorn (5)
assets/edificacoes_grandes/                            — 18 large buildings (Hub uses _001, _010)
assets/edificacoes_pequenas/                           — 17 small buildings (Hub uses _001, _002)
assets/vegetacao_estruturas/                           — 19 vegetation/structures (MapGen border + Hub)
assets/tombulos_cercas/                                — 10 tombstones/fences (MapGen interior + Hub)
assets/props_decoracao/                                — 12 decoration props (MapGen interior + Hub)
assets/tiles_chao/                                     — 8 ground tile variants (Hub uses _001, _008)
assets/tela_inicial/background/tela_inicial_oathbreaker.png — main menu background
assets/tela_inicial/botoes/                            — menu buttons (Iniciar, Config, Creditos, Sair)
assets/pause/background/Paused2.png                   — pause menu background
assets/pause/botoes/continue.png + config.png         — pause buttons
assets/pause/return_menu_principal.png                — pause menu button
assets/audio/                                          — EMPTY (no .ogg files yet, AudioManager gracefully no-ops)
```

**Missing assets:**
- `assets/enemies/galinha_podre/` — no sprite exists; GalinhaPodre.gd uses procedural green circle
- `assets/audio/*.ogg` — all 10 SFX + ambient files missing

---

## Workflow Convention

- **OpenCode** handles all routine implementation (scripts, boilerplate, well-specified features)
- **Claude** handles architecture, complex logic, reviewing OpenCode output, giving OpenCode prompts
- When giving implementation tasks: write complete OpenCode prompts with exact file names, explicit code blocks, and "do not touch .tscn files" constraint
- Never edit .tscn files via text — use Godot editor or script-based node creation in `_ready()`
- Give OpenCode prompts ONE task at a time with clear file targets
