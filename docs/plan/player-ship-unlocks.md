# Player Ship Unlocks

> **Objetivo:** Adicionar selecao persistente de nave na Title, com novas naves desbloqueadas conforme o melhor KM alcancado pelo usuario.

## Contexto

Hoje o jogo usa apenas `assets/images/player_ship.png` como sprite da nave, tanto no hero da Title quanto na entidade `Ship` dentro da Game. O `flow/background.md` ja define marcos espaciais por KM, e esses marcos serao a base dos requisitos de desbloqueio das novas naves. O melhor KM ja e persistido por `ArcadeOne` em `StorageService` com a chave `best_distance_km`, entao a selecao de nave deve usar esse valor para liberar ou bloquear opcoes. A escolha do usuario tambem deve ser persistida, seguindo o padrao atual de `TitleControlModeCubit`.

## Arquitetura / Escopo

| Arquivo | Acao | Responsabilidade |
|---------|------|-----------------|
| `assets/images/ships/` | criar | Guardar os sprites PNG transparentes das novas naves, mantendo o `player_ship.png` atual como nave padrao. |
| `lib/game/game_image_assets.dart` | alterar | Declarar os caminhos das naves e inclui-los em `gameImageAssets` para preload. |
| `lib/game/player_ship/player_ship_skin.dart` | criar | Modelo imutavel de nave com `id`, `assetPath`, `unlockKm` e dados de apresentacao. |
| `lib/game/player_ship/player_ship_catalog.dart` | criar | Catalogo ordenado de naves, usando os KMs do `flow/background.md` como requisitos de desbloqueio. |
| `lib/game/game.dart` | alterar | Exportar o catalogo/modelo de naves para Title e Game. |
| `lib/title/cubit/title_ship_selection_cubit.dart` | criar | Restaurar a nave persistida, validar desbloqueio pelo melhor KM e salvar selecoes validas. |
| `lib/title/cubit/cubit.dart` | alterar | Exportar o novo Cubit da feature Title. |
| `lib/title/view/title_page.dart` | alterar | Criar/prover `TitleShipSelectionCubit`, ler o melhor KM e adicionar o botao de escolha de nave na tela de titulo. |
| `lib/title/content/title_ship_selector_button.dart` | criar | Botao visivel da escolha de nave, com preview da nave selecionada e acao para abrir o seletor. |
| `lib/title/content/title_ship_selection_sheet.dart` | criar | Bottom sheet ou dialog com naves desbloqueadas/bloqueadas, requisito em KM e selecao. |
| `lib/title/content/title_hero.dart` | alterar | Receber a nave selecionada para usar o asset correto no hero. |
| `lib/title/content/title_main_content.dart` | alterar | Receber nave selecionada, melhor KM e callbacks de selecao para compor hero, botao e start. |
| `lib/title/content/title_start_button.dart` | alterar | Repassar a nave selecionada para `GamePage.route`. |
| `lib/game/view/game_page.dart` | alterar | Aceitar `PlayerShipSkin` na rota e repassar para `ArcadeOne`. |
| `lib/game/arcade_one.dart` | alterar | Carregar o asset da nave selecionada e criar `Ship(shipImage: ...)` com esse sprite. |
| `lib/l10n/arb/app_en.arb` | alterar | Adicionar textos do botao, seletor, status bloqueado/desbloqueado e nomes das naves. |
| `lib/l10n/arb/app_pt.arb` | alterar | Adicionar as traducoes em portugues dos novos textos. |
| `test/game/player_ship/player_ship_catalog_test.dart` | criar | Cobrir ordenacao, desbloqueio por KM e fallback para nave padrao. |
| `test/title/cubit/title_ship_selection_cubit_test.dart` | criar | Cobrir restauracao, persistencia e bloqueio de selecoes invalidas. |
| `test/title/view/title_page_test.dart` | alterar | Cobrir botao de escolha, bloqueio por melhor KM, selecao persistida e rota da Game com a nave escolhida. |
| `test/game/view/game_page_test.dart` | alterar | Cobrir rota da Game com nave selecionada. |

## Fases

### Fase 1 - Testes (contrato antes da implementacao)

> Escreva os testes que definem o comportamento esperado. Eles devem falhar inicialmente porque os tipos, Cubits e componentes ainda nao existem.

- [ ] Criar `test/game/player_ship/player_ship_catalog_test.dart` cobrindo que a nave padrao fica desbloqueada em `0 km`.
- [ ] Testar em `test/game/player_ship/player_ship_catalog_test.dart` que naves baseadas nos marcos de `flow/background.md` desbloqueiam em `250`, `600`, `1000`, `1500`, `2100`, `2800`, `3600`, `4500`, `5600`, `7000` e `8500 km`.
- [ ] Criar `test/title/cubit/title_ship_selection_cubit_test.dart` cobrindo estado inicial, restauracao de `title_player_ship`, valor invalido persistido e selecao bloqueada pelo melhor KM.
- [ ] Alterar `test/title/view/title_page_test.dart` para verificar que a Title renderiza o botao de escolha de nave e mostra a nave atual.
- [ ] Alterar `test/title/view/title_page_test.dart` para abrir o seletor, impedir toque em nave bloqueada e persistir uma nave desbloqueada via `StorageService.setString('title_player_ship', id)`.
- [ ] Alterar `test/title/view/title_page_test.dart` para iniciar a Game e confirmar que `GamePage.route` recebe a nave selecionada junto com o `GameControlMode`.
- [ ] Alterar `test/game/view/game_page_test.dart` para confirmar que `GamePage` aceita uma nave selecionada e a mantem no widget/rota.
- [ ] Verificacao: os testes compilam ate os pontos esperados e falham por simbolos ausentes ou asserts de comportamento ainda nao implementado.

### Fase 2 - Catalogo, assets e preload

- [ ] Criar `assets/images/ships/` com sprites PNG transparentes para as novas naves, mantendo a nave atual como default em `assets/images/player_ship.png` ou copiando-a para `assets/images/ships/player_ship_default.png` sem quebrar compatibilidade.
- [ ] Alterar `lib/game/game_image_assets.dart` para declarar os assets das naves e incluir todos em `gameImageAssets`.
- [ ] Criar `lib/game/player_ship/player_ship_skin.dart` com `id`, `assetPath` e `unlockKm`.
- [ ] Criar `lib/game/player_ship/player_ship_catalog.dart` com `playerShipSkins`, `defaultPlayerShipSkin`, `playerShipSkinById(String)`, `unlockedPlayerShipSkins(double bestDistanceKm)` e `isPlayerShipUnlocked(...)`.
- [ ] Usar os KMs dos marcos de `flow/background.md` como requisitos: default `0`, Mars `250`, Asteroid Belt `600`, Jupiter `1000`, Saturn `1500`, Ice Giants `2100`, Kuiper Belt `2800`, Orion Nebula `3600`, Pillars `4500`, Black Hole `5600`, Andromeda `7000`, Deep Quasar `8500`.
- [ ] Exportar o novo modulo em `lib/game/game.dart`.
- [ ] Verificacao: `flutter gen-l10n` ainda nao e necessario nesta fase; `flutter test test/game/player_ship/player_ship_catalog_test.dart` deve passar apos a implementacao do catalogo.

### Fase 3 - Persistencia da escolha de nave

- [ ] Criar `lib/title/cubit/title_ship_selection_cubit.dart` seguindo o padrao de `TitleControlModeCubit`.
- [ ] Usar a chave `title_player_ship` para salvar o `id` da nave selecionada.
- [ ] No `init(bestDistanceKm: ...)`, restaurar a nave salva apenas se ela existir e estiver desbloqueada pelo melhor KM; caso contrario, manter `defaultPlayerShipSkin`.
- [ ] Em `setShip(ship, bestDistanceKm: ...)`, ignorar naves bloqueadas, salvar somente selecoes desbloqueadas e emitir o novo estado quando a escolha mudar.
- [ ] Exportar `TitleShipSelectionCubit` em `lib/title/cubit/cubit.dart`.
- [ ] Verificacao: `flutter test test/title/cubit/title_ship_selection_cubit_test.dart` passa.

### Fase 4 - UI de escolha na Title

- [ ] Alterar `lib/title/view/title_page.dart` para criar `TitleShipSelectionCubit` junto com `TitleControlModeCubit`, ler `best_distance_km` do `StorageService` e inicializar a selecao de nave.
- [ ] Adicionar em `lib/title/view/title_page.dart` o ponto de entrada visual da escolha de nave, passando estado/callback para `TitleMainContent`.
- [ ] Criar `lib/title/content/title_ship_selector_button.dart` com botao usando icone de nave/foguete, preview pequeno do sprite selecionado e texto localizado.
- [ ] Criar `lib/title/content/title_ship_selection_sheet.dart` com lista/grid de naves, mostrando imagem, nome localizado, status selecionado, cadeado para bloqueadas e requisito de KM.
- [ ] Alterar `lib/title/content/title_main_content.dart` para renderizar o botao de escolha entre o hero e o seletor de controles, preservando o `SingleChildScrollView` da Title para telas baixas.
- [ ] Alterar `lib/title/content/title_hero.dart` para receber `selectedShip` e renderizar `Image.asset(selectedShip.assetPath)`.
- [ ] Adicionar chaves em `lib/l10n/arb/app_en.arb` e `lib/l10n/arb/app_pt.arb` para label do botao, titulo do seletor, status bloqueado/desbloqueado, requisito em KM e nomes das naves.
- [ ] Rodar `flutter gen-l10n` para atualizar `lib/l10n/gen/*`.
- [ ] Verificacao: `flutter test test/title/view/title_page_test.dart` passa, sem strings visiveis hardcoded nos widgets.

### Fase 5 - Uso da nave selecionada na Game

- [ ] Alterar `lib/title/content/title_start_button.dart` para receber `selectedShip` e chamar `GamePage.route(controlMode: selectedControlMode, playerShip: selectedShip)`.
- [ ] Alterar `lib/game/view/game_page.dart` para adicionar `PlayerShipSkin playerShip` em `GamePage`, `GameView` e `GamePage.route`, com default `defaultPlayerShipSkin`.
- [ ] Alterar `lib/game/arcade_one.dart` para receber `PlayerShipSkin playerShip` no construtor.
- [ ] Alterar `_loadGameImages` em `lib/game/arcade_one.dart` para carregar `playerShip.assetPath` em vez de sempre usar `playerShipImageAsset`.
- [ ] Manter fallback visual atual de `Ship` quando o asset nao estiver disponivel, evitando crash se um PNG faltar durante desenvolvimento.
- [ ] Verificacao: `flutter test test/game/view/game_page_test.dart test/game/arcade_one_test.dart` passa.

### Fase 6 - Validacao completa

- [ ] Rodar `flutter test --coverage --test-randomize-ordering-seed random`.
- [ ] Rodar `dart run bloc_tools:bloc lint .`.
- [ ] Rodar `flutter analyze`.
- [ ] Rodar a flavor development com `flutter run --flavor development --target lib/main_development.dart` para validar manualmente a Title, o seletor, bloqueios por KM e entrada na Game com a nave escolhida.
- [ ] Verificacao: app compila, testes passam e a selecao persiste ao fechar/reabrir ou retornar da Game para a Title.

### Fase 7 - Atualizar Flow

- [ ] Atualizar `flow/background.md` com uma observacao de que os KMs dos marcos tambem alimentam os requisitos de desbloqueio de naves.
- [ ] Atualizar `flow/title.md` incluindo o novo `TitleShipSelectionCubit`, o botao de escolha em `TitleView`, o seletor de naves e a persistencia em `title_player_ship`.
- [ ] Atualizar `flow/game.md` incluindo o parametro `playerShip` em `GamePage.route`, o repasse para `ArcadeOne` e o carregamento do asset escolhido.
- [ ] Criar ou atualizar `flow/player-ship-selection.md` com o fluxo completo UI -> Cubit -> StorageService -> GamePage -> ArcadeOne.
- [ ] Verificacao: os flows citam os novos arquivos e as regras de negocio de desbloqueio por melhor KM.

## Criterios de Sucesso

- [ ] A Title tem um botao de escolha de nave em `lib/title/view/title_page.dart` ou orquestrado diretamente por ela.
- [ ] O seletor mostra naves bloqueadas e desbloqueadas conforme `best_distance_km`.
- [ ] O usuario so consegue selecionar naves cujo `unlockKm <= best_distance_km`.
- [ ] A nave selecionada e salva em `StorageService` e restaurada ao abrir a Title novamente.
- [ ] Ao iniciar a Game, a nave escolhida aparece no gameplay e no hero da Title.
- [ ] O asset atual `[Image #1]` continua sendo a nave default.
- [ ] Build sem erros.
- [ ] Todos os testes unitarios e widget tests passando.

## Riscos e Mitigacoes

| Risco | Probabilidade | Mitigacao |
|-------|--------------|-----------|
| Os novos PNGs nao seguirem tamanho, orientacao ou transparencia compativeis com `Ship`. | Media | Padronizar assets transparentes no mesmo enquadramento visual do `player_ship.png` e validar em Title/Game antes de finalizar. |
| Uma nave persistida ficar invalida apos mudanca no catalogo. | Media | `TitleShipSelectionCubit.init` deve ignorar ids inexistentes ou bloqueados e voltar para `defaultPlayerShipSkin`. |
| A Title ficar alta demais em telas pequenas. | Media | Manter o `SingleChildScrollView`, usar botao compacto e sheet/modal para a lista completa. |
| Testes de widget dependerem de imagens reais e ficarem frageis. | Baixa | Testar textos, ids, callbacks e rota; deixar validacao visual dos PNGs para execucao manual. |
| `flutter gen-l10n` alterar arquivos gerados alem do necessario. | Baixa | Alterar apenas ARBs e regenerar l10n uma vez ao final da fase de UI. |

## Rollback

Reverter os novos arquivos de catalogo/Cubit/UI, remover os assets de `assets/images/ships/`, voltar `GamePage.route` e `ArcadeOne` para usar somente `playerShipImageAsset`, remover as chaves novas dos ARBs e regenerar l10n. A chave persistida `title_player_ship` pode permanecer sem efeito ou ser removida por uma migracao simples se necessario.
