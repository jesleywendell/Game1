# INSTITUIÇÃO DE ENSINO SUPERIOR - iCEV
**Curso:** Engenharia de Software
**Disciplina:** Introdução ao Desenvolvimento de Jogos | **Professor:** Samuel

---

# GAME DESIGN DOCUMENT: OATHBREAKER
**Versão:** 2.1 Revisada – Março de 2026

### Equipe
| Integrante | Responsabilidade |
| :--- | :--- |
| Guilherme Ancheschi Werneck Pereira | Desenvolvedor |
| Jesley Wendell Leite Soares | Desenvolvedor |
| Lara Bezerra do Vale Silva | Diretora Criativa |
| Mateus Pessoa Costa | Designer Gráfico |
| Víctor de Oliveira Souza Portelada | QA |

---

## Sumário
| Seção | Tópico | Página |
| :--- | :--- | :--- |
| **1** | **Visão Geral (High Concept)** | **3** |
| 1.1 | Título do Jogo | 3 |
| 1.2 | Elevator Pitch | 3 |
| 1.3 | Gênero e Perspectiva | 3 |
| 1.4 | Público-Alvo | 3 |
| 1.5 | Diferencial (USP) | 3 |
| **2** | **Mecânicas de Jogo** | **4** |
| 2.1 | Controles | 4 |
| 2.2 | Condições de Vitória | 4 |
| 2.3 | Condições de Derrota | 4 |
| 2.4 | Sistemas do Jogo | 4 |
| 2.4.1 | Parâmetros Base do Protagonista | 5 |
| 2.4.2 | Parâmetros dos Inimigos | 5 |
| 2.4.3 | Parâmetros dos Bosses | 5 |
| 2.4.4 | Sistema de Inventário | 6 |
| 2.4.5 | Sistema de Combate | 6 |
| 2.4.6 | Sistema de Progressão | 6 |
| **3** | **Game Loop** | **7** |
| 3.1 | Fluxo Resumido | 7 |
| 3.2 | Loop Micro (por frame) | 7 |
| 3.3 | Loop Macro (por run) | 7 |
| **4** | **Narrativa e Ambientação** | **8** |
| 4.1 | Sinopse | 8 |
| 4.2 | Personagens | 8 |
| 4.3 | Cenário | 8 |
| **5** | **Level Design** | **9** |
| 5.1 | Progressão do Jogo | 9 |
| 5.2 | Momentos de Dificuldade | 9 |
| 5.3 | Mockup da Interface (HUD) | 9 |
| 5.4 | Tela de Game Over | 9 |
| 5.5 | Tela de Vitória | 10 |
| **6** | **Estética e Áudio** | **11** |
| 6.1 | Estilo Visual | 11 |
| 6.2 | Referências Visuais (Moodboard) | 11 |
| 6.3 | Sonoplastia | 12 |
| **7** | **Planejamento Técnico** | **13** |
| 7.1 | Engine Escolhida | 13 |
| 7.2 | Ferramentas de Apoio | 13 |
| 7.3 | Escopo: MVP vs. Stretch Goals | 13 |
| 7.4 | Cronograma | 14 |

---

## 1. Visão Geral (High Concept)

### 1.1 Título do Jogo
**OATHBREAKER**

### 1.2 Elevator Pitch
Um Action RPG 2D com câmera isométrica onde um clérigo perjurador enfrenta criaturas corrompidas em uma floresta amaldiçoada para restaurar um mundo consumido pelas sombras. O jogador alterna entre combate corpo a corpo com lança, habilidades divinas corrompidas e um sistema de progressão roguelite baseado em runs curtas com escolhas de melhorias entre combates.

### 1.3 Gênero e Perspectiva
* **Gênero:** Action RPG 2D (Dark Fantasy / Roguelite)
* **Perspectiva:** Isométrica

### 1.4 Público-Alvo
* **Faixa etária:** 16-30 anos
* **Perfil:** Jogadores de PC que consomem jogos independentes 2D e apreciam runs curtas (15-30 minutos), progressão roguelite e ambientação dark fantasy sombria. São jogadores que buscam desafio mecânico baseado em reflexo e posicionamento, comparáveis ao público de Hades.
* **Plataforma alvo:** PC (Windows/Linux)
* **Classificação indicativa:** 14+ (violência fantasiosa)

### 1.5 Diferencial (USP)
O diferencial de OATHBREAKER está na combinação de três elementos:
* **Combate posicional isométrico com lança:** Diferente da maioria dos action RPGs 2D que usam perspectiva top-down ou side-scroller, a câmera isométrica adiciona uma camada de profundidade ao posicionamento em combate. O uso de lança como arma primária exige gerenciamento de distância e timing, distinto do combate corpo a corpo genérico (espada/escudo).
* **Sistema de habilidades divinas corrompidas:** As habilidades do protagonista são poderes sagrados degradados pelo perjúrio — isso afeta mecanicamente o jogo (habilidades têm custo de vida e efeitos colaterais) e narrativamente cria tensão entre redenção e poder.
* **Progressão roguelite com narrativa contínua:** Cada run não é puramente mecânica — o avanço desbloqueia fragmentos de lore e diálogos de NPCs no hub, similar ao modelo narrativo de Hades, mas com estética pixel art isométrica e tom mais sombrio.

---

## 2. Mecânicas de Jogo

### 2.1 Controles
| Ação | Tecla / Botão |
| :--- | :--- |
| Mover | [W, A, S, D] |
| Dash (esquiva) | [Barra de espaço] |
| Ataque básico (estocada de lança) | Botão esquerdo do mouse |
| Golpe Sagrado (campo de dano em área) | [Q] |
| Lança Divina (projétil direcional) | [E] |
| Interagir / Coletar | [F] |
| Abrir/fechar inventário | [I] |
| Pausar | [ESC] |

### 2.2 Condições de Vitória
* **Vitória de arena:** Eliminar todos os inimigos da onda atual dentro do limite de tempo (90 segundos por onda). Cada arena contém 2-4 ondas de inimigos.
* **Vitória de boss:** Reduzir o HP do boss a 0. Bosses possuem fases com padrões distintos de ataque (ver seção 2.4).
* **Vitória de run:** Completar as 3 áreas da floresta e derrotar o boss final (Jess Leymos-kaa).

### 2.3 Condições de Derrota
* **Morte:** HP do protagonista chega a 0. O jogador é devolvido ao hub central com os recursos permanentes coletados até aquele ponto. Melhorias temporárias da run são perdidas.
* **Timeout (opcional):** Se o tempo da arena expirar (90s), inimigos restantes recebem +50% de dano e velocidade (modo frenético), aumentando pressão sem forçar derrota imediata.

### 2.4 Sistemas do Jogo

#### 2.4.1 Parâmetros Base do Protagonista
| Parâmetro | Valor Base | Observação |
| :--- | :--- | :--- |
| HP (vida) | 100 | Pode ser aumentado no hub (+10/upgrade, máx 150) |
| Velocidade de movimento | 200 px/s | Constante, não escalável |
| Dano do ataque básico | 1.0 | Estocada de lança; hitbox 48x16 px a 32 px do centro; duração 0.35s |
| Cooldown do ataque | 0.2 s | Jogador para completamente durante o ataque |
| Dash - velocidade | 700 px/s | Usa última direção de movimento; não pode ser usado durante ataque |
| Dash - duração | 0.15 s | - |
| Dash - cooldown | 1.0 s | Reduzível com upgrade |
| Golpe Sagrado (Q) - dano | 2.0 | Campo de dano circular, raio 80 px; custo: 5 HP |
| Golpe Sagrado (Q) - cooldown | 3.0 s | Inicia após os 0.3s de duração ativa |
| Lança Divina (E) - dano | 1.5 | Projétil direcional a 400 px/s, tempo de vida 2.0s; custo: 3 HP |
| Lança Divina (E) - cooldown | 2.0 s | Projétil destruído ao colidir com inimigo |

> **Nota sobre o custo de HP das habilidades:** As habilidades divinas de Azrael foram corrompidas pelo perjúrio. Mecanicamente, isso se traduz em um custo de vida para cada uso, reforçando a tensão narrativa entre redenção e autodestruição. O jogador deve gerenciar seu HP não apenas contra inimigos, mas contra o próprio kit de habilidades.

#### 2.4.2 Parâmetros dos Inimigos
| Inimigo | HP | Dano | Velocidade | Comportamento |
| :--- | :--- | :--- | :--- | :--- |
| Esqueleto (básico) | 30 | 10 | 120 px/s | Persegue e ataca corpo a corpo |
| Galinha Podre | 20 | 8 | 160 px/s | Rápida, ataque em investida |
| Cavaleiro Corrupto | 60 | 18 | 90 px/s | Lento, ataque em área |
| Moshor das Moccas | 45 | 12 | 140 px/s | Ataque à distância (projétil) |

#### 2.4.3 Parâmetros dos Bosses
| Boss | HP Total | Fases | Dano | Padrão |
| :--- | :--- | :--- | :--- | :--- |
| Coxinha Knight (Boss 1) | 250 | 2 | 20-30 | Carga / golpe em área |
| Triss (Boss 2) | 400 | 3 | 15-25 (projéteis) | Projéteis / invocação |
| Rotten Chicken (secreto) | 180 | 1 | 35 | Investida rápida aleatória |
| Jess Leymos-kaa (Final) | 600 | 3 | 20-40 | Teleporte / AoE + invocação |

#### 2.4.4 Sistema de Inventário
Sistema funcional e visual que permite ao jogador armazenar, organizar, equipar e utilizar itens coletados durante a jogabilidade. Capacidade máxima: 12 slots. Itens incluem poções de cura (+25 HP), fragmentos de alma (recurso permanente) e relíquias (buffs passivos temporários para a run atual).

#### 2.4.5 Sistema de Combate
Combate em tempo real em arenas compactas. O jogador se move com WASD em 4 direções diagonais (perspectiva isométrica), mira a direção do ataque com o mouse e alterna entre ataque básico (estocada de lança), habilidades divinas corrompidas (Q: Golpe Sagrado — campo de dano em área; E: Lança Divina — projétil direcional) e dash. O ataque básico utiliza uma hitbox retangular de 48x16 px posicionada a 32 px do centro do personagem, representando o alcance frontal da lança; cada inimigo só pode ser atingido uma vez por ataque. O jogador para completamente durante o ataque (duração 0.35s). Colisão do jogador: círculo de raio 16 px. A física é arcade: velocidade constante, sem aceleração, prioridade em resposta imediata. As habilidades divinas consomem HP ao serem usadas, refletindo a corrupção dos poderes sagrados de Azrael.

#### 2.4.6 Sistema de Progressão
* **Recursos temporários (por run):** Ao final de cada arena, o jogador escolhe 1 de 3 melhorias aleatórias: +10% dano, +15 HP máximo, -0.2s cooldown de dash, habilidade bônus (ataque em área), ou velocidade +10%. Perdidas ao morrer.
* **Recursos permanentes:** Fragmentos de Alma coletados ao derrotar inimigos (1-3 por inimigo, 10-20 por boss). Usados no hub para comprar upgrades permanentes: Força (+3 dano, custo: 15 fragmentos), Vitalidade (+10 HP, custo: 12 fragmentos), Agilidade (-0.1s dash cooldown, custo: 20 fragmentos). Máximo de 5 upgrades por atributo.

---

## 3. Game Loop

### 3.1 Fluxo Resumido
Hub Central → Entrar na Floresta (Área 1/2/3) → Arena de Combate (2-4 ondas, limite 90s) → Vitória → Escolha de Melhoria Temporária (1 de 3) → Próxima Arena ou Boss da Área → Vitória do Boss → Avança para próxima área / Derrota → Retorna ao Hub com Fragmentos de Alma → Compra upgrades permanentes → Nova tentativa.

### 3.2 Loop Micro (por frame)
* **Entrada:** Movimentação WASD, mira com mouse, execução de ações (ataque com lança, habilidades divinas, dash).
* **Processamento:** Atualiza posição, verifica colisões (hitboxes), aplica dano e estados, resolve IA dos inimigos, decrementa cooldowns.
* **Feedback:** Animações de ataque, efeitos visuais de impacto (screen shake leve, flash branco no inimigo), som de acerto, atualização da barra de vida e cooldowns na HUD.

### 3.3 Loop Macro (por run)
* **Recompensa imediata:** Escolha de melhoria temporária entre arenas (ex: +10% dano, +15 HP, -0.2s cooldown dash).
* **Recompensa permanente:** Fragmentos de Alma acumulados durante a run (mantidos mesmo ao morrer). 1-3 por inimigo comum, 10-20 por boss.
* **Conversão no Hub:** Fragmentos trocados por upgrades permanentes de Força, Vitalidade ou Agilidade (ver seção 2.4.6).
* **Progressão narrativa:** Cada boss derrotado desbloqueia novos diálogos de NPCs no hub e fragmentos de lore sobre a história de Kaerlid e o passado de Azrael.

---

## 4. Narrativa e Ambientação

### 4.1 Sinopse
A terra de Kaerlid foi devastada por forças sombrias — uma maldição lançada por Jess Leymos-kaa, cuja visão distorcida da humanidade nasceu do ódio e do ressentimento. Campos férteis viraram terras mortas, animais se corromperam e cidades tornaram-se ruínas silenciosas. O protagonista, Azrael, um clérigo caçador de monstros expulso da igreja por quebrar seu juramento, busca agora redenção enquanto cumpre a missão de restaurar o mundo — mesmo que seus poderes divinos, corrompidos pelo perjúrio, cobrem um preço em sangue a cada uso.

### 4.2 Personagens
| Personagem | Função | Classe/Tipo | Descrição |
| :--- | :--- | :--- | :--- |
| Azrael | Protagonista | Clérigo/Lanceiro | Ex-clérigo perjurador em busca de redenção; empunha uma lança sagrada e canaliza poderes divinos corrompidos |
| Jess Leymos-kaa | Boss Final | Bruxo | Responsável pela maldição de Kaerlid |
| Triss | Boss 2 | Maga | Guardiã corrompida da floresta profunda |
| Coxinha Knight | Boss 1 | Cavaleiro | Primeiro guardião da floresta exterior |
| Rotten Chicken | Boss Secreto | Galinha | Escondido em área opcional |
| NPCs do Hub | Figurantes | Diversos | Fornecem lore, upgrades e contexto narrativo |

### 4.3 Cenário
O jogo se passa em uma floresta corrompida e de atmosfera sombria: árvores retorcidas bloqueiam a luz e uma névoa densa cobre o solo. O ambiente transmite constante ameaça e decadência — criaturas deformadas pela corrupção e trilhas estreitas conduzem o jogador por arenas naturais de combate. A floresta parece viva, hostil e marcada por uma força obscura que domina o território.

---

## 5. Level Design

### 5.1 Progressão do Jogo
Menu Principal → Hub Central (upgrades, NPCs, lore) → Área 1: Floresta Exterior (3 arenas + Coxinha Knight) → Área 2: Floresta Profunda (4 arenas + Triss) → Área 3: Coração da Corrupção (4 arenas + Jess Leymos-kaa) → Tela de Vitória / A qualquer momento: Derrota → Tela de Game Over → Hub.

### 5.2 Momentos de Dificuldade
| Momento | Descrição | Quando |
| :--- | :--- | :--- |
| Apresentação | Tutorial interativo: movimentação, ataque com lança, dash, habilidades divinas | Área 1, Arena 1 |
| Teste | Arenas com ondas crescentes; inimigos variados exigem uso de dash e posicionamento | Arenas 2-3 de cada área |
| Clímax | Boss com múltiplas fases, padrões de ataque distintos, punição por erros | Final de cada área |
| Pico de tensão | Boss final com 3 fases + invocação de adds + AoE crescente | Área 3, arena final |

### 5.3 Mockup da Interface (HUD)
Elementos da HUD identificados no mockup:

| Elemento | Posição na Tela | Função |
| :--- | :--- | :--- |
| Corações (vida) | Superior esquerdo | Representa HP do jogador (1 coração = 25 HP, total 4 = 100 HP) |
| Barra verde (stamina) | Abaixo dos corações | Indica cooldown geral ou recurso de energia para habilidades |
| Ícone circular (recurso) | Ao lado da barra | Contador de Fragmentos de Alma coletados na run atual |
| Slots Q e E (a implementar) | Inferior esquerdo | Ícones de Golpe Sagrado (Q) e Lança Divina (E) com indicador visual de cooldown |
| Mini-mapa (a implementar) | Inferior direito | Mapa da arena atual com posição do jogador e inimigos |

### 5.4 Tela de Game Over
Ao morrer, a tela escurece gradualmente (fade to black, 1.5s) e exibe:
* **Texto central:** "OATHBREAKER" em vermelho, com subtítulo "A redenção exige sacrifício"
* **Resumo da run:** Inimigos derrotados, Fragmentos de Alma coletados, tempo total, área alcançada
* **Opções:** [Retornar ao Hub] - [Tentar Novamente] - [Menu Principal]

*Nota de Imagem: Mockup da tela de Game Over contida no arquivo fonte (`tela_gameover.png`).*

### 5.5 Tela de Vitória
Após derrotar Jess Leymos-kaa, cutscene final mostrando a floresta se restaurando. Tela exibe estatísticas completas da run final e desbloqueia modo Novo Jogo+ (inimigos com +30% HP e dano, novas relíquias disponíveis).

---

## 6. Estética e Áudio

### 6.1 Estilo Visual
Pixel Art 2D com câmera isométrica. Paleta escura com tons de marrom, verde musgo e vermelho sangue.

### 6.2 Referências Visuais (Moodboard)
* **Jogos de referência:** A Lenda do Herói (pixel art isométrica, estilo de combate), Hades (estrutura roguelite, narrativa entre runs, design de arenas).
* **Ambientação visual:** Baldur's Gate 3 — Ato 2, Terras Sombrias (névoa densa, árvores mortas, iluminação fria); The Witcher 3 — Floresta das Bruxas (vegetação retorcida, atmosfera opressiva, trilhas estreitas).
* **Paleta de cores alvo:** Fundo em tons de #1a1a2e (azul escuro profundo), vegetação em #2d5016 (verde musgo), destaques de dano/perigo em #8B0000 (vermelho escuro), elementos sagrados/corrompidos em #c0a030 (dourado desgastado).

*Nota de Imagens: O documento contém referências de A Lenda do Herói (`moodboard_01.png`), Hades (`moodboard_02.png`), Baldur's Gate 3 (`moodboard_03.png`) e The Witcher 3 (`moodboard_04.png`).*

### 6.3 Sonoplastia
A trilha sonora utiliza ambientação dark fantasy para reforçar a sensação de melancolia constante na floresta corrompida. Os efeitos sonoros priorizam clareza e impacto, com feedbacks distintos para ataques (som metálico de lança), dano recebido (impacto grave), habilidades divinas (eco reverberante com distorção), morte de inimigos (dissolução) e custo de HP das habilidades (pulso grave dissonante, indicando a corrupção). Sons ambientais como vento, insetos e ruídos distantes contribuem para a imersão.

---

## 7. Planejamento Técnico

### 7.1 Engine Escolhida
Godot 4.x — engine open source com suporte nativo a GDScript, 2D isométrico e exportação multiplataforma.

### 7.2 Ferramentas de Apoio
| Categoria | Ferramentas |
| :--- | :--- |
| Arte/Sprites | DALL·E (concept art), Nano Banana (pixel art), Aseprite (animação sprite) |
| Áudio | Bfxr (SFX), Freesound (ambientes), Audacity (edição) |
| Animação | Voidless |
| Versionamento | Git / GitHub |
| Comunicação | Discord + Trello |

### 7.3 Escopo: MVP vs. Stretch Goals
Para garantir uma entrega funcional dentro do prazo de 5 semanas, o escopo é dividido em MVP (mínimo produto viável — entrega obrigatória) e Stretch Goals (funcionalidades aspiracionais, implementadas apenas se houver tempo disponível).

#### MVP — Entregável em 5 semanas
| Categoria | Detalhes |
| :--- | :--- |
| Movimentação | WASD isométrico + mira com mouse + dash com i-frames |
| Combate | Ataque básico com lança + 2 habilidades (Golpe Sagrado, Lança Divina) com custo de HP |
| Inimigos | 2 tipos funcionais (Esqueleto, Galinha Podre) com IA de perseguição e ataque |
| Estrutura | Área 1 completa: 3 arenas com ondas + Boss 1 (Coxinha Knight, 2 fases) |
| Progressão | Escolha de melhoria temporária entre arenas (1 de 3) |
| Hub | Hub básico com 1 NPC de upgrade (Fragmentos de Alma → Força/Vitalidade/Agilidade) |
| HUD | Corações (HP), barra de cooldowns, contador de Fragmentos de Alma |
| Telas | Menu Principal, Game Over (com resumo de run), Tela de Vitória da Área 1 |
| Áudio | SFX básicos (ataque, dano, morte de inimigo, dash) + 1 trilha ambiente |

#### Aspiracional — Stretch Goals
| Categoria | Detalhes |
| :--- | :--- |
| Áreas extras | Área 2 (Floresta Profunda + Triss) e Área 3 (Coração da Corrupção + Jess Leymos-kaa) |
| Inimigos extras | Cavaleiro Corrupto e Moshor das Moccas |
| Boss secreto | Rotten Chicken + área opcional para acessá-lo |
| Inventário | Sistema completo com 12 slots, poções, relíquias |
| Narrativa | Diálogos de NPCs no hub com lore progressivo desbloqueado por boss derrotado |
| Mini-mapa | Mapa da arena com posição do jogador e inimigos |
| Novo Jogo+ | Modo NG+ com inimigos +30% HP/dano e novas relíquias |
| Áudio expandido | Trilhas distintas por área, SFX de habilidades com eco reverberante |

### 7.4 Cronograma
| Semana | Período | Entregas / Marcos |
| :--- | :--- | :--- |
| 1 | 11-17 Mar | Configuração do projeto Godot; movimentação WASD + mira no mouse; câmera isométrica; colisões básicas jogador-cenário; protótipo de ataque com lança (hitbox retangular 48x16) |
| 2 | 18-24 Mar | IA básica de inimigos (perseguição + ataque); sistema de dano e HP; HUD funcional (corações, barra de stamina, cooldowns); primeira arena jogável na floresta |
| 3 | 25-31 Mar | Habilidades Golpe Sagrado (Q) e Lança Divina (E) com custo de HP; mecânica de dash com i-frames; sistema de escolha de melhorias entre arenas; balanceamento inicial com parâmetros numéricos da seção 2.4 |
| 4 | 01-04 Abr | Boss 1 (Coxinha Knight) com 2 fases; tela de Game Over e tela de vitória; hub central básico com NPC de upgrade; Fragmentos de Alma funcionais |
| 5 (buffer) | 05-07 Abr | Testes de gameplay e balanceamento; correção de bugs; ajustes visuais e sonoros; polimento de feedback (screen shake, flash); geração da build executável; início de stretch goals se houver tempo |

> **Observação:** O cronograma acima cobre exclusivamente o MVP. Stretch Goals serão implementados apenas se a semana 5 (buffer) não for inteiramente consumida por correções e polimento. A prioridade de implementação dos stretch goals segue a ordem: inimigos extras → inventário → Área 2 → demais.