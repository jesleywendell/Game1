# Chicken Boss Easter Egg — Design Spec
**Date:** 2026-05-10  
**Status:** Approved

---

## Overview

Add a hidden optional mini-boss (GalinhaPodre aprimorada) to Phase 1 only. The boss is an Easter egg — it sits in a far corner of the map, invisible until the player stumbles near it. Triggering it freezes the current wave, starts a solo boss fight, and resumes the wave after victory. Reward: 50 soul fragments.

---

## Scope

- **Phase 1 only** — spawned conditionally when `ProgressionManager.get_current_area() == 1`
- **Once per run** — flag `_chicken_defeated` in WaveManager prevents re-trigger
- **No new dependencies** — reuses existing `GalinhaPodre.gd` patterns, `ProgressionManager.add_fragments()`, and `JuiceManager`

---

## Components

### 1. `scripts/ChickenBoss.gd`

Extends `GalinhaPodre.gd`. Differences from base:

| Property | GalinhaPodre (normal) | ChickenBoss |
|---|---|---|
| MAX_HEALTH | 20 | 200 |
| DAMAGE | 8 | 25 |
| speed | 160 | 200 |
| xp_reward | 15 | 80 |
| Visual | green circle r=12 | gold circle r=22, scale 1.8× |

**Trigger zone:**
- Child `Area2D` named `TriggerZone` with `CircleShape2D` radius=120px
- On `body_entered` (player group): emits `boss_triggered` signal once, disables itself
- Flag `_trigger_used := false` prevents double-fire

**On death (`_die()` override):**
1. Calls `ProgressionManager.add_fragments(50)`
2. Emits `boss_defeated` signal
3. Calls `super._die()` for blood/hitstop/queue_free

**Signals:**
```gdscript
signal boss_triggered
signal boss_defeated
```

**Group:** `"chicken_boss"` — intentionally excluded from `"active_enemies"` so `_check_wave_clear` ignores it.

**Spawn position:** Fixed isometric coord `Vector2i(8, 75)` → `Vector2(-1072.0, 664.0)` in world space.  
This is the bottom-left edge of the Phase 1 map, away from all spawn corridors.

---

### 2. `scripts/WaveManager.gd` — additions

**New vars:**
```gdscript
var _chicken_boss_active := false
var _chicken_defeated    := false
var _saved_wave          := 0
var _saved_alive_count   := 0
```

**New method `suspend_for_chicken_boss()`:**
1. Set `_chicken_boss_active = true`, `_combat_active = false`
2. Record `_saved_wave = current_wave`, `_saved_alive_count = alive count`
3. Remove all `active_enemies` (queue_free, no signal)
4. Stop arena timer ticking (guarded by `_chicken_boss_active` in `_process`)

**New method `resume_after_chicken_boss()`:**
1. `_chicken_boss_active = false`, `_chicken_defeated = true`
2. If `_saved_alive_count == 0`: call `wave_cleared.emit(current_wave)` (wave was already done)
3. Else: re-spawn `_saved_alive_count` enemies for `current_wave` using existing spawn logic
4. `_alive_count = _saved_alive_count`, `_combat_active = true`

**`_process` guard:**
```gdscript
if not _combat_active or _frenzy_active or _boss_alive or _chicken_boss_active:
    return
```

**`_check_wave_clear` guard:**
```gdscript
if _chicken_boss_active:
    return
```

---

### 3. `scripts/World.gd` — additions

In `_ready()`, after WaveManager init:

```gdscript
if ProgressionManager.get_current_area() == 1:
    _spawn_chicken_boss()
```

**New method `_spawn_chicken_boss()`:**
1. Instantiate `ChickenBoss.gd` via `load(...).new()`
2. Set position to `Vector2(-1072.0, 664.0)`
3. Connect `boss_triggered` → `_wave_manager.suspend_for_chicken_boss()`
4. Connect `boss_defeated`  → `_wave_manager.resume_after_chicken_boss()`
5. Add to scene tree

---

## Data Flow

```
Player walks near corner
  → ChickenBoss.TriggerZone.body_entered
  → boss_triggered signal
  → WaveManager.suspend_for_chicken_boss()
      → kills active enemies
      → saves wave state
      → pauses timer

Player fights ChickenBoss
  → ChickenBoss._die()
  → ProgressionManager.add_fragments(50)
  → boss_defeated signal
  → WaveManager.resume_after_chicken_boss()
      → re-spawns saved_alive_count enemies
      → resumes timer + combat
```

---

## Edge Cases

| Case | Handling |
|---|---|
| Player triggers boss with 0 enemies alive (just cleared last one) | `_saved_alive_count = 0` → after boss dies, emit `wave_cleared` directly |
| Player dies during chicken boss fight | `_on_player_died` in World.gd handles game over normally; no special case needed |
| Player is in area 2 or 3 | `_spawn_chicken_boss()` is gated by `current_area == 1`; never spawned |
| Chicken boss killed before trigger fires | Impossible — trigger only fires once on proximity, chicken doesn't move until triggered |

---

## What's NOT in scope

- Chicken boss is NOT tracked in save data (resets each run by design)
- No HUD announcement when boss is triggered (discovery should feel organic)
- No special boss music (AudioManager files are empty anyway)
- No achievement/unlock tied to the boss kill

---

## Files Changed

| File | Change |
|---|---|
| `scripts/ChickenBoss.gd` | **New** |
| `scripts/WaveManager.gd` | Add 4 vars + 2 methods + 2 guards |
| `scripts/World.gd` | Add `_spawn_chicken_boss()` + conditional call in `_ready()` |
