# OATHBREAKER — Assets Checklist

## ❌ MISSING — Needed, not yet delivered

### Enemy Sprites (Mateus)
- [ ] **Skeleton** sprite — `Skeleton.gd` uses white placeholder circle (r=14)
- [ ] **GalinhaPodre** sprite — `GalinhaPodre.gd` uses green placeholder circle (r=12)

> Minimum format: single-direction strip PNG (SE direction, like Boar). Drop into `assets/enemies/` and update the script's `_setup_animations()`.

### Audio (entire folder missing — `res://assets/audio/`)
- [ ] `sfx_attack.ogg` — melee swing
- [ ] `sfx_dash.ogg` — dash whoosh
- [ ] `sfx_damage_player.ogg` — player hit
- [ ] `sfx_player_die.ogg` — player death
- [ ] `sfx_skill_q.ogg` — Q burst (area)
- [ ] `sfx_skill_e.ogg` — E projectile launch
- [ ] `sfx_hp_drain.ogg` — soul drain (plays on Q and E use)
- [ ] `sfx_enemy_die.ogg` — enemy death (shared by all enemies)
- [ ] `sfx_boss_phase2.ogg` — KnightCoxinha phase 2 trigger
- [ ] `ambient_forest.ogg` — looping forest ambient (plays in World)

> Just create the `assets/audio/` folder and drop `.ogg` files in. AudioManager auto-loads them. Missing files are silently skipped — game runs fine without them.

---

## ✅ DONE — Present and wired

### Characters
- [x] `assets/protagonista/walk/azrael_walk.png` — Azrael 8-dir walk (150×146 frames, 4×8)
- [x] `assets/enemies/knight_coxinha/walk/knight_coxinha_walk.png` — KnightCoxinha 8-dir walk (181×181 frames, 6×8)
- [x] `assets/critters/critters/boar/boar_SE_idle_strip.png` — Boar idle (SE only)

### HUD / UI
- [x] `assets/life/bar_frame.png` + `bar_fill.png` — HP bar
- [x] `assets/xp/xp_background.png` + `xp_bar_fill.png` — XP bar
- [x] `assets/pause/background/Paused2.png` — Pause menu bg
- [x] `assets/pause/botoes/continue.png` + `config.png` — Pause buttons
- [x] `assets/pause/return_menu_principal.png` — Pause return button
- [x] `assets/tela_inicial/background/tela_inicial_oathbreaker.png` — Main menu bg
- [x] `assets/tela_inicial/botoes/Botão_Iniciar_Jogo.png`
- [x] `assets/tela_inicial/botoes/Botao_Configuracoes.png`
- [x] `assets/tela_inicial/botoes/Botao_Creditos.png`
- [x] `assets/tela_inicial/botoes/Botao_Sair_do_Jogo.png`

### Map Scatter — Forest (`assets/forest/`)
- [x] Bones × 18
- [x] Broken_tree × 7
- [x] Dead_tree × 3
- [x] Plant × 5
- [x] Rock × 5
- [x] Thorn × 5

### assets/ — world art (84 files — all present, moved from assets_godot/)
- [x] `assets/edificacoes_grandes/` — 18 large buildings (Hub uses _001, _010)
- [x] `assets/edificacoes_pequenas/` — 17 small buildings (Hub uses _001, _002)
- [x] `assets/vegetacao_estruturas/` — 19 vegetation/structures (MapGen border + Hub)
- [x] `assets/tombulos_cercas/` — 10 tombstones/fences (MapGen interior + Hub)
- [x] `assets/props_decoracao/` — 12 decoration props (MapGen interior + Hub)
- [x] `assets/tiles_chao/` — 8 ground tile variants (Hub uses _001, _008)

---

## 📦 AVAILABLE BUT UNUSED — Ready if needed

### assets/ world art — untapped
- `edificacoes_grandes_002-009, _011-018` — 16 more large buildings (Hub expansion)
- `edificacoes_pequenas_003-017` — 15 more small buildings
- `props_decoracao_001-005` — 5 more props (could expand MapGen INTERIOR_SCATTER)
- `tiles_chao_002-007` — 6 more ground tile variants
- `tombulos_cercas_006-008` — 3 more fence/tombstone variants
- `vegetacao_estruturas_010-014` — 5 more vegetation variants

### Unused critter sprites
- `assets/critters/critters/badger/` — full 4-dir badger (walk + idle), no GDD enemy mapped
- `boar_NE/NW_idle + run strips` — Boar.gd only uses SE_idle; run animations available
