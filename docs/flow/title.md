---
generated_at: 2026-07-27
source_commit: 2bc98a5
source_state: dirty
verified_at: 2026-07-27
status: current
related_plans: []
---

# Flow: Title

> **Resumo:** Permite escolher idioma, volume, modo de controle e uma nave desbloqueada antes de substituir a tela pela partida configurada.

## Visão Geral

`TitleView` é aberta ao concluir o preload ou ao voltar do game over. Na inicialização, a tela obtém o `StorageService` global, cria Cubits próprios para modo de controle e seleção de nave e restaura as preferências salvas.

A melhor distância persistida define quais naves estão desbloqueadas. A tela exibe o locale e o volume controlados pelos Cubits globais, além dos seletores locais de controle e nave; todas as strings visíveis vêm de `context.l10n`.

Ao tocar em Launch/Decolar, `TitleStartButton` cria `GamePage.route` com o `GameControlMode` e a `PlayerShipSkin` atuais. `Navigator.pushReplacement` remove a Title da pilha e inicia a gameplay com essas escolhas.

## Passo a Passo

1. **Origem principal** — `lib/loading/view/loading_page.dart` → `onPreloadComplete`
   Após o preload, substitui a Loading por `TitleView.route()`.
2. **Origem alternativa** — `lib/game/view/game_page.dart` → callback `onReturnToTitle`
   O popup de game over substitui a Game por `TitleView.route()`.
3. **Rota** — `lib/title/view/title_page.dart` → `TitleView.route`
   Cria uma `MaterialPageRoute<void>` cuja tela é `TitleView`.
4. **Cubits locais** — `lib/title/view/title_page.dart` → `_TitleViewState.initState`
   Lê `StorageService`, cria `TitleControlModeCubit` e `TitleShipSelectionCubit`, inicia a restauração do controle e chama `_initShipSelection`.
5. **Restauração da melhor distância e nave** — `lib/title/view/title_page.dart` → `_initShipSelection`
   Lê `best_distance_km`, atualiza `_bestDistanceKm` e pede ao Cubit de nave que valide a seleção persistida contra esse recorde.
6. **Composição da tela** — `lib/title/view/title_page.dart` → `_TitleViewState.build`
   Lê o locale global, fornece os dois Cubits locais, reage ao controle e à nave e monta backdrop, top bar e conteúdo dentro de uma área rolável.
7. **Idioma e áudio** — `lib/title/content/title_top_bar.dart` → `TitleTopBar.build`
   O menu EN/PT chama `AppLocaleCubit.setLocale`; o botão de volume reage a `AudioCubit` e chama `toggleVolume`.
8. **Conteúdo principal** — `lib/title/content/title_main_content.dart` → `TitleMainContent.build`
   Exibe a nave atual, o seletor de nave, o `SegmentedButton` de controle e o botão de início; `TitleHero` usa o breakpoint de 760 px para ajustar o título e a nave.
9. **Modo de controle** — `lib/title/content/title_control_mode_selector.dart` → `TitleControlModeSelector`
   A escolha entre `touch` e `joystick` chama `TitleControlModeCubit.setControlMode`, que persiste `mode.name` e emite o novo modo.
10. **Abertura do catálogo de naves** — `lib/title/content/title_ship_selector_button.dart` → `TitleShipSelectorButton`
    O botão com preview e nome localizado chama `_showShipSelectionSheet`.
11. **Gating por distância** — `lib/title/content/title_ship_selection_sheet.dart` → `TitleShipSelectionSheet`
    O grid percorre `playerShipSkins`, calcula desbloqueio com `isPlayerShipUnlocked` e desabilita o toque em skins bloqueadas.
12. **Persistência da nave** — `lib/title/view/title_page.dart` → `_showShipSelectionSheet`
    Uma seleção liberada chama `TitleShipSelectionCubit.setShip`, salva `title_player_ship`, emite a skin e fecha o bottom sheet.
13. **Ação de início** — `lib/title/content/title_start_button.dart` → `TitleStartButton.build`
    O botão usa a string localizada e mantém as escolhas atuais em `controlMode` e `playerShip`.
14. **Navegação para a partida** — `lib/title/content/title_start_button.dart` → callback `onPressed`
    Executa `pushReplacement(GamePage.route(controlMode: controlMode, playerShip: playerShip))`.
15. **Destino** — `lib/game/view/game_page.dart` → `GamePage.route`
    Cria `GamePage` com o controle e a nave escolhidos.

### Caminhos alternativos

- **Modo salvo ausente ou desconhecido:** `TitleControlModeCubit` mantém `GameControlMode.touch`.
- **Nave salva desconhecida ou bloqueada:** `TitleShipSelectionCubit` mantém `defaultPlayerShipSkin`.
- **Sem melhor distância salva:** `_bestDistanceKm` fica em `0`, então somente a nave default está liberada.
- **Nave bloqueada:** `_ShipSelectionTile` recebe `onTap: null`; não persiste nem fecha o sheet.
- **Locale global nulo:** `TitleTopBar` usa `Localizations.localeOf(context)` para mostrar o idioma resolvido pelo sistema.

## Arquivos Envolvidos

| Camada | Arquivo | Responsabilidade |
|--------|---------|------------------|
| Apresentação / rota | `lib/title/view/title_page.dart` | Cria a rota, restaura dados, fornece Cubits e compõe a tela. |
| Estado / Cubit | `lib/title/cubit/title_control_mode_cubit.dart` | Restaura e persiste `GameControlMode`. |
| Estado / Cubit | `lib/title/cubit/title_ship_selection_cubit.dart` | Restaura e persiste uma nave conhecida e desbloqueada. |
| Apresentação | `lib/title/content/title_top_bar.dart` | Controla idioma e mute global. |
| Apresentação | `lib/title/content/title_main_content.dart` | Organiza hero, seletores e botão de início. |
| Apresentação | `lib/title/content/title_control_mode_selector.dart` | Exibe as opções touch e joystick. |
| Apresentação | `lib/title/content/title_ship_selector_button.dart` | Mostra a nave atual e abre o catálogo. |
| Apresentação | `lib/title/content/title_ship_selection_sheet.dart` | Lista naves, estados de desbloqueio e requisitos em km. |
| Apresentação | `lib/title/content/title_start_button.dart` | Substitui a Title pela `GamePage` configurada. |
| Catálogo | `lib/game/player_ship/player_ship_catalog.dart` | Define skins, distâncias de desbloqueio, lookup e nomes localizados. |
| Modelo | `lib/game/player_ship/player_ship_skin.dart` | Representa id, asset e requisito de cada nave. |
| Estado global | `lib/app/cubit/app_locale_cubit.dart` | Persiste e aplica o locale. |
| Estado global | `lib/game/cubit/audio/audio_cubit.dart` | Persiste e alterna o volume. |
| Serviços | `lib/common/services/storage_service.dart` | Persiste locale, controle, nave, volume e melhor distância. |
| Localização | `lib/l10n/arb/app_en.arb` | Textos da Title em inglês. |
| Localização | `lib/l10n/arb/app_pt.arb` | Textos da Title em português. |
| Testes | `test/title/cubit/title_control_mode_cubit_test.dart` | Cobre default, restauração, persistência e valor inválido. |
| Testes | `test/title/cubit/title_ship_selection_cubit_test.dart` | Cobre default, restauração, bloqueio, lookup e persistência. |
| Testes | `test/title/view/title_page_test.dart` | Cobre UI, idioma, áudio, seleções persistidas e argumentos da Game. |

## Regras de Negócio Relevantes

- **Controle default touch** — `lib/title/cubit/title_control_mode_cubit.dart`: o estado inicial é `GameControlMode.touch`.
- **Controle persistido pelo nome do enum** — `lib/title/cubit/title_control_mode_cubit.dart`: a chave é `title_control_mode`; nomes desconhecidos são ignorados.
- **Nave default sempre disponível** — `lib/game/player_ship/player_ship_catalog.dart`: `defaultPlayerShipSkin` exige `0` km.
- **Desbloqueio por recorde** — `lib/game/player_ship/player_ship_catalog.dart`: cada skin é liberada quando `ship.unlockKm <= bestDistanceKm`.
- **Nave persistida validada novamente** — `lib/title/cubit/title_ship_selection_cubit.dart`: a skin salva só é restaurada se o id existir e continuar desbloqueado.
- **Seleção bloqueada não altera estado** — `lib/title/cubit/title_ship_selection_cubit.dart`: `setShip` retorna antes de gravar quando o requisito não foi atingido.
- **Escolhas repassadas à partida** — `lib/title/content/title_start_button.dart`: modo e nave são argumentos de `GamePage.route`.
- **Title removida da pilha** — `lib/title/content/title_start_button.dart`: o início usa `pushReplacement`.

## Dependências Externas

- Flutter Material para layout, menu, bottom sheet, grid e navegação.
- `flutter_bloc` para Cubits locais e globais, `BlocBuilder` e `context.select`.
- `shared_preferences`, indiretamente por `StorageService`, para as preferências.

## Observações

- O arquivo se chama `title_page.dart`, mas a classe pública atual é `TitleView`; não existe uma classe `TitlePage`.
- `TitleMainContent` recebe `bestDistanceKm`, porém o valor é usado no fluxo pelo bottom sheet construído em `TitleView`, não diretamente dentro de `TitleMainContent`.
