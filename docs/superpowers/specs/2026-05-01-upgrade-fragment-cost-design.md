# Design: Custo de Fragmentos para Upgrades de Level-Up

**Data:** 2026-05-01  
**Status:** Aprovado

---

## Resumo

Substituir o sistema de `skill_points` gratuitos por um sistema onde cada upgrade de level-up custa fragmentos da alma. O custo escala individualmente por tipo de upgrade usando fórmula quadrática. O hub de upgrades permanentes é removido.

---

## Fórmula de Custo

```
custo(tipo, n) = base[tipo] + escala[tipo] × n²
```

`n` = número de upgrades já comprados daquele tipo (antes desta compra).

### Tabela de valores

| Atributo       | base | escala | 1º | 2º | 3º | 4º | 5º  |
|----------------|------|--------|-----|-----|-----|-----|-----|
| Vida Máxima    | 6    | 3      | 6   | 9   | 18  | 33  | 54  |
| Velocidade     | 8    | 4      | 8   | 12  | 24  | 44  | 72  |
| Dano do Ataque | 10   | 5      | 10  | 15  | 30  | 55  | 90  |
| Dano das Skills| 12   | 6      | 12  | 18  | 36  | 66  | 108 |

---

## Fluxo do Jogador

1. Jogador sobe de nível → `ProgressionManager.leveled_up` emite
2. `UpgradePanel` abre, jogo pausa (`get_tree().paused = true`)
3. Painel exibe 4 botões de upgrade com custo atual em fragmentos
   - Botão habilitado se `soul_fragments >= custo`
   - Botão desabilitado (texto do custo em vermelho) se insuficiente
   - Saldo atual de fragmentos exibido no topo do painel
4. Jogador clica num upgrade acessível → `ProgressionManager.spend_fragments(custo)` → upgrade aplicado → painel fecha (1 upgrade por level-up)
5. Se nenhum upgrade for acessível → botão "Fechar" disponível para sair sem comprar

---

## Mudanças nos Sistemas

### ProgressionManager.gd
- Adicionar constantes `UPGRADE_BASE` e `UPGRADE_SCALE` por tipo
- Adicionar método `get_upgrade_cost(attribute: String) -> int`
- Modificar `apply_upgrade()` para chamar `spend_fragments(custo)` em vez de decrementar `skill_points`
- Remover `HUB_UPGRADE_COSTS`, `HUB_UPGRADE_MAX`, `buy_hub_upgrade()`, `get_dash_cd_reduction()`, `get_hub_upgrade_count()`, `_get_upgrade_count()`
- Manter `add_fragments`, `spend_fragments`, `get_fragments`

### UpgradePanel.gd
- Exibir saldo de fragmentos no topo
- Exibir custo de cada upgrade no botão
- Desabilitar botões sem fragmentos suficientes (custo em vermelho)
- Adicionar botão "Fechar" sempre visível
- Remover lógica de `skill_points`

### PlayerData.gd
- Remover campo `skill_points` (ou manter zerado para compatibilidade — preferir remover)
- Remover campo `dash_cd_upgrades`
- Manter `soul_fragments`

### Cenas/Scripts a remover
- Hub upgrade shop (se existir como cena separada)
- Qualquer referência a `buy_hub_upgrade`, `dash_cd_upgrades`, `skill_points` fora dos arquivos acima

---

## O que NÃO muda

- `soul_fragments` é ganho da mesma forma que antes (inimigos, orbs, etc.)
- `UpgradePanel` ainda abre apenas no level-up
- Apenas 1 upgrade por level-up
- Lógica de XP e leveling (`add_xp`, `xp_required`) intacta
- Upgrades de stats (`get_attack_damage`, `get_skill_damage_bonus`, `get_speed`, `get_max_health`) intactos
