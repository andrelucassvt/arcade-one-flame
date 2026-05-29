# Flow: Title

> **Resumo:** Mostra a home tematica do jogo, permite trocar idioma, mutar o audio, escolher modo de controle e nave, e envia o usuario para a partida quando ele toca em Launch/Decolar.

## Visão Geral

O fluxo de Title comeca quando a tela de loading conclui o preload e navega para `TitlePage.route()`. Ele tambem pode ser reaberto pela tela de game over quando o usuario escolhe voltar para a tela inicial. A tela renderiza uma home fullscreen com fundo espacial, nave, meteoros, seletor de controles e botao principal de partida.

Os textos sao obtidos via `context.l10n`, usando as chaves geradas a partir dos ARBs. O seletor de idioma no topo aciona `AppLocaleCubit.setLocale`, que atualiza o `Locale` do `MaterialApp`; antes da selecao manual, o app usa o locale resolvido pelo sistema. A top bar tambem exibe o botao de volume ligado ao `AudioCubit` global, permitindo alternar entre audio ligado e mutado antes de iniciar a partida.

O modo de controle da gameplay e gerenciado por `TitleControlModeCubit`, que usa `GameControlMode.touch` como padrao quando nao ha preferencia salva. Ao abrir a tela, o cubit restaura a chave `title_control_mode` via `StorageService`; quando o usuario alterna entre toque/clique e joystick virtual, a escolha e salva imediatamente.

A selecao de nave e gerenciada por `TitleShipSelectionCubit`. A Title le o melhor KM salvo em `best_distance_km`, restaura a chave `title_player_ship` somente quando a skin ainda existe e esta desbloqueada, e mostra um botao compacto com preview da nave atual. O bottom sheet lista skins liberadas e bloqueadas conforme `lib/game/player_ship/player_ship_catalog.dart`; selecoes bloqueadas sao ignoradas. Ao tocar no botao principal, `TitleStartButton` faz `Navigator.pushReplacement` para `GamePage.route(controlMode: ..., playerShip: ...)`, removendo a tela de titulo da pilha e repassando a escolha atual para a gameplay.

## Passo a Passo

1. **Origem** — `lib/loading/view/loading_page.dart` → `onPreloadComplete`
   Apos o preload, chama `navigator.pushReplacement(TitlePage.route())`.
   **Origem alternativa:** `lib/game/view/game_page.dart` → `GameOverPopup.onReturnToTitle`
   A partir do game over, chama `Navigator.pushReplacement(TitleView.route())`.
2. **Rota** — `lib/title/view/title_page.dart` → `TitlePage.route`
   Cria uma `MaterialPageRoute<void>` para `TitlePage`.
3. **Tela** — `lib/title/view/title_page.dart` → `TitlePage.build`
   Renderiza `Scaffold` fullscreen com `SafeArea` e `TitleView`.
4. **Cubits da Title** — `lib/title/view/title_page.dart` → `TitleView.initState`
   Cria `TitleControlModeCubit` e `TitleShipSelectionCubit` com o `StorageService` disponivel acima da tela. O modo de controle chama `init()` imediatamente; a selecao de nave chama `_initShipSelection()` para ler `best_distance_km` antes de validar `title_player_ship`.
5. **Home** — `lib/title/view/title_page.dart` → `TitleView.build`
   Le `AppLocaleCubit` via `context.select`, expoe os Cubits da Title com `MultiBlocProvider`, reage ao modo atual e a nave selecionada com `BlocBuilder`, e monta fundo espacial (`TitleBackdrop`), top bar (`TitleTopBar`) e conteudo principal (`TitleMainContent`). O conteudo fica dentro de `SingleChildScrollView` para evitar overflow em telas baixas.
6. **Layout** — `lib/title/content/title_main_content.dart` → `TitleMainContent.build`
   Usa `MediaQuery.sizeOf` para passar `isWide` ao `TitleHero` (breakpoint 760px) e renderiza `Column` com `TitleHero`, botao de selecao de nave, seletor de controle e `TitleStartButton`.
7. **Idioma** — `lib/title/content/title_top_bar.dart` → `TitleTopBar`
   Mostra `PopupMenuButton<Locale>` com opcoes EN/PT usando `TitleLanguageMenuItem` e chama `AppLocaleCubit.setLocale` ao selecionar uma opcao.
8. **Mute** — `lib/title/content/title_top_bar.dart` → `BlocBuilder<AudioCubit, AudioState>`
   Mostra `Icons.volume_up` ou `Icons.volume_off` conforme `AudioState.volume` e chama `AudioCubit.toggleVolume` ao tocar no botao.
9. **Modo de controle** — `lib/title/content/title_control_mode_selector.dart` → `TitleControlModeSelector`
   Exibe um `SegmentedButton<GameControlMode>` com opcoes localizadas para toque/clique e joystick. Ao mudar a selecao, chama `TitleControlModeCubit.setControlMode`, que salva `mode.name` em storage e emite o novo modo para atualizar a UI.
10. **Entrada do seletor de nave** — `lib/title/content/title_ship_selector_button.dart` → `TitleShipSelectorButton`
   Exibe um `OutlinedButton` localizado com icone, preview do sprite e nome localizado da nave atual. Ao tocar, chama `TitleView._showShipSelectionSheet`.
11. **Sheet de nave** — `lib/title/content/title_ship_selection_sheet.dart` → `TitleShipSelectionSheet`
   Lista `playerShipSkins`, mostra imagem, nome localizado, status selecionada/liberada/bloqueada e requisito em KM. Tocar em nave liberada chama `TitleShipSelectionCubit.setShip`; tocar em nave bloqueada nao aciona persistencia.
12. **Acao do usuario** — `lib/title/content/title_start_button.dart` → `TitleStartButton`
   Exibe um `ElevatedButton.icon` com `l10n.titleButtonStart` e recebe o `GameControlMode` e a `PlayerShipSkin` selecionados.
13. **Navegacao** — `lib/title/content/title_start_button.dart` → `onPressed`
   Ao tocar no botao, faz `Navigator.of(context).pushReplacement(GamePage.route(controlMode: controlMode, playerShip: playerShip))`.
14. **Destino** — `lib/game/view/game_page.dart` → `GamePage.route`
   Cria a rota da tela de jogo com o modo de controle e a nave selecionados.

## Arquivos Envolvidos

| Camada | Arquivo | Responsabilidade |
|--------|---------|------------------|
| Apresentacao — View | `lib/title/view/title_page.dart` | Define `TitlePage` (routing shell com `SafeArea`) e `TitleView` (orquestra estado e estrutura principal). |
| Apresentacao — Content | `lib/title/content/title_backdrop.dart` | Fundo espacial com imagem, gradientes e glow radial. |
| Apresentacao — Content | `lib/title/content/title_top_bar.dart` | Top bar com seletor de idioma e botao de mute ligado ao `AudioCubit`. |
| Apresentacao — Content | `lib/title/content/title_hero.dart` | Nave, meteoros, headline e subtitulo do hero. |
| Apresentacao — Content | `lib/title/content/title_main_content.dart` | Conteudo principal que orquestra hero, seletor de nave, seletor de controle e botao. |
| Apresentacao — Content | `lib/title/content/title_ship_selector_button.dart` | Botao compacto de escolha de nave com preview e nome localizado da skin atual. |
| Apresentacao — Content | `lib/title/content/title_ship_selection_sheet.dart` | Bottom sheet com lista de naves, status de bloqueio/desbloqueio e requisitos em KM. |
| Apresentacao — Content | `lib/title/content/title_control_mode_selector.dart` | Seletor segmentado entre gameplay por toque/clique e joystick virtual. |
| Apresentacao — Content | `lib/title/content/title_start_button.dart` | Botao Launch/Decolar e navegacao para `GamePage`, repassando modo de controle e nave selecionada. |
| Apresentacao — Content | `lib/title/content/title_language_menu_item.dart` | Item do menu de idioma com icone de selecao. |
| Jogo / Configuracao | `lib/game/game_control_mode.dart` | Enum publico com os modos `touch` e `joystick` usados pela Title e pela Game. |
| Estado / Cubit | `lib/title/cubit/title_control_mode_cubit.dart` | Restaura e persiste o modo de controle escolhido pelo usuario em `StorageService`. |
| Estado / Cubit | `lib/title/cubit/title_ship_selection_cubit.dart` | Restaura, valida por melhor KM e persiste a nave escolhida em `StorageService`. |
| Estado / Cubit | `lib/app/cubit/app_locale_cubit.dart` | Mantem o locale selecionado pelo usuario; persiste em storage e restaura no proximo lancamento. |
| Estado / Cubit | `lib/game/cubit/audio/audio_cubit.dart` | Mantem o volume global, aplica volume nos players e persiste a escolha. |
| Estado | `lib/game/cubit/audio/audio_state.dart` | Guarda o volume atual usado para escolher icone e tooltip do botao de mute. |
| Servico | `lib/common/services/storage_service.dart` | Interface de storage usada por `TitleControlModeCubit`, `AppLocaleCubit` e `AudioCubit` para ler e salvar preferencias. |
| Jogo / Catalogo | `lib/game/player_ship/player_ship_skin.dart` | Modelo imutavel de uma skin de nave. |
| Jogo / Catalogo | `lib/game/player_ship/player_ship_catalog.dart` | Catalogo ordenado de skins, requisitos por KM, fallback por id e helper de nome localizado. |
| Navegacao | `lib/loading/view/loading_page.dart` | Entra no fluxo de Title apos completar preload. |
| Navegacao | `lib/game/view/game_page.dart` | Rota de destino quando o usuario inicia o jogo. |
| L10n | `lib/l10n/arb/app_en.arb` | Define strings em ingles da home. |
| L10n | `lib/l10n/arb/app_pt.arb` | Define strings em portugues da home. |
| Barrel | `lib/title/title.dart` | Exporta a view e os cubits publicos da feature Title; arquivos em `content/` sao internos. |
| Testes | `test/title/cubit/title_control_mode_cubit_test.dart` | Cobre estado padrao, restauracao, persistencia e valor invalido do modo de controle. |
| Testes | `test/title/cubit/title_ship_selection_cubit_test.dart` | Cobre estado padrao, restauracao, valor invalido, bloqueio por melhor KM e persistencia da nave. |
| Testes | `test/title/view/title_page_test.dart` | Cobre renderizacao, troca de idioma, mute, navegacao, selecao de nave, persistencia e restauracao das preferencias da tela de titulo. |

## Regras de Negócio Relevantes

- **Launch substitui a rota atual** — `lib/title/content/title_start_button.dart`: o jogo e aberto com `pushReplacement`, entao a tela de titulo nao permanece abaixo de `GamePage`.
- **Modo de controle padrao** — `lib/title/cubit/title_control_mode_cubit.dart`: a tela inicia com `GameControlMode.touch` quando nao existe valor salvo.
- **Modo de controle persistido** — `lib/title/cubit/title_control_mode_cubit.dart`: `init()` restaura a chave `title_control_mode`, ignora valores invalidos e `setControlMode` salva `mode.name` antes de emitir a nova escolha.
- **Modo escolhido via rota** — `lib/title/content/title_start_button.dart`: o modo selecionado e enviado para `GamePage.route(controlMode: ..., playerShip: ...)`, sem criar estado global novo.
- **Nave padrao** — `lib/game/player_ship/player_ship_catalog.dart`: `defaultPlayerShipSkin` usa `assets/images/player_ship.png` e fica liberada em `0 km`.
- **Desbloqueio por melhor KM** — `lib/title/cubit/title_ship_selection_cubit.dart`: `init` e `setShip` aceitam uma nave somente quando `ship.unlockKm <= bestDistanceKm`.
- **Nave persistida** — `lib/title/cubit/title_ship_selection_cubit.dart`: a chave `title_player_ship` salva o `id` da nave; ids inexistentes ou bloqueados caem para a nave default sem sobrescrever o storage.
- **Nave escolhida via rota** — `lib/title/content/title_start_button.dart`: a skin selecionada e enviada para `GamePage.route(controlMode: ..., playerShip: ...)`, sem criar estado global novo.
- **Idioma persistido em storage** — `lib/app/cubit/app_locale_cubit.dart`: ao inicializar, `init()` le a chave `app_locale` do `StorageService` e emite o locale salvo; `setLocale` salva o `languageCode` antes de emitir; sem selecao manual o app usa a resolucao padrao do sistema.
- **Mute compartilhado com gameplay** — `lib/title/content/title_top_bar.dart` e `lib/game/cubit/audio/audio_cubit.dart`: o botao da Title altera o mesmo `AudioCubit` global usado pela Game, entao a escolha vale ao entrar na partida.
- **Textos localizados** — todos os textos visiveis dependem de `context.l10n`; nenhuma string visivel e hardcoded.
- **Content nao exportado** — os arquivos em `lib/title/content/` sao auxiliares internos da feature e nao sao expostos pelo barrel `lib/title/title.dart`.

## Dependências Externas

- Flutter Material para `Scaffold`, `ElevatedButton`, `PopupMenuButton`, `Navigator` e `MaterialPageRoute`.
- Flutter Material para `SegmentedButton` no seletor de modo de controle.
- `flutter_bloc` para ler e atualizar `TitleControlModeCubit`, `AppLocaleCubit` e `AudioCubit`.
- `dart:ui` — não há mais dependência direta na feature Title.

## Observações

- A feature Title agora tem Cubits proprios para as preferencias de controles e nave; os estados globais consumidos continuam sendo `AppLocaleCubit` e `AudioCubit`.
- O idioma escolhido e persistido via `StorageService` e restaurado automaticamente no proximo lancamento.
- O modo de controle e a nave escolhidos tambem sao persistidos via `StorageService` e restaurados automaticamente quando a Title abre novamente.
- O breakpoint de 760px (definido em `TitleMainContent`) apenas controla o `isWide` passado ao `TitleHero` (tamanho de fonte e alinhamento de texto); nao ha mais bifurcacao de layout para o console.
