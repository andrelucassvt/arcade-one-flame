# Flow: Obstaculos

> **Resumo:** Documenta como o jogo cria, alterna, move, renderiza e remove os dois obstaculos atuais: paredes de asteroides com gap e meteoros soltos.

## Visao Geral

O fluxo de obstaculos vive dentro de `ArcadeOne`, a classe `FlameGame` principal. Durante o load da partida, o jogo carrega os sprites de asteroide, meteoro e nave, adiciona os componentes base (`StarfieldComponent`, `Ship` e `DriftHudComponent`) e cria a primeira sequencia de obstaculos.

Hoje existem dois tipos de obstaculo. O primeiro e `AsteroidPairComponent`, que desenha duas paredes laterais de asteroides e deixa um gap central para a nave passar. O sprite dessas paredes muda de cor conforme o marco espacial ativo em `flow/background.md`, usando uma variação de tile por planeta/objeto. O segundo e `LooseMeteorComponent`, que representa meteoros individuais espalhados pela tela, com raio proprio e drift horizontal opcional.

A partida sempre comeca com uma sequencia de paredes de asteroides. `ArcadeOne` mantem contadores de sequencias consecutivas para deixar `AsteroidPairComponent` mais comum: meteoros soltos so podem comecar depois de pelo menos tres sequencias seguidas de paredes, entram com 25% de chance quando liberados e nunca passam de duas sequencias consecutivas. A troca e antecipada quando a peca mais alta da sequencia atual chega perto do topo, permitindo que a proxima sequencia nasca acima dela sem apagar os obstaculos que ainda estao visiveis.

Em cada frame, `ArcadeOne.update` avanca distancia e velocidade, move todos os obstaculos para baixo, verifica colisao com a nave e remove componentes que ja sairam pela parte inferior da tela. Se houver colisao com parede, meteoro ou borda da tela, `endRun` marca game over, atualiza a melhor distancia e toca o efeito sonoro.

## Passo a Passo

1. **Load do jogo** — `lib/game/arcade_one.dart` -> `ArcadeOne.onLoad`
   Chama `_buildRun`, que prepara a partida inicial.

2. **Carga de imagens** — `lib/game/arcade_one.dart` -> `_loadGameImages`
   Carrega `asteroid_tile.png`, todas as variações em `assets/images/asteroids/`, `loose_meteor.png` e `player_ship.png` usando os caminhos definidos em `lib/game/game_image_assets.dart`.

3. **Montagem dos componentes base** — `lib/game/arcade_one.dart` -> `_buildRun`
   Cria `StarfieldComponent`, `Ship` e `DriftHudComponent`, adiciona os tres ao jogo e chama `_spawnNextObstacleSequence`.

4. **Selecao da sequencia inicial** — `lib/game/arcade_one.dart` -> `_spawnNextObstacleSequence`
   Usa `_nextObstacleSequence`, que inicia como `ObstacleSequence.asteroidPairs`, para criar a primeira leva de paredes.

5. **Spawn das paredes de asteroides** — `lib/game/arcade_one.dart` -> `_spawnAsteroidPairSequence`
   Define `_nextObstacleY` a partir de `initialObstacleY` ou de `afterY - obstacleSpacing`, e chama `_spawnObstacle` `asteroidPairSequenceLength` vezes.

6. **Criacao de cada parede** — `lib/game/arcade_one.dart` -> `_spawnObstacle`
   Calcula uma margem lateral, sorteia `gapCenter`, escolhe o tile por `landmarkForDistance(distanceKm)`, cria `AsteroidPairComponent`, adiciona na lista `obstacles`, adiciona o componente ao Flame e desloca `_nextObstacleY` para a proxima parede.

7. **Componente de parede** — `lib/game/components/asteroid_pair_component.dart` -> `AsteroidPairComponent`
   Calcula `gapSize` pela dificuldade, define `leftRect` e `rightRect`, renderiza o sprite de asteroide quando disponivel e usa fallback procedural se o sprite nao carregar.

8. **Escolha da proxima sequencia** — `lib/game/arcade_one.dart` -> `_chooseNextObstacleSequence`
   `_recordSpawnedObstacleSequence` atualiza os contadores de sequencias consecutivas. `_chooseNextObstacleSequence` so libera `ObstacleSequence.looseMeteors` depois de `asteroidPairSequencesBeforeLooseMeteors` sequencias de paredes, usa `looseMeteorSequenceChance` para manter paredes mais frequentes e forca paredes quando `maxConsecutiveLooseMeteorSequences` ja foi atingido.

9. **Update por frame** — `lib/game/arcade_one.dart` -> `ArcadeOne.update`
   Se nao houver game over, atualiza `distanceKm`, recalcula `scrollSpeed`, avanca o starfield e percorre as listas `obstacles` e `looseMeteors`.

10. **Movimento e colisao das paredes** — `lib/game/arcade_one.dart` -> `ArcadeOne.update`; `lib/game/components/asteroid_pair_component.dart` -> `moveByScroll` e `collidesWith`
    Cada `AsteroidPairComponent` desce com `scrollSpeed * dt`. A colisao testa o circulo da nave contra os retangulos esquerdo e direito; se colidir, `ArcadeOne.endRun` encerra a partida.

11. **Remocao das paredes fora da tela** — `lib/game/arcade_one.dart` -> `ArcadeOne.update`; `lib/game/components/asteroid_pair_component.dart` -> `isOffscreen`
    Quando uma parede passa de `gameSize.y + height`, ela sai da lista `obstacles` e e removida da arvore de componentes.

12. **Handoff entre sequencias** — `lib/game/arcade_one.dart` -> `_advanceObstacleSequenceIfNeeded`
    Se so ha paredes na tela e a parede mais alta ja chegou em `obstacleSequenceHandoffY` ou abaixo, o jogo cria a proxima sequencia usando `_topMostAsteroidPairY` como ancora.

13. **Spawn dos meteoros soltos** — `lib/game/arcade_one.dart` -> `_spawnLooseMeteorSequence`
    Define `_nextLooseMeteorY`, calcula o tamanho da sequencia como `looseMeteorBaseSequenceLength + difficulty * looseMeteorDifficultyBonus` e chama `_spawnLooseMeteor` para cada meteoro.

14. **Criacao de cada meteoro** — `lib/game/arcade_one.dart` -> `_spawnLooseMeteor`
    Sorteia posicao horizontal, raio e `horizontalDrift`, cria `LooseMeteorComponent`, adiciona na lista `looseMeteors`, adiciona o componente ao Flame e desloca `_nextLooseMeteorY` para o proximo meteoro.

15. **Componente de meteoro solto** — `lib/game/components/loose_meteor_component.dart` -> `LooseMeteorComponent`
    Guarda `gameSize`, `radius`, `horizontalDrift` e sprite opcional. O raio e limitado entre `looseMeteorMinRadius` e `looseMeteorMaxRadius`.

16. **Movimento e colisao dos meteoros** — `lib/game/arcade_one.dart` -> `ArcadeOne.update`; `lib/game/components/loose_meteor_component.dart` -> `moveByScroll` e `collidesWith`
    Cada meteoro aplica drift horizontal e scroll vertical. A colisao compara a distancia ao quadrado entre nave e meteoro contra a soma dos raios.

17. **Remocao dos meteoros fora da tela** — `lib/game/arcade_one.dart` -> `ArcadeOne.update`; `lib/game/components/loose_meteor_component.dart` -> `isOffscreen`
    Quando um meteoro passa de `gameSize.y + radius`, ele sai da lista `looseMeteors` e e removido da arvore de componentes.

18. **Restart da rodada** — `lib/game/arcade_one.dart` -> `restartRun`
    Reseta distancia, velocidade, proxima sequencia e contadores de sequencias consecutivas, reposiciona a nave, remove obstaculos antigos e cria novamente a sequencia inicial de paredes.

### Caminhos alternativos

- **Sprite indisponivel:** `AsteroidPairComponent.render` e `LooseMeteorComponent.render` usam desenho procedural quando a imagem nao foi carregada.
- **Game over ativo:** `ArcadeOne.update` retorna cedo quando `isGameOver` e verdadeiro, entao obstaculos nao se movem, nao colidem e novas sequencias nao sao criadas.
- **Duas sequencias visiveis:** `_advanceObstacleSequenceIfNeeded` nao cria uma terceira sequencia se `obstacles` e `looseMeteors` estiverem ambas preenchidas.

## Arquivos Envolvidos

| Camada | Arquivo | Responsabilidade |
|--------|---------|------------------|
| Jogo Flame | `lib/game/arcade_one.dart` | Orquestra load, spawn, escolha de sequencia, update, colisao, remocao e restart dos obstaculos. |
| Componente | `lib/game/components/asteroid_pair_component.dart` | Implementa paredes laterais de asteroides, gap, renderizacao, movimento vertical e colisao retangular contra a nave. |
| Componente | `lib/game/components/loose_meteor_component.dart` | Implementa meteoros soltos, raio, drift horizontal, renderizacao, movimento e colisao circular contra a nave. |
| Barrel export | `lib/game/components/components.dart` | Exporta os componentes de jogo, incluindo os dois tipos de obstaculo. |
| Barrel export | `lib/game/game.dart` | Exporta `arcade_one.dart`, componentes, cubits, entidades e views para consumidores da feature game. |
| Assets | `lib/game/game_image_assets.dart` | Define os caminhos de `asteroid_tile.png`, das variações por marco, `loose_meteor.png` e `player_ship.png`. |
| Assets | `assets/images/asteroid_tile.png`, `assets/images/asteroids/*.png`, `assets/images/loose_meteor.png` | Sprites usados pela renderizacao dos dois obstaculos; as paredes usam uma variação por marco espacial. |
| Testes | `test/game/arcade_one_test.dart` | Cobre load inicial, prioridade de paredes, atraso e limite de sequencias de meteoros, handoff antecipado, colisao com meteoro e restart. |
| Testes | `test/game/components/asteroid_pair_component_test.dart` | Cobre reducao de gap por dificuldade, movimento e colisao das paredes. |
| Testes | `test/game/components/loose_meteor_component_test.dart` | Cobre movimento com drift, offscreen e colisao circular dos meteoros. |

## Regras de Negocio Relevantes

- **Primeira sequencia sempre e parede** — `lib/game/arcade_one.dart`: `_nextObstacleSequence` inicia como `ObstacleSequence.asteroidPairs`.
- **Asteroides sao mais comuns** — `lib/game/arcade_one.dart`: `_chooseNextObstacleSequence` retorna paredes por padrao e so permite meteoros com `looseMeteorSequenceChance`, hoje `0.25`, quando eles estao liberados.
- **Meteoros exigem sequencia previa de paredes** — `lib/game/arcade_one.dart`: `asteroidPairSequencesBeforeLooseMeteors`, hoje `3`, impede meteoros soltos antes de uma sequencia razoavel de paredes.
- **Meteoros consecutivos tem limite** — `lib/game/arcade_one.dart`: `maxConsecutiveLooseMeteorSequences`, hoje `2`, forca a proxima sequencia a voltar para paredes apos duas levas seguidas de meteoros.
- **Handoff antecipado evita vazio grande** — `lib/game/arcade_one.dart`: `_advanceObstacleSequenceIfNeeded` cria a proxima sequencia quando a peca mais alta chega em `obstacleSequenceHandoffY`.
- **Obstaculos antigos continuam visiveis** — `lib/game/arcade_one.dart`: o handoff adiciona a proxima sequencia sem apagar a sequencia atual; a remocao so acontece quando cada componente fica offscreen.
- **Dificuldade fecha o gap das paredes** — `lib/game/components/asteroid_pair_component.dart`: `gapSize` começa em `asteroidBaseGap` e reduz com `difficulty`, sem passar de `asteroidMinGap`.
- **Cor das paredes acompanha o marco espacial** — `lib/game/arcade_one.dart`: `_spawnObstacle` usa `_asteroidTileImageForDistance(distanceKm)` para escolher a imagem da parede conforme o marco ativo; Terra/Lua usa a arte original, os proximos marcos usam paletas novas, e se a variação nao carregar o jogo usa `asteroid_tile.png`.
- **Dificuldade aumenta a sequencia de meteoros** — `lib/game/arcade_one.dart`: `_spawnLooseMeteorSequence` soma ate `looseMeteorDifficultyBonus` meteoros ao tamanho base conforme `difficulty`.
- **Dificuldade aumenta variedade dos meteoros** — `lib/game/arcade_one.dart`: `_spawnLooseMeteor` amplia a faixa de raio e o drift horizontal conforme `difficulty`.
- **Colisao encerra a rodada** — `lib/game/arcade_one.dart`: colisao com `AsteroidPairComponent` ou `LooseMeteorComponent` chama `endRun`.
- **Restart limpa os dois tipos** — `lib/game/arcade_one.dart`: `restartRun` chama `_removeAsteroidPairs` e `_removeLooseMeteors` antes de criar nova sequencia inicial.

## Dependencias Externas

- `flame` — fornece `FlameGame`, `PositionComponent`, `Vector2`, anchors e ciclo de vida de componentes.
- `flutter/material.dart` e `dart:ui` — fornecem `Canvas`, `Paint`, `Path`, `Rect` e `ui.Image` para renderizacao.
- `audioplayers` — `ArcadeOne.endRun` toca o efeito sonoro quando a colisao encerra a rodada.

## Observacoes

- O nome publico `obstacles` em `ArcadeOne` representa apenas paredes de asteroides; meteoros ficam em `looseMeteors`.
- A colisao das paredes usa retangulos (`leftRect` e `rightRect`) mesmo quando a renderizacao visual usa sprite com formas irregulares.
- O melhor score continua em memoria na instancia de `ArcadeOne`; o fluxo de obstaculos nao persiste progresso.
