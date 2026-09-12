---
generated_at: 2026-07-27
source_commit: 698131b
source_state: clean
verified_at: 2026-09-12
status: current
related_plans:
  - docs/plan/implement-drift-mvp.md
  - docs/plan/game-hud-audio-game-over.md
  - docs/plan/add-loose-meteors-obstacles.md
  - docs/plan/bgm-replace-thrust-tap.md
  - docs/plan/local-persistence.md
  - docs/plan/space-background-by-km.md
  - docs/plan/player-ship-unlocks.md
---

# Flow: Game

> **Resumo:** Executa uma rodada Flame configurada na tela de título, acumulando distância e dificuldade até colisão, quando persiste o recorde e oferece reinício ou retorno ao título.

## Visão Geral

O fluxo começa quando o usuário toca em Decolar/Launch. A rota recebe o modo de controle e a skin escolhidos; `GameView` inicia a BGM, obtém os providers globais e cria `ArcadeOne` dentro de um `GameWidget`.

O jogo restaura a melhor distância, carrega imagens do cache e monta fundo, nave, HUD e a primeira sequência de paredes de asteroides. A cada frame, distância, velocidade visual e dificuldade crescem; cenário e obstáculos avançam enquanto toque/drag ou joystick controlam o thrust da nave.

Colidir com uma parede, meteoro ou limite da tela encerra a rodada. Um novo recorde é persistido, o dispositivo recebe feedback háptico, o efeito de morte toca e um overlay Flutter permite reconstruir a rodada na mesma instância ou substituir a rota por `TitleView`. Em Android e iOS, um banner fica sobreposto na base da tela.

## Passo a Passo

1. **Início pelo título** — `lib/title/content/title_start_button.dart` → `TitleStartButton.build`
   O botão cria `GamePage.route` com `GameControlMode` e `PlayerShipSkin` atuais e usa `Navigator.pushReplacement`.
2. **Rota do jogo** — `lib/game/view/game_page.dart` → `GamePage.route`
   Constrói uma `MaterialPageRoute<void>` que preserva as escolhas da tela anterior em `GamePage` e `GameView`.
3. **Ciclo de áudio** — `lib/game/view/game_page.dart` → `_GameViewState.didChangeDependencies`
   Na primeira resolução de dependências, lê o `AudioCubit` global e solicita `startBgm`; `dispose` solicita `stopBgm`.
4. **Composição Flutter/Flame** — `lib/game/view/game_page.dart` → `GameView.build`
   Lê `AudioCubit`, `PreloadCubit` e `StorageService`, cria `ArcadeOne` uma única vez e o entrega a `GameWidget` com o overlay de game over.
5. **Carga inicial** — `lib/game/arcade_one.dart` → `ArcadeOne.onLoad`
   Restaura `best_distance_km` e chama `_buildRun`.
6. **Montagem da rodada** — `lib/game/arcade_one.dart` → `_buildRun`
   Carrega sprites, cria `SpaceBackgroundComponent`, `Ship` e `DriftHudComponent`, adiciona os componentes e gera a primeira sequência de obstáculos.
7. **Input da nave** — `lib/game/arcade_one.dart` → callbacks de toque/drag, `setJoystickDirection` e `clearJoystick`
   Apenas o modo selecionado altera o thrust; o joystick virtual aparece somente em partidas configuradas com `GameControlMode.joystick`.
8. **Atualização contínua** — `lib/game/arcade_one.dart` → `update`
   Aumenta `distanceKm`, deriva `scrollSpeed`, avança o background, move obstáculos, detecta colisões, remove itens fora da tela, verifica limites e prepara a próxima sequência.
9. **Movimento e HUD** — `lib/game/entities/ship/ship.dart` → `Ship.update`; `lib/game/components/drift_hud_component.dart` → `DriftHudComponent.update`
   A nave aplica aceleração, inércia, giro e limite de velocidade; o HUD localiza e atualiza distância atual e recorde.
10. **Fim da rodada** — `lib/game/arcade_one.dart` → `endRun`
    Executa uma única vez, salva o recorde se superado, dispara háptico e som de morte, mostra o overlay e paralisa a nave.
11. **Decisão pós-morte** — `lib/game/view/game_page.dart` → `overlayBuilderMap`
    `GameOverPopup` chama `restartRun` ou substitui a rota atual por `TitleView.route()`.
12. **Reinício** — `lib/game/arcade_one.dart` → `restartRun`
    Remove o overlay, zera a rodada, reposiciona a nave, reseta o fundo, remove obstáculos antigos e inicia uma nova sequência, preservando o recorde.

### Caminhos alternativos

- **Touch:** toque e drag apontam o thrust para a posição do evento; soltar ou cancelar limpa o thrust.
- **Joystick:** `GameJoystick` normaliza o deslocamento fora da dead zone e chama `setJoystickDirection`; eventos touch do `FlameGame` são ignorados.
- **Sem novo recorde:** `endRun` mantém `bestDistanceKm` e não grava no storage.
- **Imagem ausente:** nave, obstáculos ou marcos usam renderização procedural/fallback prevista pelos componentes.
- **Plataforma sem banner:** quando `AdConfig.maybeBanner` é `null`, o banner é omitido e o joystick usa apenas o espaçamento inferior padrão.

## Arquivos Envolvidos

| Camada | Arquivo | Responsabilidade |
|--------|---------|------------------|
| Entrada | `lib/title/content/title_start_button.dart` | Inicia a rota com controle e nave escolhidos. |
| Apresentação | `lib/game/view/game_page.dart` | Integra providers, Flame, overlays, áudio, joystick e banner. |
| Apresentação | `lib/game/widgets/game_joystick.dart` | Converte gesto local em direção normalizada. |
| Apresentação | `lib/game/widgets/game_over_popup.dart` | Exibe resultado e ações pós-morte. |
| Estado | `lib/game/cubit/audio/audio_cubit.dart` | Persiste volume e controla BGM e efeito de morte. |
| Orquestração | `lib/game/arcade_one.dart` | Mantém ciclo da rodada, progressão, spawn, colisões e recorde. |
| Entidade | `lib/game/entities/ship/ship.dart` | Implementa movimento, limites de velocidade e renderização da nave. |
| Componentes | `lib/game/components/` | Implementa background, HUD, paredes, meteoros e starfield. |
| Catálogos | `lib/game/background/`, `lib/game/player_ship/` | Define progressão visual e skins selecionáveis. |
| Dados | `lib/common/services/storage_service.dart` | Persiste melhor distância por contrato abstrato. |
| Anúncios | `lib/common/services/ads/ad_config.dart` | Resolve unidades de banner por plataforma. |
| Testes | `test/game/arcade_one_test.dart` | Cobre montagem, progressão, sequências, controles, colisão, restart e storage. |
| Testes | `test/game/view/game_page_test.dart` | Cobre rota, parâmetros, volume, overlay, retorno e joystick. |
| Testes | `test/game/components/` | Cobre comportamento isolado dos componentes Flame. |

## Regras de Negócio Relevantes

- **Velocidade crescente** — `lib/game/arcade_one.dart`: `driftSpeed` começa em `2` e soma `distanceKm * 0.0008`; o scroll visual multiplica o resultado por `42`.
- **Dificuldade limitada** — `lib/game/arcade_one.dart`: `difficulty` cresce até `distanceKm / 3000` atingir `1`.
- **Modos de controle distintos** — `lib/game/arcade_one.dart`: touch usa thrust `520` e velocidade máxima `250`; joystick usa `360` e `170`.
- **Alternância de obstáculos** — `lib/game/arcade_one.dart`: meteoros só ficam elegíveis após três sequências de paredes, têm 25% de chance e não ultrapassam duas sequências consecutivas.
- **Colisão encerra a rodada** — `lib/game/arcade_one.dart`: tocar qualquer obstáculo ou limite da área dispara `endRun` uma única vez.
- **Recorde persistente** — `lib/game/arcade_one.dart`: `best_distance_km` só é regravado quando a distância atual supera o valor restaurado.
- **Volume binário** — `lib/game/cubit/audio/audio_cubit.dart`: o toggle alterna exclusivamente entre `0` e `1` e persiste em `audio_volume`.

## Dependências Externas

- Flame para loop, input, componentes, overlays e cache de imagens.
- `audioplayers` para BGM e efeito de morte.
- `shared_preferences`, acessado por `StorageService`, para recorde e preferências.
- Google Mobile Ads para o banner em Android e iOS.

## Observações

- A BGM `assets/audio/background_2.mp3` não faz parte da fase de áudio do `PreloadCubit`; `AudioCubit.startBgm` solicita sua reprodução ao entrar em `GameView`.
- Se a tela do jogo for aberta enquanto o volume já está em `0`, `startBgm` retorna sem tocar; desmutar altera o volume do player, mas não chama `play` novamente.
- `ArcadeOne` concentra orquestração, regras de spawn, persistência e carregamento de imagens no mesmo arquivo, por isso alterações de gameplay costumam atravessar esse núcleo e seus testes.
