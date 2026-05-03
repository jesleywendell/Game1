# OATHBREAKER — Implementation Plan

## Task 1 — Remove enemy detection range limits
- [ ] Skeleton.gd: `var moving := dist < DETECT_RANGE and dist > STOP_RANGE` → `var moving := dist > STOP_RANGE`
- [ ] GalinhaPodre.gd: `if dist < DETECT_RANGE and dist > STOP_RANGE:` → `if dist > STOP_RANGE:`
- [ ] KnightCoxinha.gd: `if dist < DETECT_RANGE and dist > STOP_RANGE:` → `if dist > STOP_RANGE:`

## Task 2 — Make Phase 1 map square
- [ ] MapGenerator.gd: `MAP_COLS := 132` → `MAP_COLS := 120`, `MAP_ROWS := 102` → `MAP_ROWS := 120`

## Task 3 — Redesign both upgrade panels
- [ ] UpgradePanel.gd: dark fantasy visual redesign (StyleBoxFlat, two-line buttons, gold accents)
- [ ] ArenaUpgradePanel.gd: same visual treatment
