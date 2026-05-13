# OATHBREAKER

![Godot 4.6](https://img.shields.io/badge/Godot-4.6-478CBF?logo=godotengine&logoColor=white)
![GDScript](https://img.shields.io/badge/GDScript-darkgreen)
![iCEV](https://img.shields.io/badge/iCEV-Engenharia%20de%20Software-8B0000)

> *"The oath you broke made you who you are."*

Action RPG 2D isométrico dark fantasy com progressão roguelite — lute através de 3 áreas corrompidas, acumule fragmentos da alma e enfrente bosses em ondas crescentes de dificuldade.

---

## Sobre o Jogo

Você é **Azrael**, um guerreiro amaldiçoado que quebrou um juramento divino. Condenado a vagar por terras corrompidas, sua única redenção é avançar — área por área, onda por onda — colhendo fragmentos da alma dos inimigos para fortalecer suas habilidades corrompidas.

Três áreas aguardam: a **Floresta Podre**, a **Terra Maldita** e o **Cemitério dos Mortos-Vivos**. Cada uma com atmosfera, inimigos e boss únicos. Sobreviva às ondas ou seja consumido.

---

## Funcionalidades

- **3 áreas jogáveis** com tileset, iluminação e atmosfera únicos
- **Sistema de ondas** — 3 waves normais + boss wave por área (12 ondas no total)
- **4 inimigos distintos** — Esqueleto, Cavalheiro, Mosca Podre e Galinha Boss (easter egg fase 1)
- **Progressão roguelite** — XP → nível → 4 tipos de upgrade com fragmentos da alma
- **2 habilidades ativas** — Golpe Sagrado (Q) e Lança Divina (E) com cooldown
- **Dash com i-frames**, knockback, hit-stop e screen shake
- **Hub entre corridas** com mercador, portal e atmosfera AAA
- **Sistema de juice completo** — números de dano flutuantes, partículas de sangue, frenzy mode
- **Modo Frenético** — inimigos ficam 50% mais rápidos e fortes se a onda demorar muito

---

## Controles

| Ação | Tecla |
|------|-------|
| Mover | W / A / S / D |
| Dash | Espaço |
| Ataque básico | Mouse Esquerdo |
| Golpe Sagrado | Q |
| Lança Divina | E |
| Pausar | ESC |

---

## Como Jogar

### Executável (recomendado)
1. Baixe o executável na seção **Releases** do repositório
2. **Windows:** execute `oathbreaker.exe`
3. **macOS:** abra `oathbreaker.app` — na primeira vez: clique direito → Abrir
4. Nenhuma instalação necessária

### Via Editor (desenvolvimento)
Abrir o projeto no **Godot 4.6** (Compatibility renderer) e pressionar **F5**.

---

## Equipe

| Nome | Papel |
|------|-------|
| Guilherme Ancheschi | Desenvolvedor |
| Jesley Wendell | Desenvolvedor |
| Lara Bezerra | Diretora Criativa |
| Mateus Pessoa | Designer Gráfico |
| Víctor Portelada | QA |

---

## Stack Técnica

- **Engine:** Godot 4.6 — GDScript, GL Compatibility renderer
- **Arquitetura:** 25+ scripts autorais, 4 autoloads (JuiceManager, AudioManager, ProgressionManager, TransitionScreen)
- **Geração de mapa:** FastNoiseLite procedural — 3 fases com tileset e scatter únicos
- **Iluminação:** PointLight2D + CanvasModulate por área, LightOccluder2D no hub
- **Áudio:** AudioManager com polifonia e fallback gracioso para arquivos ausentes

---

*Projeto acadêmico — iCEV, Engenharia de Software*
*Disciplina: Introdução ao Desenvolvimento de Jogos*
