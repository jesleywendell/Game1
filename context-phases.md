first phase: an forest with dark vibes and skulls, a dark themed one, using as reference the /Users/seunome/Code/Game1/first-scenario folder assets.1.1 Fase 1 — Floresta Podre (Terras Devastadas)
Contexto: Azrael adentra a periferia da floresta de Kaerlid, onde a corrupção começou
a se espalhar. A vida ainda existe, mas está em estado avançado de decomposição.
Ambiente:
• Árvores secas e retorcidas
• Névoa baixa constante
• Iluminação fraca com tons esverdeados
Chão:
• Terra úmida e escura
• Poças de lodo
• Ossos espalhados
Elementos de cenário:
• Troncos caídos
• Rochas com musgo escuro
• Restos de criaturas
Sensação:
• Início da corrupção
• Ambiente decadente, porém ainda natural, /Users/seunome/Code/Game1/thewitcher.png

second phase: cursed land, a corrupted forest deepening the rot, using assets from the asset pack. /Users/seunome/Code/Game1/assets/cursed-land-tileset
1.2 Fase 2 — Terra Amaldiçoada (Floresta Profunda)
Contexto: A corrupção se aprofundou. A floresta está completamente tomada por energia
sombria, com o solo marcado por cicatrizes mágicas e vegetação retorcida.
Ambiente:
• Rochas com musgo corrompido e cristais escuros
• Árvores negras e retorcidas
• Chão marcado com runas e fissuras brilhantes
• Névoa densa e escura
Elementos de cenário:
• Cristais negros e roxos
• Tocos de árvore corrompidos
• Cogumelos venenosos com brilho espectral
• Estruturas de pedra antigas
Spawn:
• 2x mais inimigos que a fase 1
• Knights (Coxinha) desde a wave 1
• Colliders de borda em formato diamond
Mecânica:
• Inimigos sofrem clamp de posição para não sair da arena
Inimigos: skeleton, knight coxinha, galinha podre (rotativo por wave)

third phase: undead cemetery, a graveyard environment using the undead tileset. /Users/seunome/Code/Game1/first-scenario/Free-Undead-Tileset-Top-Down-Pixel-Art
1.3 Fase 3 — Cemitério Maldito (Coração da Corrupção)
Contexto: O cemitério onde a maldição se originou. Terra morta, lápides quebradas
e o ar carregado de energia necromântica. O cheiro de podridão é insuportável.
Ambiente:
• Lápides cobertas de musgo negro
• Terra estéril com rachaduras
• Cercas de ferro retorcidas
• Crânios e ossos pelo chão
• Iluminação azulada/esverdeada fantasmagórica
Elementos de cenário:
• Túmulos abertos
• Restos de esqueletos
• Cruzes de madeira podre
• Árvores mortas sem folhas
Spawn:
• Sistema rotativo de inimigos: knight coxinha → galinha podre → skeleton
• Spawn variado a cada onda
Inimigos: skeleton, knight coxinha, galinha podre (rotação por índice na wave)

hub: the hub area, a corrupted sanctuary between combat arenas. /Users/seunome/Code/Game1/assets/
Hub — Santuário Corrompido
Contexto: Entre as arenas de combate, Azrael encontra um fragmento de terra flutuante
— um santuário corrompido pelo mesmo mal que assola a floresta. Um misterioso Mercador
oferece consolo e conhecimento, e um portal pulsante conduz aos campos de batalha.
Ambiente:
• Ilha flutuante assimétrica com bordas quebradas
• Grama escura e musgosa (tons azulados)
• Vegetação morta nas bordas
• Névoa baixa rastejante e cinzas flutuando no ar
• Silhuetas de ruínas emolduram as bordas da tela
Elementos de cenário:
• Acampamento do Mercador (7 props: construções, lápides, relíquias)
• Clusters de ossos espalhados (2 grupos, 7 sprites)
• Vegetação nas bordas (6 sprites)
• Portal corrompido (edificação grande, partículas vermelhas, luz pulsante)
Iluminação:
• PointLight2D (3 luzes com textura radial compartilhada, 256×256 FILL_RADIAL)
• Jogador: luz azul fria (~115px radius, energy 1.4) — legibilidade constante
• Mercador: luz âmbar quente (~140px, energy 1.2) — zona segura frágil
• Portal: luz vermelha pulsante (~179px, 0.6+sin(t*2)*0.8) — objetivo principal
• 4 LightOccluder2D nas construções do acampamento (sombras reais)
CanvasModulate: Color(0.22, 0.24, 0.28) — toda visibilidade vem das luzes
Interação:
• Mercador: exibe fragmentos da alma (proximidade)
• Portal "O Caminho": inicia expedição ou nova jornada (reseta nível + área 1)
• Labels "Mercador" e "O Caminho" só aparecem quando o jogador está próximo
Layout: fluxo triangular assimétrico — Mercador(2,4) → Jogador(7,8) → Portal(16,3)
Caminho: trilha diagonal quebrada (9 segmentos) guiando do jogador ao portal
Sensação:
• Santuário frágil e corrompido
• Atmosfera opressiva com pontos de calor (luz do Mercador)
• O portal pulsa como batimento cardíaco — convida e ameaça
• O ambiente não é seguro nem limpo — é um refúgio entre horrores