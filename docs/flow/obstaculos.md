---
generated_at: 2026-09-12
source_commit: 698131b
source_state: clean
verified_at: 2026-09-12
status: current
related_plans:
  - docs/plan/add-loose-meteors-obstacles.md
  - docs/plan/implement-drift-mvp.md
---

# Flow: Obstáculos

> **Resumo:** Alterna sequências de paredes com passagem e meteoros soltos, aumentando a pressão com a distância até uma colisão encerrar a rodada.

## Visão Geral

Os obstáculos pertencem a `ArcadeOne`. Ao montar a rodada, o jogo carrega tiles de asteroides e o sprite do meteoro, cria os componentes base e gera uma primeira sequência de sete paredes `AsteroidPairComponent`.

Cada parede ocupa as laterais e deixa um gap cuja largura diminui com a dificuldade. Meteoros soltos usam posição, raio e drift horizontal aleatórios. Eles só entram depois de uma sequência mínima de paredes, permanecem menos frequentes e têm limite de repetições consecutivas.

No update, os dois tipos descem com o scroll, verificam colisão antes de serem removidos fora da tela e preservam a sequência antiga durante o handoff antecipado. Colisão com obstáculo ou borda chama o mesmo `endRun`; restart remove tudo e recomeça por paredes.

## Passo a Passo

1. **Preload** — `lib/game/game_image_assets.dart` e `lib/loading/cubit/preload/preload_cubit.dart`
   Tiles genérico/temáticos e o PNG de meteoro entram em `gameImageAssets` e são carregados antes do gameplay.
2. **Carga no jogo** — `lib/game/arcade_one.dart` → `_loadGameImages`
   Resolve o tile genérico, o mapa de tiles por marco e `loose_meteor.png` no cache de imagens.
3. **Primeira sequência** — `lib/game/arcade_one.dart` → `_buildRun` e `_spawnNextObstacleSequence`
   `_nextObstacleSequence` começa como `asteroidPairs`, então a rodada nasce com sete paredes.
4. **Criação de paredes** — `lib/game/arcade_one.dart` → `_spawnAsteroidPairSequence` e `_spawnObstacle`
   Posiciona paredes a cada 145 unidades, escolhe o centro do gap dentro da área útil e injeta o tile correspondente ao marco espacial atual.
5. **Geometria das paredes** — `lib/game/components/asteroid_pair_component.dart` → `AsteroidPairComponent`
   Calcula blocos esquerdo/direito em torno do gap e reduz sua largura de `150` até o mínimo `76` conforme a dificuldade.
6. **Escolha da próxima sequência** — `lib/game/arcade_one.dart` → `_chooseNextObstacleSequence`
   Usa contadores de sequências e o gerador aleatório para decidir entre novas paredes e meteoros soltos.
7. **Criação de meteoros** — `lib/game/arcade_one.dart` → `_spawnLooseMeteorSequence` e `_spawnLooseMeteor`
   Gera de 9 a 14 meteoros conforme a dificuldade, com espaçamento `95`, raio entre `10` e `22` e drift horizontal variável.
8. **Movimento e colisão** — `lib/game/arcade_one.dart` → `update`
   Move cada componente com `scrollSpeed`, testa colisão com `Ship` e encerra a rodada imediatamente quando encontra contato.
9. **Remoção e handoff** — `lib/game/arcade_one.dart` → `update` e `_advanceObstacleSequenceIfNeeded`
   Remove componentes que passaram do limite inferior e cria a sequência seguinte quando o item mais alto atinge `-32`, mantendo os anteriores na árvore.
10. **Fim ou reinício** — `lib/game/arcade_one.dart` → `endRun` e `restartRun`
    Colisão ativa game over; reinício remove paredes e meteoros, zera os contadores e volta à sequência inicial de paredes.

### Caminhos alternativos

- **Tile ausente:** `AsteroidPairComponent` desenha blocos e realces em canvas.
- **Sprite do meteoro ausente:** `LooseMeteorComponent` desenha uma rocha procedural com sombra e brilho.
- **Nave dentro do gap:** o teste círculo-retângulo não acusa colisão quando o raio da nave não alcança os blocos laterais.
- **Duas sequências de meteoros seguidas:** a próxima escolha é forçada para paredes.
- **Borda da tela:** `_checkBounds` encerra a rodada pelo mesmo caminho das colisões com obstáculos.

## Arquivos Envolvidos

| Camada | Arquivo | Responsabilidade |
|--------|---------|------------------|
| Orquestração | `lib/game/arcade_one.dart` | Escolhe, cria, move, alterna e remove sequências. |
| Componente | `lib/game/components/asteroid_pair_component.dart` | Modela paredes, gap, colisão e renderização. |
| Componente | `lib/game/components/loose_meteor_component.dart` | Modela meteoro, drift, colisão circular e renderização. |
| Entidade | `lib/game/entities/ship/ship.dart` | Fornece posição e raio de colisão da nave. |
| Catálogo visual | `lib/game/background/space_landmark_catalog.dart` | Determina o tema de tile pela distância. |
| Assets | `lib/game/game_image_assets.dart` | Lista imagens genéricas e temáticas. |
| Testes | `test/game/components/asteroid_pair_component_test.dart` | Cobre gap, movimento e colisão das paredes. |
| Testes | `test/game/components/loose_meteor_component_test.dart` | Cobre movimento, saída da tela e colisão dos meteoros. |
| Testes | `test/game/arcade_one_test.dart` | Cobre cadência, handoff, colisões e limpeza no restart. |

## Regras de Negócio Relevantes

- **Paredes predominantes** — `lib/game/arcade_one.dart`: meteoros só ficam elegíveis depois de três sequências consecutivas de paredes.
- **Chance de meteoros** — `lib/game/arcade_one.dart`: quando elegíveis, meteoros são escolhidos com probabilidade de 25%.
- **Limite consecutivo** — `lib/game/arcade_one.dart`: no máximo duas sequências de meteoros podem ocorrer sem uma sequência de paredes.
- **Dificuldade das paredes** — `lib/game/components/asteroid_pair_component.dart`: o gap encolhe em até 64 unidades, mas nunca abaixo de 76.
- **Dificuldade dos meteoros** — `lib/game/arcade_one.dart`: a sequência cresce de 9 até 14 itens e amplia a faixa de raio e drift horizontal.
- **Colisão terminal** — `lib/game/arcade_one.dart`: o primeiro contato interrompe o restante do update e executa `endRun` uma única vez.

## Dependências Externas

- Flame para componentes, vetores, ciclo de update e árvore da cena.
- Flutter Canvas/`dart:ui` para sprites e fallback procedural.

## Observações

- A sequência seguinte nasce antes da atual sair da tela; esse handoff intencional mantém os componentes existentes e pode deixar duas sequências simultâneas nas listas.
- O tile de uma parede é escolhido no momento do spawn. Mudanças posteriores de marco espacial não alteram obstáculos já criados.
