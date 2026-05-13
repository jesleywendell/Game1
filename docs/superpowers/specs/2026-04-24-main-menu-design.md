# Main Menu Design — 2026-04-24

## Overview
Tela inicial do jogo (IsometricGame2D) exibida automaticamente ao abrir. Usa a imagem `assets/tela_inicial/tela_de_inicio.png` como fundo e fornece três opções: Iniciar Jogo, Opções (placeholder), Sair.

## Arquitetura

### Novos arquivos
- `scenes/MainMenu.tscn` — cena raiz do jogo
- `scripts/MainMenu.gd` — orquestra fluxo do menu e troca de cenas
- `scripts/MenuButton.gd` — componente reutilizável de botão com animações

### Alteração em project.godot
`run/main_scene` muda de `res://scenes/World.tscn` para `res://scenes/MainMenu.tscn`.

### Hierarquia de nós
```
MainMenu (Node2D)
 └── CanvasLayer
      ├── Background (TextureRect)          — tela_de_inicio.png, full-screen
      ├── ButtonsContainer (VBoxContainer)  — centralizado na tela
      │    ├── BtnIniciar (Button + MenuButton.gd)
      │    ├── BtnOpcoes (Button + MenuButton.gd)
      │    └── BtnSair (Button + MenuButton.gd)
      ├── OptionsPanel (Panel)              — visible=false por padrão
      │    ├── Label "Opções — Em breve"
      │    └── BtnFechar (Button + MenuButton.gd)
      └── FadeRect (ColorRect, full-screen, preto)
```

## Animações

### Hover
- Scale: `1.0` → `1.05` via Tween, ease_out, 0.12s
- Modulate: normal → `Color(1.3, 1.3, 1.3)`, 0.12s

### Unhover
- Reverso: scale `1.05` → `1.0`, modulate normal, 0.10s

### Click (button_down)
- Scale: `1.05` → `0.95` em 0.05s

### Release (button_up)
- Scale: `0.95` → `1.0` em 0.08s
- Emite sinal `activated`

### Fade entrada
- FadeRect começa alpha=1, fade-out para alpha=0 em 0.5s no `_ready()`

### Fade saída (iniciar jogo)
- FadeRect fade-in de alpha=0 → 1 em 0.4s
- Ao completar: `get_tree().change_scene_to_file("res://scenes/World.tscn")`

## Fluxo de Dados

`MenuButton.gd` emite sinal `activated`. `MainMenu.gd` conecta cada botão:
- BtnIniciar → `_start_game()` → fade-out → change_scene
- BtnOpcoes → `_open_options()` → OptionsPanel.show()
- BtnSair → `get_tree().quit()`
- BtnFechar → OptionsPanel.hide()

Sem dependência circular: MenuButton não conhece MainMenu.

## Sem escopo neste spec
- Tela de Opções funcional (reservado para spec futuro)
- Música de fundo
- Save/load de configurações
