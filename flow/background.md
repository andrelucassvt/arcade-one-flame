# Flow: Background

> **Resumo:** Controla os marcos espaciais distantes do jogo, mantendo o starfield procedural como fundo e renderizando planetas/objetos transparentes que entram, descem e somem conforme a distancia em KM.

## Visão Geral

O fluxo de background comeca no preload. `PreloadCubit` carrega todos os caminhos em `gameImageAssets`, incluindo os sprites transparentes de `assets/images/backgrounds/`, para que o jogo consiga buscar as imagens no cache do Flame.

Quando `ArcadeOne.onLoad` chama `_buildRun`, o jogo carrega os sprites principais e os assets de marcos espaciais com `_loadGameImages`. Em seguida cria `SpaceBackgroundComponent`, passando o tamanho da area de jogo e o mapa de imagens carregadas. O componente fica antes de nave, HUD e obstaculos na arvore do Flame, com prioridade negativa, para renderizar sempre atras do gameplay.

Durante a partida, `ArcadeOne.update` incrementa `distanceKm`, recalcula `scrollSpeed` e chama `background.advance(scrollSpeed, dt, distanceKm)`. O componente avanca o `StarfieldComponent` interno e consulta `visibleLandmarksForDistance(distanceKm)` para descobrir quais sprites devem estar visiveis naquele trecho. Cada marco tem uma janela de KM, ancora de entrada, ancora de saida, escala, opacidade e fator de parallax; com isso a Terra, planetas e outros objetos aparecem no fundo, descem lentamente e somem sem substituir o campo de estrelas. Se alguma imagem nao estiver disponivel, o componente desenha um fallback procedural translucido.

No restart, `ArcadeOne.restartRun` zera a distancia e chama `background.reset()`, voltando o marco ativo para Terra/Lua sem recriar a tela.

## Passo a Passo

1. **Lista de assets** — `lib/game/game_image_assets.dart` -> `gameImageAssets`
   Define os sprites de jogo e os doze sprites transparentes de marcos espaciais usados pelo preload.
2. **Preload** — `lib/loading/cubit/preload/preload_cubit.dart` -> `PreloadCubit.loadSequentially`
   Chama `images.loadAll([...gameImageAssets])`, deixando os sprites de marcos no cache do Flame antes da tela de jogo.
3. **Modelo de marco** — `lib/game/background/space_landmark.dart` -> `SpaceLandmark`
   Representa cada marco com id, asset, KM inicial, janela visivel em KM, escala, ancora de entrada/saida, opacidade e fator de parallax.
4. **Catalogo por KM** — `lib/game/background/space_landmark_catalog.dart` -> `spaceLandmarks`
   Mantem a tabela ordenada dos marcos e expõe `landmarkForDistance(distanceKm)` e `visibleLandmarksForDistance(distanceKm)`.
5. **Load do jogo** — `lib/game/arcade_one.dart` -> `ArcadeOne._loadGameImages`
   Busca cada asset de `spaceLandmarkAssetPaths` no cache de imagens e guarda em `_spaceLandmarkImages`; se falhar, guarda `null` para ativar fallback visual.
6. **Criacao do componente** — `lib/game/arcade_one.dart` -> `ArcadeOne._buildRun`
   Cria `SpaceBackgroundComponent(gameSize: area, landmarkImages: _spaceLandmarkImages)` e adiciona antes de `Ship` e `DriftHudComponent`.
7. **Avanco por frame** — `lib/game/arcade_one.dart` -> `ArcadeOne.update`
   Incrementa `distanceKm`, calcula `scrollSpeed` e chama `background.advance(scrollSpeed, dt, distanceKm)`.
8. **Starfield e distancia** — `lib/game/components/space_background_component.dart` -> `advance`
   Avanca o `StarfieldComponent`, acumula distancia de parallax e guarda o `distanceKm` atual para o proximo render.
9. **Renderizacao** — `lib/game/components/space_background_component.dart` -> `render`
   Renderiza o starfield e depois desenha todos os marcos visiveis em `visibleLandmarksForDistance`, interpolando a posicao entre `startAnchor` e `endAnchor` e aplicando fade de entrada/saida por progresso.
10. **Restart** — `lib/game/arcade_one.dart` -> `restartRun`
    Zera `distanceKm` e chama `background.reset()`, retornando para `landmarkForDistance(0)`.

### Caminhos alternativos

- **Imagem ausente ou cache falha:** `ArcadeOne._loadGameImage` retorna `null`; `SpaceBackgroundComponent._renderFallbackLandmark` desenha um brilho procedural com cor baseada no id do marco.
- **Game over:** `ArcadeOne.update` retorna antes de atualizar distancia, background e obstaculos, congelando a progressao visual.
- **Resize do jogo:** `ArcadeOne.onGameResize` chama `background.resizeGame(size)` para atualizar a area usada no desenho do background.

## Arquivos Envolvidos

| Camada | Arquivo | Responsabilidade |
|--------|---------|------------------|
| Assets de jogo | `lib/game/game_image_assets.dart` | Declara os caminhos dos sprites transparentes de marcos espaciais e inclui todos em `gameImageAssets`. |
| Preload | `lib/loading/cubit/preload/preload_cubit.dart` | Carrega `gameImageAssets` no cache de imagens do Flame. |
| Jogo Flame | `lib/game/arcade_one.dart` | Carrega imagens, cria o background, avanca o componente por distancia e reseta no restart. |
| Background | `lib/game/background/space_landmark.dart` | Modelo imutavel do marco espacial com janela de visibilidade e movimento de entrada/saida. |
| Background | `lib/game/background/space_landmark_catalog.dart` | Catalogo ordenado, selecao de marco por KM e lista de marcos visiveis. |
| Componente | `lib/game/components/space_background_component.dart` | Renderiza starfield, sprites visiveis, movimento por KM, fade de entrada/saida e fallback procedural. |
| Componente | `lib/game/components/starfield_component.dart` | Mantem estrelas procedurais com parallax continuo. |
| Assets | `assets/images/backgrounds/*.png` | Sprites PNG transparentes dos marcos espaciais. |
| Configuracao | `pubspec.yaml` | Registra `assets/images/backgrounds/` no bundle Flutter. |
| Testes | `test/game/background/space_landmark_catalog_test.dart` | Cobre ordenacao, duplicidade e bordas de selecao por KM. |
| Testes | `test/game/components/space_background_component_test.dart` | Cobre continuidade do starfield, troca de marco, fade e reset. |
| Testes | `test/game/arcade_one_test.dart` | Cobre criacao do background, avanco por distancia e reset integrado. |

## Regras de Negócio Relevantes

- **Selecao por distancia** — `lib/game/background/space_landmark_catalog.dart`: o marco ativo e o ultimo item de `spaceLandmarks` cujo `startKm` e menor ou igual a `distanceKm`.
- **Visibilidade por janela** — `lib/game/background/space_landmark.dart`: cada marco fica visivel entre `startKm` e `startKm + visibleKm`.
- **Faixas iniciais** — `lib/game/background/space_landmark_catalog.dart`: 0 Terra/Lua, 250 Marte, 600 Cintura de asteroides, 1000 Jupiter, 1500 Saturno, 2100 Urano/Netuno, 2800 Cintura de Kuiper, 3600 Nebulosa de Orion, 4500 Pilares da Criacao, 5600 Buraco negro, 7000 Andromeda, 8500 Quasar.
- **Entrada e saida visual** — `lib/game/components/space_background_component.dart`: cada sprite interpola de `startAnchor` para `endAnchor` e usa fade curto no inicio/fim da sua janela.
- **Background nao interfere no gameplay** — `lib/game/components/space_background_component.dart`: o componente tem prioridade `-100` e nao participa de colisao, spawn ou HUD.
- **Fallback visual** — `lib/game/components/space_background_component.dart`: ausencia de PNG nao quebra a partida; o componente renderiza uma forma procedural translucida.
- **Restart volta ao inicio** — `lib/game/arcade_one.dart`: `restartRun` chama `background.reset()` junto com `distanceKm = 0`.

## Dependências Externas

- `flame` para `PositionComponent`, `Vector2` e cache/renderizacao de imagens.
- `flutter`/`dart:ui` para `Canvas`, `Paint`, `Offset` e `ui.Image`.

## Observações

- Os PNGs sao sprites transparentes, nao fundos completos, e somam cerca de `1.5M`.
- `StarfieldComponent` continua procedural e independente dos sprites de marcos, preservando a continuidade do loop.
