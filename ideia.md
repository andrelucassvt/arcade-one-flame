# DRIFT — Game Design Document

# Visão Geral

DRIFT é um jogo mobile de navegação espacial com física de inércia real. A inspiração vem da fórmula do Flappy Bird: simples de entender, difícil de dominar, rentável pela longevidade. O diferencial é a mecânica de momentum — a nave não para instantaneamente, e a habilidade do jogador está em controlar o deslizamento.

---

# Mecânica Principal

**Input:** Segurar a tela → propulsor ativa em direção ao toque. Soltar → nave desliza pela inércia.

**A variável central do jogo:** Não é desviar dos obstáculos, é saber *quando soltar* o propulsor.

- Scroll vertical infinito automático
- Nave se orienta em direção ao toque com rotação suave
- Inércia real: velocidade acumulada não some instantaneamente
- Toque nas bordas da tela = morte

---

# Obstáculos

## Par de Asteroides

Dois blocos com um gap entre eles. O gap diminui conforme a pontuação aumenta. Obstáculo mais comum (60% dos spawns).

## Satélite em Órbita

Um satélite girando em torno de um ponto fixo. O jogador precisa sincronizar o movimento com a órbita para passar. 18% dos spawns.

## Cluster de Detritos

Grupo de fragmentos espalhados. Exige navegação precisa entre os pedaços. 22% dos spawns.

---

# Progressão de Dificuldade

| Distância | Zona | Descrição |
| --- | --- | --- |
| 0 km | Asteroid Belt | Gaps largos, velocidade baixa |
| 800 km | Nebula Alpha | Paleta rosa, obstáculos mais rápidos |
| 1800 km | Debris Field | Paleta laranja, clusters frequentes |
| 3000 km+ | Dark Sector | Quase preto, máxima dificuldade |

Velocidade aumenta gradualmente com a fórmula: `speed = 2 + score × 0.0008`

---

# Visual

- **Estilo:** Pixel art com paleta restrita por zona
- **Fundo:** Paralax de estrelas em 2 camadas
- **Nave:** Pixel art com cockpit, asas, propulsor animado
- **Efeitos:** Trail da nave, partículas de propulsor, explosão na morte
- **Pós-processamento:** Scanline leve (efeito CRT)
- **Fonte:** Press Start 2P (pixel font)

---

# Som (a definir)

- Trilha **synthwave lo-fi** por zona
- SFX: propulsor (hum suave), colisão (crunch), morte (explosão)
- Quanto mais profundo na zona, mais pesada a trilha

---

# Monetização

- **Skins de nave:** nave retrô, OVNI, cápsula soviética, etc. (moeda in-game ou compra)
- **Continue após morte:** rewarded ad
- **Missões diárias:** recompensa de moeda in-game
- **Sem pay-to-win:** toda mecânica é cosmética

---

# Stack Técnica

- **Engine:** Flutter (Flame) ou React Native com Canvas
- **Prototipagem:** HTML5 Canvas / React JSX ✅ (protótipo funcional criado)
- **Plataformas-alvo:** iOS e Android
- **Monetização SDK:** AdMob (rewarded ads) + RevenueCat (IAP)

---

# Status

- [x]  Conceito definido
- [x]  Protótipo jogável criado (React/Canvas)
- [x]  Mecânica de inércia validada
- [ ]  Arte final da nave
- [ ]  Trilha sonora
- [ ]  Build Flutter
- [ ]  Testes de balanceamento de dificuldade
- [ ]  Submissão App Store / Google Play

---

# Referências de Inspiração

- **Flappy Bird** — simplicidade + dificuldade = vício
- **Alto's Odyssey** — progressão visual por bioma
- **Geometry Dash** — ritmo e precisão
- **Monument Valley** — pixel art minimalista no espaço