---
generated_at: 2026-07-27
source_commit: 698131b
source_state: clean
verified_at: 2026-09-12
status: current
related_plans:
  - docs/plan/local-persistence.md
  - docs/plan/player-ship-unlocks.md
---

# Flow: Title

> **Resumo:** Restaura e permite ajustar idioma, volume, controle e nave antes de substituir a tela por uma partida com as escolhas atuais.

## Visão Geral

`TitleView` é aberta quando o preload termina ou quando o usuário retorna pelo game over. Locale e áudio vêm de Cubits globais; modo de controle e nave selecionada usam Cubits próprios criados e fechados pela tela.

Na inicialização, o título restaura o modo de controle, lê a melhor distância e valida a nave persistida. A interface exibe idioma, mute, hero com a nave atual, seletor de skins, seletor touch/joystick e o botão de lançamento, usando textos de `context.l10n`.

Ao iniciar, `TitleStartButton` passa `GameControlMode` e `PlayerShipSkin` para `GamePage.route`. `Navigator.pushReplacement` remove a tela de título da pilha e entrega a configuração à gameplay.

## Passo a Passo

1. **Entrada após preload** — `lib/loading/view/loading_page.dart` → `onPreloadComplete`
   Substitui `LoadingPage` por `TitleView.route()` quando as fases terminam.
2. **Entrada após game over** — `lib/game/view/game_page.dart` → `onReturnToTitle`
   Substitui `GamePage` por uma nova `TitleView` quando o usuário escolhe voltar.
3. **Rota** — `lib/title/view/title_page.dart` → `TitleView.route`
   Cria a `MaterialPageRoute<void>` da tela.
4. **Estados locais** — `lib/title/view/title_page.dart` → `_TitleViewState.initState`
   Obtém `StorageService`, cria `TitleControlModeCubit` e `TitleShipSelectionCubit` e inicia a restauração de ambos.
5. **Modo de controle** — `lib/title/cubit/title_control_mode_cubit.dart` → `init`
   Lê `title_control_mode`, converte o nome persistido em enum e mantém touch quando o valor é ausente ou inválido.
6. **Recorde e nave** — `lib/title/view/title_page.dart` → `_initShipSelection`
   Lê `best_distance_km` e pede ao Cubit de seleção que restaure apenas uma nave conhecida e liberada.
7. **Composição da tela** — `lib/title/view/title_page.dart` → `build`
   Fornece os dois Cubits locais, observa seus estados e monta backdrop, top bar e conteúdo central responsivo.
8. **Idioma e áudio** — `lib/title/content/title_top_bar.dart` → `TitleTopBar.build`
   O menu chama `AppLocaleCubit.setLocale`; o botão de volume chama `AudioCubit.toggleVolume`.
9. **Escolha de nave** — `lib/title/view/title_page.dart` → `_showShipSelectionSheet`
   Abre o catálogo e envia seleções permitidas para `TitleShipSelectionCubit.setShip`.
10. **Escolha de controle** — `lib/title/content/title_control_mode_selector.dart` → `onSelectionChanged`
    Envia touch ou joystick a `TitleControlModeCubit.setControlMode`, que persiste o nome do enum.
11. **Início da partida** — `lib/title/content/title_start_button.dart` → `onPressed`
    Substitui a rota por `GamePage.route(controlMode: ..., playerShip: ...)`.
12. **Descarte** — `lib/title/view/title_page.dart` → `dispose`
    Fecha os Cubits locais de modo e nave; os Cubits globais permanecem sob `App`.

### Caminhos alternativos

- **Preferência de controle ausente ou inválida:** a tela mantém `GameControlMode.touch`.
- **Nave persistida inválida ou bloqueada:** a tela mantém `defaultPlayerShipSkin`.
- **Locale global nulo:** o texto do seletor usa o locale resolvido pelo Flutter.
- **Tela estreita:** `TitleHero` centraliza e reduz o título; a partir de 760 px usa a composição larga.

## Arquivos Envolvidos

| Camada | Arquivo | Responsabilidade |
|--------|---------|------------------|
| Rota/Apresentação | `lib/title/view/title_page.dart` | Cria estados locais, restaura preferências e compõe a tela. |
| Estado | `lib/title/cubit/title_control_mode_cubit.dart` | Persiste e restaura touch/joystick. |
| Estado | `lib/title/cubit/title_ship_selection_cubit.dart` | Persiste e valida a skin escolhida. |
| Estado global | `lib/app/cubit/app_locale_cubit.dart` | Mantém e persiste o idioma. |
| Estado global | `lib/game/cubit/audio/audio_cubit.dart` | Mantém e persiste mute/volume. |
| Apresentação | `lib/title/content/title_top_bar.dart` | Exibe idioma e volume. |
| Apresentação | `lib/title/content/title_main_content.dart` | Compõe hero, seletores e início. |
| Apresentação | `lib/title/content/title_ship_selection_sheet.dart` | Exibe catálogo e bloqueios de nave. |
| Apresentação | `lib/title/content/title_control_mode_selector.dart` | Exibe controle segmentado. |
| Navegação | `lib/title/content/title_start_button.dart` | Abre a partida configurada. |
| Dados | `lib/common/services/storage_service.dart` | Fornece locale, volume, modo, nave e recorde persistidos. |
| Testes | `test/title/view/title_page_test.dart` | Cobre renderização, idioma, áudio, seletores, persistência e rota. |
| Testes | `test/title/cubit/title_control_mode_cubit_test.dart` | Cobre restauração e persistência do controle. |
| Testes | `test/title/cubit/title_ship_selection_cubit_test.dart` | Cobre restauração e regras de desbloqueio da nave. |

## Regras de Negócio Relevantes

- **Controle padrão** — `lib/title/cubit/title_control_mode_cubit.dart`: novas instalações e valores inválidos usam touch.
- **Escolhas persistentes** — `lib/app/cubit/app_locale_cubit.dart`, `lib/game/cubit/audio/audio_cubit.dart`, `lib/title/cubit/`: idioma, volume, controle e nave sobrevivem a novas instâncias da tela.
- **Naves condicionadas ao recorde** — `lib/title/cubit/title_ship_selection_cubit.dart`: a seleção só muda quando `best_distance_km` alcança `unlockKm`.
- **Partida recebe snapshot atual** — `lib/title/content/title_start_button.dart`: modo e skin são passados como valores à nova rota.

## Dependências Externas

- `flutter_bloc` para estados globais e locais.
- Flutter Material para rota, bottom sheet, menu e controle segmentado.
- `shared_preferences`, via `StorageService`, para restaurar escolhas.

## Observações

- A tela mantém seus Cubits de controle e nave fora do método `build`, evitando recriá-los quando locale, áudio ou layout mudam.
- A restauração da melhor distância e da skin é assíncrona; até sua conclusão, o catálogo é renderizado com `0 km` e a nave padrão.
