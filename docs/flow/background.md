---
generated_at: 2026-09-12
source_commit: 698131b
source_state: clean
verified_at: 2026-09-12
status: current
related_plans:
  - docs/plan/space-background-by-km.md
---

# Flow: Background

> **Resumo:** Faz o cenário evoluir por distância, mantendo um starfield contínuo e exibindo marcos espaciais com fade e parallax que também determinam a aparência dos asteroides.

## Visão Geral

O fluxo começa no preload, que inclui todos os backgrounds declarados em `gameImageAssets`. Quando `ArcadeOne` monta uma rodada, busca essas imagens no cache e cria `SpaceBackgroundComponent` com prioridade negativa para renderizá-lo atrás dos demais componentes.

Em cada frame, a distância acumulada e a velocidade visual chegam a `SpaceBackgroundComponent.advance`. O starfield procedural avança continuamente, enquanto o catálogo decide o marco ativo e quais imagens ainda estão dentro de sua janela de visibilidade.

Cada marco interpola entre âncoras de entrada e saída, aplica fade no começo e no fim e soma um deslocamento senoidal de parallax. O mesmo `landmarkForDistance` seleciona o tile usado por novas paredes de asteroides; reiniciar a rodada volta cenário e distância ao primeiro marco.

## Marcos por KM

| Marco | ID | Início | Visível até | Janela |
|-------|----|--------|-------------|--------|
| Terra/Lua | `earth_moon` | `-80 km` | `420 km` | `500 km` |
| Marte | `mars` | `250 km` | `720 km` | `470 km` |
| Cintura de asteroides | `asteroid_belt` | `600 km` | `1120 km` | `520 km` |
| Júpiter | `jupiter` | `1000 km` | `1620 km` | `620 km` |
| Saturno | `saturn` | `1500 km` | `2150 km` | `650 km` |
| Gigantes de gelo | `ice_giants` | `2100 km` | `2660 km` | `560 km` |
| Cintura de Kuiper | `kuiper_belt` | `2800 km` | `3400 km` | `600 km` |
| Nebulosa de Órion | `orion_nebula` | `3600 km` | `4320 km` | `720 km` |
| Pilares da Criação | `pillars_creation` | `4500 km` | `5220 km` | `720 km` |
| Buraco negro | `black_hole` | `5600 km` | `6360 km` | `760 km` |
| Andrômeda | `andromeda` | `7000 km` | `7860 km` | `860 km` |
| Quasar profundo | `deep_quasar` | `8500 km` | `9420 km` | `920 km` |

## Passo a Passo

1. **Registro de assets** — `lib/game/game_image_assets.dart` → `gameImageAssets`
   Reúne os backgrounds e tiles temáticos que o fluxo precisa carregar.
2. **Preload** — `lib/loading/cubit/preload/preload_cubit.dart` → `PreloadCubit.loadSequentially`
   Carrega `gameImageAssets` no cache `Images` antes de abrir a tela de título.
3. **Carga da rodada** — `lib/game/arcade_one.dart` → `_loadGameImages`
   Resolve cada caminho de `spaceLandmarkAssetPaths` no cache e guarda o resultado, inclusive `null` quando uma imagem falha.
4. **Montagem do fundo** — `lib/game/arcade_one.dart` → `_buildRun`
   Cria `SpaceBackgroundComponent` com a área jogável e o mapa de imagens; o componente cria internamente um `StarfieldComponent`.
5. **Progressão** — `lib/game/arcade_one.dart` → `update`
   Incrementa `distanceKm`, recalcula `scrollSpeed` e chama `background.advance(scrollSpeed, dt, distanceKm)`.
6. **Seleção de marcos** — `lib/game/background/space_landmark_catalog.dart` → `landmarkForDistance` e `visibleLandmarksForDistance`
   O último marco cujo `startKm` já foi alcançado vira o ativo; todos os marcos cuja janela inclui a distância são renderizados.
7. **Renderização** — `lib/game/components/space_background_component.dart` → `render`
   Desenha primeiro o starfield e depois cada marco visível, interpolando posição, opacidade e parallax.
8. **Tema dos obstáculos** — `lib/game/arcade_one.dart` → `_asteroidTileImageForDistance`
   Ao criar uma parede, escolhe o tile associado ao marco ativo, com fallback para o tile genérico.
9. **Reinício** — `lib/game/arcade_one.dart` → `restartRun`
   Zera a distância e chama `background.reset()`, restaurando Terra/Lua sem recriar o componente.

### Caminhos alternativos

- **Imagem ausente:** `SpaceBackgroundComponent` desenha um círculo translúcido com cor específica do marco em vez do PNG.
- **Janelas sobrepostas:** `visibleLandmarksForDistance` pode devolver mais de um marco; todos são renderizados na ordem do catálogo.
- **Redimensionamento:** `ArcadeOne.onGameResize` repassa o novo tamanho ao fundo e o starfield é semeado novamente para a nova área.

## Arquivos Envolvidos

| Camada | Arquivo | Responsabilidade |
|--------|---------|------------------|
| Catálogo | `lib/game/background/space_landmark.dart` | Modela janela, âncoras, escala, opacidade e parallax de um marco. |
| Catálogo | `lib/game/background/space_landmark_catalog.dart` | Define a progressão e seleciona marcos por distância. |
| Componente | `lib/game/components/space_background_component.dart` | Renderiza starfield, imagens, fade, deslocamento e fallback. |
| Componente | `lib/game/components/starfield_component.dart` | Mantém estrelas procedurais em duas velocidades de parallax. |
| Orquestração | `lib/game/arcade_one.dart` | Carrega imagens, avança o fundo, redimensiona e reinicia a progressão. |
| Assets | `lib/game/game_image_assets.dart` | Relaciona marcos, tiles e arquivos de imagem. |
| Testes | `test/game/background/space_landmark_catalog_test.dart` | Cobre ordenação, unicidade, limites e correspondência de tiles. |
| Testes | `test/game/components/space_background_component_test.dart` | Cobre continuidade, troca, remoção visual, velocidade e reset. |
| Testes | `test/game/components/starfield_component_test.dart` | Cobre continuidade do loop do starfield. |
| Testes | `test/game/arcade_one_test.dart` | Cobre integração e avanço do marco conforme a distância. |

## Regras de Negócio Relevantes

- **Progressão dirigida por distância** — `lib/game/background/space_landmark_catalog.dart`: os doze marcos entram em limiares fixos de `-80` a `8500` km.
- **Visibilidade inclusiva** — `lib/game/background/space_landmark.dart`: um marco permanece visível quando a distância é igual a `startKm + visibleKm`.
- **Fade nas extremidades** — `lib/game/components/space_background_component.dart`: os primeiros e últimos 14% da janela modulam a opacidade.
- **Fundo atrás do gameplay** — `lib/game/components/space_background_component.dart`: prioridade `-100` mantém o componente abaixo de nave, obstáculos e HUD.
- **Starfield determinístico** — `lib/game/components/starfield_component.dart`: a semente padrão `7` gera 95 estrelas e facilita testes reprodutíveis.

## Dependências Externas

- Flame para ciclo de vida, componentes, tamanho da cena e cache de imagens.
- Flutter Canvas/`dart:ui` para composição e renderização dos marcos.

## Observações

- O catálogo de naves reutiliza os `startKm` de Marte em diante como requisitos de desbloqueio, mas os dois catálogos são constantes separadas e precisam continuar sincronizados manualmente.
- Paredes de asteroides recebem o tile temático apenas no spawn; uma parede já existente não troca de aparência ao cruzar um novo limiar de distância.
