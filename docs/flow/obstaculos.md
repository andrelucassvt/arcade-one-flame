---
generated_at: 2026-09-12
source_commit: a3f02f7
source_state: dirty
verified_at: 2026-09-12
status: current
related_plans:
  - docs/plan/add-loose-meteors-obstacles.md
  - docs/plan/implement-drift-mvp.md
---

# Flow: Obstáculos

> **Resumo:** Alterna sequências de paredes (com gap fixo ou móvel) e meteoros soltos que descem com scroll, registram near miss e podem ser absorvidos por escudo até uma colisão encerrar a rodada.

## Visão Geral

Os obstáculos pertencem a `ArcadeOne`. Ao montar a rodada, o jogo carrega tiles de asteroides e o sprite do meteoro, cria os componentes base e gera uma primeira sequência de sete paredes `AsteroidPairComponent`.

Cada parede ocupa as laterais e deixa um gap cuja largura diminui com a dificuldade. Parte das paredes nasce com gap móvel: o centro oscila senoidalmente dentro da área útil, com amplitude e velocidade que crescem com `difficulty` e `deepDifficulty`. Gaps estáticos podem receber um power-up de escudo ou câmera lenta.

Meteoros soltos nascem em formação de onda (seno com amplitude, frequência e fase aleatórias) e usam raio, drift horizontal, rotação e bounce nas laterais. Eles só entram depois de uma sequência mínima de paredes, permanecem menos frequentes e têm limite de repetições consecutivas; a quantidade e o drift crescem na curva profunda.

No update, os componentes descem com o scroll, testam colisão (círculo-retângulo nas paredes, círculo-círculo nos meteoros) e registram near miss uma única vez por obstáculo. Escudo ativo absorve o impacto e remove o obstáculo; sem escudo, a rodada termina. Restart remove paredes, meteoros e power-ups, zera os contadores e recomeça por paredes.

## Passo a Passo

1. **Preload** — `lib/game/game_image_assets.dart` e `lib/loading/cubit/preload/preload_cubit.dart`
   Tiles genérico/temáticos e o PNG de meteoro entram em `gameImageAssets` e são carregados antes do gameplay.
2. **Carga no jogo** — `lib/game/arcade_one.dart` → `_loadGameImages`
   Resolve o tile genérico, o mapa de tiles por marco e `loose_meteor.png` no cache de imagens.
3. **Primeira sequência** — `lib/game/arcade_one.dart` → `_buildRun` e `_spawnNextObstacleSequence`
   `_nextObstacleSequence` começa como `asteroidPairs`, então a rodada nasce com sete paredes.
4. **Criação de paredes** — `lib/game/arcade_one.dart` → `_spawnAsteroidPairSequence` e `_spawnObstacle`
   Posiciona paredes a cada 145 unidades, escolhe o centro do gap dentro da área útil e decide se o gap será móvel (`_movingGapChance`, amplitude e velocidade crescentes) antes de injetar o tile do marco atual.
5. **Power-ups do gap** — `lib/game/arcade_one.dart` → `_maybeSpawnPowerUp`
   Com chance `powerUpSpawnChance`, escolhe uma parede de gap estático e cria um `PowerUpComponent` (escudo ou câmera lenta) no centro do gap.
6. **Geometria e oscilação das paredes** — `lib/game/components/asteroid_pair_component.dart` → `AsteroidPairComponent.update` e `gapCenterX`
   O gap encolhe de `150` até o mínimo `76` com a dificuldade; com drift configurado, `sin` desloca o centro mantendo o gap dentro da área (`asteroidGapEdgeMargin`).
7. **Criação de meteoros** — `lib/game/arcade_one.dart` → `_spawnLooseMeteorSequence` e `_spawnLooseMeteor`
   Gera de 9 até 14+ meteoros conforme `difficulty` e `deepDifficulty`, posicionando cada um numa onda senoidal (`formationCenter`, `formationAmplitude`, `formationWave`, `formationPhase`) com espaçamento `95`, raio entre `10` e `22`, drift horizontal e rotação aleatórios.
8. **Movimento e colisão** — `lib/game/arcade_one.dart` → `update`, `_updateObstacles` e `_updateLooseMeteors`
   Move cada componente com `scrollSpeed`, testa `collidesWith` e registra near miss; com escudo chama `_tryAbsorbHit` e remove o obstáculo, sem escudo chama `endRun`.
9. **Power-ups** — `lib/game/arcade_one.dart` → `_updatePowerUps` e `_collectPowerUp`
   Move os pickups, coleta por sobreposição com a nave, aplica escudo/câmera lenta e gera burst de coleta.
10. **Bounce e remoção** — `lib/game/components/loose_meteor_component.dart` → `moveByScroll`; `lib/game/arcade_one.dart` → `update`
    Meteoros refletem o drift nas laterais e giram com `rotationSpeed`; componentes que passam do limite inferior são removidos por índice.
11. **Handoff de sequência** — `lib/game/arcade_one.dart` → `_advanceObstacleSequenceIfNeeded`
    Cria a sequência seguinte quando o item mais alto atinge `-32`, mantendo os anteriores na árvore.
12. **Fim ou reinício** — `lib/game/arcade_one.dart` → `endRun` e `restartRun`
    Colisão ativa game over com hit-stop; reinício remove paredes, meteoros e power-ups, zera contadores e volta à sequência inicial de paredes.

### Caminhos alternativos

- **Tile ausente:** `AsteroidPairComponent` desenha blocos e realces em canvas.
- **Sprite do meteoro ausente:** `LooseMeteorComponent` desenha uma rocha procedural com sombra e brilho.
- **Nave dentro do gap:** o clearance círculo-retângulo fica positivo e não há colisão.
- **Gap móvel fora do centro:** o valor é clampado para o gap não encostar nas bordas da tela.
- **Near miss:** clearance entre 0 e `nearMissThreshold` marca o obstáculo e incrementa o combo uma única vez.
- **Escudo ativo:** o primeiro contato consome o escudo, remove o obstáculo e concede invulnerabilidade curta.
- **Invulnerabilidade:** durante o grace period ou após absorver escudo, colisões e near miss são ignorados.
- **Duas sequências de meteoros seguidas:** a próxima escolha é forçada para paredes.
- **Borda lateral:** meteoros refletem o `horizontalDrift` em vez de sair da tela.

## Arquivos Envolvidos

| Camada | Arquivo | Responsabilidade |
|--------|---------|------------------|
| Orquestração | `lib/game/arcade_one.dart` | Escolhe, cria, move, alterna, absorve e remove obstáculos e power-ups. |
| Componente | `lib/game/components/asteroid_pair_component.dart` | Modela paredes, gap fixo/móvel, clearance e near miss. |
| Componente | `lib/game/components/loose_meteor_component.dart` | Modela meteoro, drift com bounce, rotação, colisão e near miss. |
| Componente | `lib/game/components/power_up_component.dart` | Modela pickups de escudo e câmera lenta. |
| Componente | `lib/game/components/particle_burst_component.dart` | Renderiza explosões de impacto e coleta. |
| Entidade | `lib/game/entities/ship/ship.dart` | Fornece posição, raio de colisão e estado de escudo/trilha. |
| Catálogo visual | `lib/game/background/space_landmark_catalog.dart` | Determina o tema de tile pela distância. |
| Assets | `lib/game/game_image_assets.dart` | Lista imagens genéricas e temáticas. |
| Testes | `test/game/components/asteroid_pair_component_test.dart` | Cobre gap, gap móvel, movimento, colisão e near miss das paredes. |
| Testes | `test/game/components/loose_meteor_component_test.dart` | Cobre movimento, bounce, rotação, saída da tela, colisão e near miss. |
| Testes | `test/game/components/power_up_component_test.dart` | Cobre coleta, movimento e saída da tela dos pickups. |
| Testes | `test/game/arcade_one_test.dart` | Cobre cadência, handoff, colisões, escudo, slow-mo, combo e limpeza no restart. |

## Regras de Negócio Relevantes

- **Paredes predominantes** — `lib/game/arcade_one.dart`: meteoros só ficam elegíveis depois de três sequências consecutivas de paredes.
- **Chance de meteoros** — `lib/game/arcade_one.dart`: quando elegíveis, meteoros são escolhidos com probabilidade de 25%.
- **Limite consecutivo** — `lib/game/arcade_one.dart`: no máximo duas sequências de meteoros podem ocorrer sem uma sequência de paredes.
- **Dificuldade das paredes** — `lib/game/components/asteroid_pair_component.dart`: o gap encolhe em até 64 unidades, mas nunca abaixo de 76.
- **Gaps móveis** — `lib/game/arcade_one.dart`: chance cresce de 0,12 até no máximo 0,7 somando `difficulty` e `deepDifficulty`; amplitude e velocidade também crescem.
- **Power-ups** — `lib/game/arcade_one.dart`: chance de 16% por sequência de paredes, apenas em gaps estáticos, alternando escudo e câmera lenta.
- **Dificuldade dos meteoros** — `lib/game/arcade_one.dart`: a sequência cresce de 9 até 14 itens (mais 3 na curva profunda) e amplia raio, drift e rotação.
- **Near miss one-shot** — `lib/game/components/`: `nearMissRewarded` garante um único registro por obstáculo, com threshold de 18 unidades.
- **Colisão terminal** — `lib/game/arcade_one.dart`: o primeiro contato sem escudo interrompe o update e executa `endRun` uma única vez.
- **Restart limpa tudo** — `lib/game/arcade_one.dart`: paredes, meteoros, power-ups e bursts são removidos e os contadores de sequência zerados.

## Dependências Externas

- Flame para componentes, vetores, ciclo de update e árvore da cena.
- Flutter Canvas/`dart:ui` para sprites e fallback procedural.

## Observações

- A sequência seguinte nasce antes da atual sair da tela; esse handoff intencional mantém os componentes existentes e pode deixar duas sequências simultâneas nas listas.
- O tile de uma parede é escolhido no momento do spawn. Mudanças posteriores de marco espacial não alteram obstáculos já criados.
- O power-up guarda o `gapCenterX` do momento do spawn; se a parede hospedeira fosse móvel ele ficaria desalinhado, por isso `_maybeSpawnPowerUp` só considera hosts estáticos.
- `AsteroidPairComponent` e `LooseMeteorComponent` expõem `nearMissRewarded` público para o orquestrador controlar a premiação sem recriar o componente.
- Meteoros podem cruzar a tela horizontalmente quicando mais de uma vez; o bounce usa o raio atual do sprite.
