# Phase 1 — Floresta Podre (Rotten Forest)

## Narrative Context
Azrael enters the outskirts of the Kaerlid forest, where corruption has begun to spread.
Life still exists but is in advanced decomposition.
Feel: beginning of corruption — decadent, yet still natural.

---

## Asset Verdict (revised)

| Asset | Usable? | How |
|-------|---------|-----|
| `isometric tileset/tile_012-014` | ✅ Floor | Dark wet soil — main floor |
| `isometric tileset/tile_020-023` | ✅ Floor | Dark earth + moss patches |
| `isometric tileset/tile_100` | ✅ Floor | Dark navy — mud puddles (rare) |
| `isometric tileset/tile_060-061` | ✅ Border | Dark rocky border edge |
| `first-scenario/.../Bones_shadow1_N.png` | ✅ Scatter | Scattered creature remains |
| `first-scenario/.../Broken_tree_shadow1_N.png` | ✅ Scatter | Fallen trunks (7 variants) |
| `first-scenario/.../Rock_shadow1_N.png` | ✅ Scatter | Mossy rocks (5 variants) |
| `first-scenario/.../Plant_shadow1_N.png` | ✅ Scatter | Dead vegetation |
| `first-scenario/.../Thorn_palnt_shadow2_N.png` | ✅ Scatter | Thorn patches (typo: "palnt") |
| `first-scenario/.../Dead_tree_shadow1_N.png` | ✅ Border scatter | Dead standing trees — edge wall |
| `first-scenario/.../Grave_shadow1_N.png` | ❌ Skip | Graveyard vibe — wrong phase |
| `first-scenario/.../Ruin_shadow1_N.png` | ❌ Skip | Ancient ruins — wrong phase |
| `first-scenario/.../Crystal_shadow1_N.png` | ❌ Skip | Bright green bush — wrong vibe |
| `first-scenario/.../Ground_rocks.png` | ❌ Skip | Top-down ground — wrong projection |

---

## Step 0 — Copy assets to `assets/forest/`

`first-scenario/` is in `.gitignore` — assets used in the game must be copied to the tracked `assets/` folder before implementation.

Copy only the files actually used (no need to copy the full pack):

```
Source: first-scenario/Free-Undead-Tileset-Top-Down-Pixel-Art/PNG/Objects_separately/
Dest:   assets/forest/

Files to copy:
  Bones_shadow1_{1..18}.png
  Plant_shadow1_{1..5}.png
  Broken_tree_shadow1_{1..7}.png
  Rock_shadow1_{1..5}.png
  Thorn_palnt_shadow2_{1..5}.png   ← typo in original filename, copy as-is
  Dead_tree_shadow1_{1..3}.png
```

After copying, update the path constant in MapGenerator:
```gdscript
const OBJECTS_PATH := "res://assets/forest/"
```

---

## Changes Required

### File 1: `scripts/MapGenerator.gd`

**A) New tile categories:**
```gdscript
const TILES_DARK_SOIL := [12, 13, 14]      # wet dark earth — main floor
const TILES_MOSSY     := [20, 21, 22, 23]  # dark earth + moss patches
const TILES_MUD       := [100]             # dark navy mud puddles (rare)
const TILES_BORDER    := [60, 61]          # dark rocky border
```

**B) New noise thresholds (interior tiles):**
```
noise < 0.0   → TILES_DARK_SOIL  (~50% — main wet earth)
noise < 0.45  → TILES_MOSSY      (~35% — mossy variations)
noise >= 0.45 → TILES_MUD        (~15% — mud puddles)
```

**C) Scatter system — `_spawn_scatter()` called after floor generation**

Uses `col * 31 + row * 97` for deterministic per-tile seeding.

Interior scatter (skip border rows/cols):
| Object | Chance | Variants | Notes |
|--------|--------|----------|-------|
| `Bones_shadow1_N.png` | 12% | N=1..18 | creature remains |
| `Broken_tree_shadow1_N.png` | 8% | N=1..7 | fallen trunks |
| `Rock_shadow1_N.png` | 6% | N=1..5 | mossy rocks |
| `Plant_shadow1_N.png` | 10% | N=1..5 | dead vegetation |
| `Thorn_palnt_shadow2_N.png` | 5% | N=1..5 | thorn patches |

Border zone scatter (row/col ≤ 2 or ≥ MAX−3):
| Object | Chance | Variants |
|--------|--------|----------|
| `Dead_tree_shadow1_N.png` | 30% | N=1..3 |
| `Broken_tree_shadow1_N.png` | 20% | N=1..7 |

z_index for scatter sprites = `row` (correct depth ordering)

**D) Map modulate — dark greenish corruption tone:**
```gdscript
modulate = Color(0.55, 0.70, 0.55, 1.0)
```

**Object path constant:**
```gdscript
const OBJECTS_PATH := "res://assets/forest/"
```

---

### File 2: `scenes/World.tscn`

**A) Dark background:**
Add `ColorRect` as first child of World:
- Color: `#080e08` (dark green-black)
- Anchors: full-rect
- `z_index = -100`

**B) Fog layer:**
Add `CanvasLayer` (layer = 1, above world but below HUD) containing a `ColorRect`:
- Color: `Color(0.08, 0.15, 0.08, 0.32)` — dark green semi-transparent
- Anchors: full-rect
- Simulates constant low greenish mist

---

## Critical Notes

- `Broken_ tree_shadow3_N.png` has a **space in the filename** (`Broken_ tree`) — use `Broken_tree_shadow1_N.png` (no space) to be safe
- `Thorn_palnt` typo in filename — must use exactly as-is
- Scatter scale may need tuning: try `scale = Vector2(1.5, 1.5)` on scatter sprites (objects are ~16px source, floor is 32px)
- No changes to: `Player.gd`, `Boar.gd`, `HUD.gd`, `SkillManager.gd`, `Projectile.gd`, `World.gd`

---

## Verification Checklist

- [ ] Floor is dark wet brown/mossy (not current orange-brown dirt)
- [ ] Mud puddles (dark navy tiles) appear scattered
- [ ] Bones and dead plants visible on floor
- [ ] Fallen trunks and mossy rocks scattered mid-map
- [ ] Dead trees form a ring at map edges
- [ ] Greenish modulate tints the whole map
- [ ] Fog overlay gives a misty feel
- [ ] Background is dark green-black
- [ ] Player, dash, skills, Boar combat all still work
