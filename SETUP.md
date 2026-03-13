# Jogo Isométrico 2D — Guia de Configuração no Godot 4

## 1. Criar o projeto

1. Abra o Godot 4
2. **New Project** → escolha esta pasta como raiz: `OneDrive/PRODATER/IsometricGame2D`
3. Renderer: **Compatibility** (mais leve para 2D)

---

## 2. Configurar o Input Map (WASD)

`Project → Project Settings → Input Map`

Adicione 4 ações novas clicando em **Add Action**:

| Nome da ação  | Tecla |
|---------------|-------|
| `move_up`     | W     |
| `move_down`   | S     |
| `move_left`   | A     |
| `move_right`  | D     |

Para cada ação: clique no **+** ao lado dela → **Key** → pressione a tecla.

---

## 3. Montar a cena do Player

1. **Scene → New Scene**
2. Crie o nó raiz: `CharacterBody2D` → renomeie para `Player`
3. Adicione filhos:
   - `CollisionShape2D` → no Inspector, Shape: **CircleShape2D** (radius 16)
   - `Sprite2D` (qualquer sprite provisório, ex: ícone do Godot)
   - `Camera2D` → no Inspector, ative **Position Smoothing Enabled** (opcional)
4. Com `Player` selecionado, arraste `scripts/Player.gd` no campo **Script** do Inspector
5. Salve como `scenes/Player.tscn`

---

## 4. Montar a cena principal

1. **Scene → New Scene**
2. Crie o nó raiz: `Node2D` → renomeie para `World`
3. Instancie o Player: **Scene → Instantiate Child Scene** → `scenes/Player.tscn`
4. Adicione um `TileMapLayer` para o chão isométrico:
   - No Inspector: **Tile Set** → New TileSet
   - Em TileSet, mude **Tile Shape** para `Isometric`
   - **Tile Size**: 128×64 (proporção 2:1 clássica)
5. Salve como `scenes/World.tscn`
6. Defina como cena principal: **Project → Project Settings → Application → Run → Main Scene**

---

## 5. Resultado esperado

- **W** → jogador move para cima-esquerda (Noroeste)
- **S** → jogador move para baixo-direita (Sudeste)
- **A** → jogador move para baixo-esquerda (Sudoeste)
- **D** → jogador move para cima-direita (Nordeste)
- Combinações (ex: W+D) resultam em movimento para cima (Norte puro)

---

## Próximos passos sugeridos

- Adicionar animações com `AnimatedSprite2D` para cada direção
- Criar tiles isométricos no `TileMapLayer` com colisão
- Implementar ordenamento de profundidade (Y-Sort) para sobreposição correta de sprites
