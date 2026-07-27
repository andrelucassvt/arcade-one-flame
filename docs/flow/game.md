---
generated_at: 2026-07-27
source_commit: 2bc98a5
source_state: dirty
verified_at: 2026-07-27
status: current
related_plans: []
---

# Flow: Game

> **Resumo:** Executa uma partida Flame com nave por toque ou joystick, progressão por distância, obstáculos, áudio, anúncio, game over, recorde persistido e restart.

## Visão Geral

O fluxo começa quando `TitleStartButton` substitui a Title por `GamePage`, passando o modo de controle e a nave selecionados. `GameView` inicia a BGM pelo `AudioCubit`, obtém os caches e o storage globais e cria `ArcadeOne` dentro de um `GameWidget`.

`ArcadeOne` restaura a melhor distância, carrega imagens do cache e monta fundo, nave, HUD e a primeira sequência de asteroides. Durante a partida, eventos de toque/drag ou o joystick virtual controlam o thrust da nave; o update aumenta distância e velocidade visual, move o cenário e os obstáculos e verifica colisões e bordas.

Uma colisão encerra a rodada, persiste um novo recorde quando necessário, dispara feedback háptico e som de morte e abre um overlay Flutter. O usuário pode reiniciar a mesma instância do jogo ou voltar para `TitleView`. Em Android e iOS, um banner fica sobreposto na base da tela.

## Passo a Passo

1. **Gatilho** — `lib/title/content/title_start_button.dart` → callback `onPressed`
   Chama `GamePage.route` com o `GameControlMode` e a `PlayerShipSkin` selecionados e usa `pushReplacement`.
2. **Rota e tela** — `lib/game/view/game_page.dart` → `GamePage.route` e `GamePage.build`
   Cria uma `MaterialPageRoute<void>` e monta `GameView` dentro de um `Scaffold`.
3. **BGM** — `lib/game/view/game_page.dart` → `_GameViewState.didChangeDependencies`
   Obtém o `AudioCubit` global uma vez e dispara `startBgm`.
4. **Criação do jogo** — `lib/game/view/game_page.dart` → `_GameViewState.build`
   Cria `ArcadeOne` com l10n, player de morte, estilo do HUD, imagens do `PreloadCubit`, `StorageService`, controle e nave.
5. **Composição Flutter/Flame** — `lib/game/view/game_page.dart` → `GameWidget`
   Renderiza a cena, registra o builder do overlay `game_over`, repassa o padding seguro ao HUD e sobrepõe mute, joystick opcional e banner opcional.
6. **Carregamento do recorde** — `lib/game/arcade_one.dart` → `ArcadeOne.onLoad`
   Lê `best_distance_km` do storage e usa `0.0` quando não existe valor.
7. **Montagem da rodada** — `lib/game/arcade_one.dart` → `_buildRun`
   Carrega imagens, cria `SpaceBackgroundComponent`, `Ship` e `DriftHudComponent`, adiciona os componentes e gera a primeira sequência.
8. **Carregamento de sprites** — `lib/game/arcade_one.dart` → `_loadGameImages`
   Busca tile padrão e tiles por marco, meteoro, nave selecionada e cenários no cache de `Images`; uma falha individual resulta em imagem `null`.
9. **Controle por toque** — `lib/game/arcade_one.dart` → `onTapDown`, `onDragStart`, `onDragUpdate`
   No modo `touch` e com rodada ativa, transforma a posição do ponteiro em alvo de thrust para `Ship.setThrustTarget`.
10. **Controle por joystick** — `lib/game/widgets/game_joystick.dart` → `GameJoystick`
    Calcula uma direção normalizada com dead zone de `0.14` e chama `ArcadeOne.setJoystickDirection`; ao soltar, chama `clearJoystick`.
11. **Inércia e movimento** — `lib/game/entities/ship/ship.dart` → `Ship.update`
    Acelera na direção do thrust, limita a velocidade, gira gradualmente e atualiza a posição; limpar o thrust não zera a velocidade.
12. **Progressão** — `lib/game/arcade_one.dart` → `ArcadeOne.update`
    Incrementa `distanceKm`, recalcula `scrollSpeed`, avança o background, move obstáculos, remove itens fora da tela, gera sequências e verifica limites.
13. **Background por distância** — `lib/game/components/space_background_component.dart` → `advance` e `render`
    Avança o starfield e renderiza os marcos visíveis do catálogo com fade e parallax; usa desenho de fallback quando a imagem não foi carregada.
14. **Sequências de obstáculos** — `lib/game/arcade_one.dart` → `_spawnNextObstacleSequence`
    Começa com sete `AsteroidPairComponent`; após sequências suficientes, pode gerar `LooseMeteorComponent` sem remover prematuramente a sequência anterior.
15. **Colisões e bordas** — `lib/game/arcade_one.dart` → `update` e `_checkBounds`
    Colisão da nave com blocos, meteoros ou qualquer borda chama `endRun`.
16. **Fim da rodada** — `lib/game/arcade_one.dart` → `endRun`
    Ativa `isGameOver`, persiste recorde maior, dispara haptic, toca `Assets.audio.death`, abre o overlay e para a nave.
17. **Overlay Flutter** — `lib/game/view/game_page.dart` → `overlayBuilderMap`
    Calcula a distância inteira e monta `GameOverPopup` com ações de restart e retorno à Title.
18. **Restart** — `lib/game/widgets/game_over_popup.dart` → `onRestart` → `ArcadeOne.restartRun`
    Remove o overlay, zera a rodada, reseta nave e background, remove obstáculos antigos e cria uma nova sequência inicial.
19. **Volta à Title** — `lib/game/widgets/game_over_popup.dart` → `onReturnToTitle`
    Executa `pushReplacement(TitleView.route())`.
20. **Encerramento da tela** — `lib/game/view/game_page.dart` → `_GameViewState.dispose`
    Dispara `AudioCubit.stopBgm` quando a Game sai da árvore.

### Caminhos alternativos

- **Modo touch:** o canvas aceita tap e drag; o joystick virtual não é exibido.
- **Modo joystick:** eventos de tap/drag do canvas não movem a nave; `GameJoystick` envia a direção e a nave usa thrust e velocidade máxima reduzidos.
- **Volume mutado ao entrar:** `AudioCubit.startBgm` retorna sem iniciar a faixa.
- **Plataforma sem banner:** `AdConfig.maybeBanner` retorna `null`; banner e reserva adicional do joystick são omitidos.
- **Falha do banner principal:** `AdBannerWidget` descarta o anúncio e tenta a unidade fallback uma única vez.
- **Sprite indisponível:** nave, asteroides, meteoro e marcos mantêm renderização procedural ou deixam o sprite ausente, conforme o componente.
- **Recorde não superado:** `endRun` mantém `bestDistanceKm` e não grava no storage.
- **Chamada repetida de game over:** a guarda `isGameOver` impede repetir persistência, haptic e som de morte.

## Arquivos Envolvidos

| Camada | Arquivo | Responsabilidade |
|--------|---------|------------------|
| Origem | `lib/title/content/title_start_button.dart` | Inicia a Game com controle e nave selecionados. |
| Apresentação | `lib/game/view/game_page.dart` | Cria a rota, integra `GameWidget`, overlays, áudio, joystick, mute e banner. |
| Jogo Flame | `lib/game/arcade_one.dart` | Orquestra load, input, progressão, spawn, colisões, game over e restart. |
| Estado / Cubit | `lib/game/cubit/audio/audio_cubit.dart` | Restaura e alterna volume e inicia/para a BGM. |
| Estado | `lib/game/cubit/audio/audio_state.dart` | Guarda o volume atual. |
| Configuração de áudio | `lib/game/game_audio_assets.dart` | Define `assets/audio/background_2.mp3` como BGM. |
| Configuração de imagem | `lib/game/game_image_assets.dart` | Define sprites e a lista completa usada no preload. |
| Configuração de controle | `lib/game/game_control_mode.dart` | Define os modos `touch` e `joystick`. |
| Entidade | `lib/game/entities/ship/ship.dart` | Implementa thrust, inércia, velocidade, rotação, colisão e renderização da nave. |
| Componente | `lib/game/components/asteroid_pair_component.dart` | Implementa paredes com gap, movimento, colisão e tile por marco. |
| Componente | `lib/game/components/loose_meteor_component.dart` | Implementa meteoro circular com drift horizontal. |
| Componente | `lib/game/components/drift_hud_component.dart` | Exibe distância atual e melhor distância respeitando SafeArea. |
| Background | `lib/game/background/space_landmark.dart` | Modela janela de visibilidade e parallax de um marco. |
| Background | `lib/game/background/space_landmark_catalog.dart` | Ordena marcos e seleciona os ativos pela distância. |
| Componente | `lib/game/components/space_background_component.dart` | Renderiza starfield e marcos com fade, parallax e fallback. |
| Componente | `lib/game/components/starfield_component.dart` | Renderiza 95 estrelas determinísticas em duas velocidades. |
| Widget | `lib/game/widgets/game_joystick.dart` | Converte gestos em direção de controle. |
| Widget | `lib/game/widgets/game_over_popup.dart` | Mostra distância e ações após a morte. |
| Serviços | `lib/common/services/storage_service.dart` | Persiste volume e melhor distância. |
| Anúncios | `lib/common/services/ads/ad_config.dart` | Fornece IDs principal e fallback em Android e iOS. |
| Anúncios | `lib/common/widgets/ad_banner_widget.dart` | Carrega, exibe, tenta fallback e descarta o banner. |
| Testes | `test/game/arcade_one_test.dart` | Cobre load, progressão, sequências, controles, mortes, recorde e restart. |
| Testes | `test/game/view/game_page_test.dart` | Cobre rota, argumentos, mute, overlay, retorno e joystick. |
| Testes | `test/game/cubit/audio_cubit_test.dart` | Cobre persistência de volume, BGM e descarte dos players. |
| Testes | `test/game/entities/ship/ship_test.dart` | Cobre thrust, inércia, velocidade máxima e reset. |
| Testes | `test/game/components/asteroid_pair_component_test.dart` | Cobre gap, movimento e colisão dos pares. |
| Testes | `test/game/components/loose_meteor_component_test.dart` | Cobre movimento, saída de tela e colisão dos meteoros. |
| Testes | `test/game/components/space_background_component_test.dart` | Cobre continuidade, marcos, movimento e reset do background. |
| Testes | `test/game/background/space_landmark_catalog_test.dart` | Cobre ordem, assets e seleção de marcos. |
| Testes | `test/game/player_ship/player_ship_catalog_test.dart` | Cobre desbloqueios, requisitos e fallback de nave. |

## Regras de Negócio Relevantes

- **Defaults da partida** — `lib/game/view/game_page.dart`: sem argumentos, o modo é `touch` e a nave é `defaultPlayerShipSkin`.
- **Parâmetros menores no joystick** — `lib/game/arcade_one.dart`: o modo joystick usa thrust `360` e velocidade máxima `170`; touch usa os defaults `520` e `250` de `Ship`.
- **Inércia preservada** — `lib/game/entities/ship/ship.dart`: `clearThrust` remove aceleração, mas não altera `velocity`.
- **Progressão contínua** — `lib/game/arcade_one.dart`: `driftSpeed = 2 + distanceKm * 0.0008`, e o scroll visual multiplica esse valor por `42`.
- **Dificuldade limitada** — `lib/game/arcade_one.dart`: `difficulty` é `distanceKm / 3000`, limitada ao intervalo de `0` a `1`.
- **Gap menor com dificuldade** — `lib/game/components/asteroid_pair_component.dart`: o gap parte de `150` e chega a `86` na faixa atual, protegido pelo mínimo `76`.
- **Primeira sequência fixa** — `lib/game/arcade_one.dart`: toda rodada começa com sete pares de asteroides.
- **Meteoros condicionais** — `lib/game/arcade_one.dart`: meteoros só ficam elegíveis após três sequências consecutivas de pares, têm chance `0.25` e no máximo duas sequências consecutivas.
- **Quantidade de meteoros por dificuldade** — `lib/game/arcade_one.dart`: a sequência contém de 9 a 14 meteoros.
- **Game over por contato** — `lib/game/arcade_one.dart`: tocar bordas, asteroides ou meteoro encerra a rodada.
- **Rodada congelada após a morte** — `lib/game/arcade_one.dart`: `update` retorna imediatamente quando `isGameOver` é verdadeiro.
- **Recorde monotônico** — `lib/game/arcade_one.dart`: `best_distance_km` só é salvo quando a distância atual supera a melhor.
- **Volume binário persistido** — `lib/game/cubit/audio/audio_cubit.dart`: `toggleVolume` alterna entre `0` e `1`, aplica aos dois players e salva `audio_volume`.
- **BGM limitada à Game** — `lib/game/view/game_page.dart`: começa na primeira resolução de dependências e para no dispose da tela.
- **Banner somente mobile suportado** — `lib/common/services/ads/ad_config.dart`: somente Android e iOS recebem IDs.

## Dependências Externas

- `flame` para `FlameGame`, `GameWidget`, eventos, componentes, vetores e cache de imagens.
- Flutter Material e services para overlays, gestos, navegação, SafeArea e `HapticFeedback`.
- `audioplayers` para BGM, som de morte e volume.
- `flutter_bloc` e `equatable` para estado de áudio.
- `shared_preferences`, via `StorageService`, para volume e melhor distância.
- `google_mobile_ads` para o banner.

## Observações

- O código atual não possui player nem efeito sonoro de motor; o áudio de runtime é BGM mais som de morte.
- Se a Game abrir já mutada, `startBgm` não inicia a faixa e desmutar não chama `startBgm` novamente.
- Os componentes mantêm fallbacks procedurais para testes ou falhas de imagem; o starfield é sempre procedural.
- `flame_audio` está declarado no `pubspec.yaml`, mas este fluxo usa `audioplayers` diretamente.
