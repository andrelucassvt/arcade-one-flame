# Flow: Player Ship Selection

> **Resumo:** Permite escolher uma skin de nave na Title, persiste a escolha quando ela esta desbloqueada pelo melhor KM e usa essa nave na tela de jogo.

## Visão Geral

O fluxo comeca quando `TitleView` e aberta depois do loading ou ao voltar da Game. A tela cria `TitleShipSelectionCubit`, le o melhor KM salvo em `best_distance_km` e usa esse valor para validar a nave persistida em `title_player_ship`. Se a nave salva nao existir mais ou ainda estiver bloqueada para o melhor KM atual, a Title permanece com `defaultPlayerShipSkin`.

O usuario abre o seletor pelo `TitleShipSelectorButton`. O bottom sheet renderizado por `TitleShipSelectionSheet` percorre `playerShipSkins`, mostra o sprite, nome localizado, status selecionada/liberada/bloqueada e requisito de desbloqueio em KM. O toque em uma nave bloqueada nao chama o Cubit; o toque em uma nave liberada chama `TitleShipSelectionCubit.setShip`, que salva o `id` em `StorageService` e emite a nova skin.

Quando o usuario inicia a partida, `TitleStartButton` navega com `GamePage.route(controlMode: ..., playerShip: ...)`. `GameView` repassa a `PlayerShipSkin` para `ArcadeOne`, que carrega `playerShip.assetPath` junto dos demais assets do jogo e cria `Ship(shipImage: _playerShipImage)`. Se o PNG nao puder ser carregado, `Ship` mantem o fallback procedural existente.

## Passo a Passo

1. **Entrada da Title** — `lib/title/view/title_page.dart` -> `TitleView.initState`
   Cria `TitleShipSelectionCubit` com `StorageService` e chama `_initShipSelection()`.
2. **Melhor distancia** — `lib/title/view/title_page.dart` -> `_initShipSelection`
   Le `best_distance_km` usando `bestDistanceStorageKey`, atualiza `_bestDistanceKm` e chama `TitleShipSelectionCubit.init(bestDistanceKm: ...)`.
3. **Restauracao** — `lib/title/cubit/title_ship_selection_cubit.dart` -> `init`
   Le `title_player_ship`; se o id existe no catalogo e `isPlayerShipUnlocked(ship, bestDistanceKm)` retorna `true`, emite a skin salva. Caso contrario, mantem `defaultPlayerShipSkin`.
4. **Hero e botao** — `lib/title/content/title_main_content.dart` -> `TitleMainContent.build`
   Repassa a skin selecionada para `TitleHero`, `TitleShipSelectorButton` e `TitleStartButton`.
5. **Preview na Title** — `lib/title/content/title_hero.dart` -> `TitleHero.build`
   Renderiza `Image.asset(selectedShip.assetPath)` como nave principal do hero.
6. **Abrir seletor** — `lib/title/content/title_ship_selector_button.dart` -> `TitleShipSelectorButton`
   Mostra o botao localizado com preview pequeno e chama `TitleView._showShipSelectionSheet` ao tocar.
7. **Listar naves** — `lib/title/content/title_ship_selection_sheet.dart` -> `TitleShipSelectionSheet`
   Renderiza `playerShipSkins` em grid, calcula desbloqueio por `isPlayerShipUnlocked(ship, bestDistanceKm)` e mostra requisito com `titleShipUnlockRequirement`.
8. **Persistir selecao** — `lib/title/cubit/title_ship_selection_cubit.dart` -> `setShip`
   Ignora skins bloqueadas ou iguais ao estado atual. Para skins liberadas, salva `title_player_ship = ship.id` e emite a nova nave.
9. **Iniciar jogo** — `lib/title/content/title_start_button.dart` -> `onPressed`
   Chama `Navigator.pushReplacement(GamePage.route(controlMode: controlMode, playerShip: playerShip))`.
10. **Rota da Game** — `lib/game/view/game_page.dart` -> `GamePage.route`
    Cria `GamePage` com o modo de controle e a skin selecionados; `GamePage.build` repassa ambos para `GameView`.
11. **Instancia Flame** — `lib/game/view/game_page.dart` -> `GameView.build`
    Cria `ArcadeOne(playerShip: widget.playerShip, ...)` usando os caches do `PreloadCubit`.
12. **Load do sprite** — `lib/game/arcade_one.dart` -> `_loadGameImages`
    Carrega `playerShip.assetPath` no cache de imagens e guarda em `_playerShipImage`.
13. **Criacao da entidade** — `lib/game/arcade_one.dart` -> `_buildRun`
    Cria `Ship(shipImage: _playerShipImage)`, usando o sprite escolhido ou o fallback procedural se `_playerShipImage == null`.

### Caminhos alternativos

- **Sem nave persistida:** `TitleShipSelectionCubit.init` retorna sem emitir, mantendo `defaultPlayerShipSkin`.
- **Id persistido invalido:** `playerShipSkinById` cai para default, mas `init` exige que o id retornado seja igual ao id salvo; a skin invalida e ignorada.
- **Nave persistida bloqueada:** `init` valida `ship.unlockKm <= bestDistanceKm`; se falhar, a Title permanece com a nave default.
- **Toque em nave bloqueada:** `TitleShipSelectionSheet` deixa `onTap` nulo, entao `setShip` nao e chamado.
- **PNG ausente ou cache falha:** `ArcadeOne._loadGameImage` retorna `null`; `Ship.render` desenha o fallback procedural.

## Arquivos Envolvidos

| Camada | Arquivo | Responsabilidade |
|--------|---------|------------------|
| Apresentacao — View | `lib/title/view/title_page.dart` | Cria o Cubit de nave, le melhor KM, abre o bottom sheet e passa estado/callbacks para o conteudo. |
| Apresentacao — Content | `lib/title/content/title_main_content.dart` | Orquestra hero, botao de nave, seletor de controle e start. |
| Apresentacao — Content | `lib/title/content/title_hero.dart` | Mostra a nave selecionada no hero da Title. |
| Apresentacao — Content | `lib/title/content/title_ship_selector_button.dart` | Entrada visual do seletor de nave. |
| Apresentacao — Content | `lib/title/content/title_ship_selection_sheet.dart` | Grid de naves desbloqueadas/bloqueadas e chamada de selecao. |
| Apresentacao — Content | `lib/title/content/title_start_button.dart` | Navega para a Game com `controlMode` e `playerShip`. |
| Estado / Cubit | `lib/title/cubit/title_ship_selection_cubit.dart` | Restaura, valida e persiste a nave escolhida. |
| Jogo / Catalogo | `lib/game/player_ship/player_ship_skin.dart` | Modelo imutavel de skin. |
| Jogo / Catalogo | `lib/game/player_ship/player_ship_catalog.dart` | Lista ordenada de skins, requisitos por KM, fallback por id e helper de nome localizado. |
| Jogo / Assets | `lib/game/game_image_assets.dart` | Declara os caminhos das skins e os inclui em `gameImageAssets` para preload. |
| Apresentacao — Game | `lib/game/view/game_page.dart` | Recebe `PlayerShipSkin` na rota e repassa para `ArcadeOne`. |
| Jogo Flame | `lib/game/arcade_one.dart` | Carrega o sprite da nave selecionada e cria `Ship` com a imagem carregada. |
| Entidade Flame | `lib/game/entities/ship/ship.dart` | Renderiza o sprite da nave ou fallback procedural. |
| Servico | `lib/common/services/storage_service.dart` | Interface usada para ler `best_distance_km` e salvar `title_player_ship`. |
| L10n | `lib/l10n/arb/app_en.arb` | Strings em ingles do seletor e nomes das naves. |
| L10n | `lib/l10n/arb/app_pt.arb` | Strings em portugues do seletor e nomes das naves. |
| Assets | `assets/images/player_ship.png` | Sprite default da nave. |
| Assets | `assets/images/ships/*.png` | Sprites das skins desbloqueaveis. |
| Testes | `test/game/player_ship/player_ship_catalog_test.dart` | Cobre requisitos por KM, desbloqueio e fallback. |
| Testes | `test/title/cubit/title_ship_selection_cubit_test.dart` | Cobre restauracao, persistencia e bloqueio de selecoes invalidas. |
| Testes | `test/title/view/title_page_test.dart` | Cobre UI do seletor, persistencia e rota para Game com nave. |
| Testes | `test/game/view/game_page_test.dart` | Cobre repasse da nave para `GameView`. |
| Testes | `test/game/arcade_one_test.dart` | Cobre carregamento do asset da nave selecionada. |

## Regras de Negócio Relevantes

- **Default sempre liberada** — `lib/game/player_ship/player_ship_catalog.dart`: `defaultPlayerShipSkin` usa `assets/images/player_ship.png` e `unlockKm = 0`.
- **Desbloqueio por melhor KM** — `lib/game/player_ship/player_ship_catalog.dart`: uma skin fica liberada quando `ship.unlockKm <= bestDistanceKm`.
- **Requisitos seguem marcos espaciais** — `lib/game/player_ship/player_ship_catalog.dart`: as skins usam `250`, `600`, `1000`, `1500`, `2100`, `2800`, `3600`, `4500`, `5600`, `7000` e `8500 km`.
- **Storage da escolha** — `lib/title/cubit/title_ship_selection_cubit.dart`: a chave `title_player_ship` guarda somente o `id` de skins desbloqueadas.
- **Fallback para valor invalido** — `lib/title/cubit/title_ship_selection_cubit.dart`: ids inexistentes ou bloqueados nao emitem estado novo e preservam a nave default.
- **Sem estado global novo para gameplay** — `lib/title/content/title_start_button.dart`: a nave escolhida e enviada pela rota para `GamePage`.
- **Fallback visual de desenvolvimento** — `lib/game/arcade_one.dart` e `lib/game/entities/ship/ship.dart`: falha no load do PNG nao quebra a partida; a entidade desenha a nave procedural.

## Dependências Externas

- Flutter Material para `showModalBottomSheet`, `OutlinedButton`, grid e navegacao por `Navigator`.
- `flutter_bloc` para expor e observar `TitleShipSelectionCubit`.
- Flame `Images` para cache e load do sprite selecionado.

## Observações

- O melhor KM continua sendo gravado pela Game em `best_distance_km`; a Title apenas le esse valor para calcular desbloqueios.
- Os nomes das naves ficam nos ARBs e sao acessados por `localizedPlayerShipName`, evitando strings visiveis hardcoded nos widgets.
- O catalogo fica em `lib/game/player_ship/` porque tanto Title quanto Game dependem dele.
