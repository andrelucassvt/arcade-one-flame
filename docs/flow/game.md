---
generated_at: 2026-07-27
source_commit: 1f03b4f
source_state: dirty
verified_at: 2026-09-14
status: current
related_plans:
  - docs/plan/implement-drift-mvp.md
  - docs/plan/game-hud-audio-game-over.md
  - docs/plan/add-loose-meteors-obstacles.md
  - docs/plan/bgm-replace-thrust-tap.md
  - docs/plan/local-persistence.md
  - docs/plan/space-background-by-km.md
  - docs/plan/player-ship-unlocks.md
  - docs/plan/remove-ads-iap.md
---

# Flow: Game

> **Resumo:** Executa uma rodada Flame configurada na tela de título, acumulando distância com combo de near miss, power-ups de escudo/câmera lenta e dificuldade crescente até uma colisão encerrar a rodada com hit-stop e oferecer reinício ou retorno ao título.

## Visão Geral

O fluxo começa quando o usuário toca em Decolar/Launch. A rota recebe o modo de controle e a skin escolhidos; `GameView` obtém os providers globais e cria `ArcadeOne` dentro de um `GameWidget`. Não há música de fundo: o único áudio contínuo é o som do motor da nave, que toca em loop enquanto o jogador impulsiona.

O jogo restaura a melhor distância, carrega imagens do cache e monta fundo, nave, HUD e a primeira sequência de paredes de asteroides. A rodada nasce com um período de invulnerabilidade (a nave pisca) para dar tempo de orientação. A cada frame, distância, velocidade visual e dificuldade crescem; no modo touch a direção do thrust é recalculada continuamente a partir do alvo segurado, com dead zone e suavização, e quando não há thrust a velocidade decai por damping.

Power-ups de escudo e câmera lenta nascem sobre gaps de paredes estáticas: o escudo absorve uma colisão e a câmera lenta reduz o `timeScale` da rodada. Passar raspando em obstáculos registra um near miss que alimenta um combo, e o combo multiplica o ganho de distância. Depois de 3000 km entra a curva "deep space", que aumenta a chance de gaps móveis, a quantidade de meteoros e a velocidade base.

Colidir sem escudo encerra a rodada com hit-stop: a cena desacelera, a nave explode em partículas e a tela treme; o overlay de game over só aparece após um atraso e o engine é pausado. Um novo recorde é persistido, o dispositivo recebe feedback háptico e o efeito de morte toca. O popup Flutter permite reconstruir a rodada na mesma instância (retomando o engine) ou substituir a rota por `TitleView`. Em Android e iOS, um banner fica sobreposto na base da tela; ao morrer, um intersticial pré-carregado pode assumir a tela, limitado a uma exibição a cada 60 s. Ambos os formatos são omitidos quando o entitlement de remoção de anúncios está ativo.

## Passo a Passo

1. **Início pelo título** — `lib/title/content/title_start_button.dart` → `TitleStartButton.build`
   O botão cria `GamePage.route` com `GameControlMode` e `PlayerShipSkin` atuais e usa `Navigator.pushReplacement`.
2. **Rota do jogo** — `lib/game/view/game_page.dart` → `GamePage.route`
   Constrói uma `MaterialPageRoute<void>` que preserva as escolhas da tela anterior em `GamePage` e `GameView`.
3. **Preload do intersticial** — `lib/game/view/game_page.dart` → `_GameViewState.didChangeDependencies`
   Na primeira resolução de dependências, pede o preload do intersticial a `InterstitialAdService.load`.
4. **Composição Flutter/Flame** — `lib/game/view/game_page.dart` → `GameView.build`
   Lê `AudioCubit`, `PreloadCubit` e `StorageService`, cria `ArcadeOne` uma única vez (entregando `deathPlayer` e `enginePlayer` do `AudioCubit`) e o entrega a `GameWidget` com o overlay de game over.
5. **Carga inicial** — `lib/game/arcade_one.dart` → `ArcadeOne.onLoad`
   Restaura `best_distance_km` e chama `_buildRun`.
6. **Montagem da rodada** — `lib/game/arcade_one.dart` → `_buildRun`
   Carrega sprites, cria `SpaceBackgroundComponent`, `Ship` e `DriftHudComponent`, define `_invulnerabilitySeconds` com `invulnerabilityGraceSeconds` e gera a primeira sequência de obstáculos.
7. **Input da nave** — `lib/game/arcade_one.dart` → callbacks de toque/drag e `setJoystickDirection`
   Toque/drag gravam o alvo no mundo via `Ship.setThrustTarget`; `Ship.update` recomputa a direção a cada frame com dead zone e suavização. O joystick virtual envia direção normalizada somente em partidas `GameControlMode.joystick`.
8. **Atualização contínua** — `lib/game/arcade_one.dart` → `update`
   Limita `dt` por `maxGameUpdateDt`, sincroniza o som do motor com `Ship.isThrusting` via `_syncEngineSound` (play em loop de `Assets.audio.engineFire` ao começar a impulsionar, `stop` ao soltar), aplica `timeScale` (câmera lenta), decai timers, avança `distanceKm` com `comboMultiplier`, deriva `scrollSpeed`, move background/obstáculos/meteoros/power-ups, registra near miss, absorve colisão com escudo, prepara a próxima sequência, aplica soft bounds e decai o screen shake.
9. **Movimento, efeitos e HUD** — `lib/game/entities/ship/ship.dart` → `Ship.update`; `lib/game/components/drift_hud_component.dart` → `DriftHudComponent.update`
   A nave aplica aceleração, inércia com damping, giro, limite de velocidade, trilha do motor e anel de escudo; o HUD reescreve textos apenas quando os inteiros mudam e exibe o combo.
10. **Absorção de impacto** — `lib/game/arcade_one.dart` → `_tryAbsorbHit`
    Com escudo ativo, consome o escudo, remove o obstáculo/meteoro, gera explosão e concede invulnerabilidade curta; sem escudo, cai em `endRun`.
11. **Fim da rodada** — `lib/game/arcade_one.dart` → `endRun`
    Ativa slow motion de morte, persiste recorde se superado, dispara háptico e som, explode a nave e treme a tela; o overlay só é adicionado depois de `deathOverlayDelaySeconds`, quando `pauseEngine` é chamado.
12. **Decisão pós-morte** — `lib/game/view/game_page.dart` → `overlayBuilderMap`
    Quando o overlay aparece, `GameOverPopup.onShown` aciona `InterstitialAdService.showOnGameOver`, que exibe o anúncio pré-carregado se a remoção de anúncios não está ativa e o cooldown de 60 s passou. O popup chama `restartRun` ou substitui a rota atual por `TitleView.route()`.
13. **Reinício** — `lib/game/arcade_one.dart` → `restartRun`
    Retoma o engine, remove overlay, zera rodada/combo/efeitos, limpa bursts e power-ups, reposiciona a nave, reseta o fundo, remove obstáculos antigos e inicia uma nova sequência com grace period, preservando o recorde.

### Caminhos alternativos

- **Touch:** toque e drag guardam o alvo no mundo; soltar ou cancelar limpa o alvo.
- **Som do motor:** em ambos os modos de controle, o loop de `engine_fire.mp3` segue exatamente o mesmo sinal (`Ship.isThrusting`) que anima a chama da nave; alvo dentro da dead zone, soltar o controle ou `endRun` param o som.
- **Joystick:** `GameJoystick` normaliza o deslocamento fora da dead zone e chama `setJoystickDirection`; eventos touch do `FlameGame` são ignorados.
- **Borda da tela:** `_applySoftBounds` fixa a posição dentro da área e reflete a velocidade com `bounceRestitution`, sem encerrar a rodada.
- **Grace period:** colisões são ignoradas enquanto `isInvulnerable`; testes usam `invulnerabilityGraceSeconds: 0`.
- **Near miss:** `tryRegisterNearMiss` marca o obstáculo uma única vez e `_rewardNearMiss` incrementa combo e renova a janela.
- **Câmera lenta:** enquanto `isSlowMotionActive`, `timeScale` é `slowMotionTimeScale` e um tint azul é desenhado sobre a cena.
- **Sem novo recorde:** `endRun` mantém `bestDistanceKm` e não grava no storage.
- **Imagem ausente:** nave, obstáculos e marcos usam renderização procedural/fallback prevista pelos componentes.
- **Plataforma sem banner:** quando `AdConfig.maybeBanner` é `null`, o banner é omitido e o joystick usa apenas o espaçamento inferior padrão.
- **Anúncios removidos:** com `hasRemovedAds` verdadeiro no `RemoveAdsCubit`, `GameView` trata `bannerAdUnitId` como `null`, omite o `AdBannerWidget` e o popup de game over não aciona o intersticial; o joystick volta ao espaçamento inferior padrão.
- **Intersticial em cooldown:** com menos de 60 s desde a última exibição, `showOnGameOver` ignora o pedido sem esconder o popup.
- **Intersticial sem preload:** sem anúncio carregado, o pedido apenas dispara um novo `load` e a rodada segue sem exibição.

## Arquivos Envolvidos

| Camada | Arquivo | Responsabilidade |
|--------|---------|------------------|
| Entrada | `lib/title/content/title_start_button.dart` | Inicia a rota com controle e nave escolhidos. |
| Apresentação | `lib/game/view/game_page.dart` | Integra providers, Flame, overlays, áudio, joystick, banner e o gatilho do intersticial no game over (ambos ocultos com anúncios removidos). |
| Estado global | `lib/app/cubit/remove_ads_cubit.dart` | Mantém o entitlement que remove o banner do jogo. |
| Apresentação | `lib/game/widgets/game_joystick.dart` | Converte gesto local em direção normalizada com `ValueNotifier`. |
| Apresentação | `lib/game/widgets/game_over_popup.dart` | Exibe resultado, ações pós-morte e notifica a primeira exibição via `onShown`. |
| Estado | `lib/game/cubit/audio/audio_cubit.dart` | Persiste o volume e o aplica aos players de morte e de motor; não inicia nem para reprodução. |
| Orquestração | `lib/game/arcade_one.dart` | Mantém ciclo da rodada, progressão, spawn, colisões, combos, power-ups, soft bounds e morte. |
| Entidade | `lib/game/entities/ship/ship.dart` | Implementa input contínuo, inércia com damping, escudo, trilha e renderização da nave. |
| Componentes | `lib/game/components/asteroid_pair_component.dart` | Modela paredes com gap fixo/móvel, colisão e near miss. |
| Componentes | `lib/game/components/loose_meteor_component.dart` | Modela meteoro com drift, bounce, rotação e near miss. |
| Componentes | `lib/game/components/power_up_component.dart` | Modela pickups de escudo e câmera lenta. |
| Componentes | `lib/game/components/particle_burst_component.dart` | Animação de explosão/coleta em canvas. |
| Componentes | `lib/game/components/drift_hud_component.dart` | Distância, recorde e combo com atualização cacheada. |
| Componentes | `lib/game/components/space_background_component.dart` | Fundo por km com starfield e marcos otimizados. |
| Componentes | `lib/game/components/starfield_component.dart` | Estrelas em parallax desenhadas com `drawRawPoints`. |
| Dados | `lib/common/services/storage_service.dart` | Persiste melhor distância por contrato abstrato. |
| Anúncios | `lib/common/services/ads/ad_config.dart` | Resolve unidades de banner principal, alternativo e intersticial por plataforma. |
| Anúncios | `lib/common/services/ads/interstitial_ad_service.dart` | Carrega e exibe o intersticial de game over com cooldown e pré-carrega o próximo ao fechar. |
| Testes | `test/game/arcade_one_test.dart` | Cobre montagem, progressão, spawn, controles, som do motor, colisão, escudo, slow-mo, combo, clamp de dt, morte e restart. |
| Testes | `test/game/entities/ship/ship_test.dart` | Cobre alvo contínuo, dead zone, damping, escudo e limites de velocidade. |
| Testes | `test/game/view/game_page_test.dart` | Cobre rota, parâmetros, volume, overlay, retorno, joystick, banner e intersticial suprimidos com anúncios removidos. |
| Testes | `test/common/services/ads/interstitial_ad_service_test.dart` | Cobre exibição no game over, cooldown, cooldown customizado e descarte. |
| Testes | `test/game/components/` | Cobre comportamento isolado dos componentes Flame, incluindo power-up e explosão. |

## Regras de Negócio Relevantes

- **Velocidade crescente** — `lib/game/arcade_one.dart`: `driftSpeed` começa em `2`, soma `distanceKm * 0.0008` e ganha `deepSpaceSpeedBonus` conforme `deepDifficulty`; o scroll visual multiplica o resultado por `42`.
- **Dificuldade limitada + curva profunda** — `lib/game/arcade_one.dart`: `difficulty` atinge `1` em 3000 km; `deepDifficulty` cobre os 6000 km seguintes e amplia gaps móveis, meteoros e velocidade.
- **Modos de controle distintos** — `lib/game/arcade_one.dart`: touch usa thrust `520` e velocidade máxima `250`; joystick usa `360` e `170`.
- **Input contínuo com dead zone** — `lib/game/entities/ship/ship.dart`: a direção é recalculada por frame com `shipThrustDeadZone`, suavizada por `shipDirectionSmoothing` e a inércia decai por `shipIdleDamping` sem thrust.
- **Soft bounds sem morte** — `lib/game/arcade_one.dart`: a nave nunca morre por tocar a borda; a posição é fixada e a velocidade refletida com `bounceRestitution`.
- **Grace period inicial** — `lib/game/arcade_one.dart`: colisões ficam desativadas por `invulnerabilityGraceSeconds` no começo da rodada e após o restart.
- **Near miss vira combo** — `lib/game/arcade_one.dart`: cada obstáculo só pontua uma vez, a janela dura `comboDurationSeconds` e o ganho de distância é multiplicado por até `maxComboMultiplier`.
- **Escudo absorve um impacto** — `lib/game/arcade_one.dart` e `lib/game/entities/ship/ship.dart`: `consumeShield` remove o obstáculo e concede `shieldInvulnerabilitySeconds`; sem escudo a colisão encerra a rodada.
- **Power-ups nos gaps** — `lib/game/arcade_one.dart`: pickups nascem apenas em paredes estáticas com chance `powerUpSpawnChance`; escudo é booleano e câmera lenta renova o timer.
- **Câmera lenta** — `lib/game/arcade_one.dart`: por `slowMotionDurationSeconds` todo o update usa `slowMotionTimeScale` (0,55) e a tela recebe um tint azul.
- **Morte com hit-stop** — `lib/game/arcade_one.dart`: `endRun` ativa slow motion de morte, gera explosão/shake e revela o overlay após `deathOverlayDelaySeconds`, pausando o engine em seguida.
- **Clamp de frame** — `lib/game/arcade_one.dart`: nenhum update processa `dt` maior que `maxGameUpdateDt` (1/30), evitando teleporte de obstáculos após hitches.
- **Recorde persistente** — `lib/game/arcade_one.dart`: `best_distance_km` só é regravado quando a distância atual supera o valor restaurado.
- **Volume binário** — `lib/game/cubit/audio/audio_cubit.dart`: o toggle alterna exclusivamente entre `0` e `1`, persiste em `audio_volume` e é aplicado a `deathPlayer` e `enginePlayer`; mutar silencia o motor mesmo que o loop já esteja tocando.

## Dependências Externas

- Flame para loop, input, componentes, overlays e cache de imagens.
- `audioplayers` para o loop do motor da nave e o efeito de morte.
- `shared_preferences`, acessado por `StorageService`, para recorde e preferências.
- Google Mobile Ads para o banner e o intersticial em Android e iOS.

## Observações

- `assets/audio/engine_fire.mp3` é pré-carregado na fase de áudio do `PreloadCubit` junto com o efeito de morte; `ArcadeOne` chama `play`/`stop` diretamente no `enginePlayer`, sem passar pelo `AudioCubit`.
- Os arquivos `background.mp3`, `background_2.mp3`, `beyond_the_far_rim.mp3`, `effect.mp3` e `thrust_tap.wav` continuam em `assets/audio/`, mas nenhum é referenciado pelo código.
- O engine é pausado junto com a revelação do overlay de game over; `restartRun` é o único caminho que retoma o loop.
- O burst de explosão dura `particleBurstLifetime` (0,5 s) e é removido no restart para não vazar para a nova rodada.
- O HUD de combo aparece somente com combo maior que 1 e os textos de distância/recorde só são reescritos quando o valor inteiro muda.
- `lib/common/services/shared_preferences_storage_service.dart` e `test/app/cubit/app_locale_cubit_test.dart` tinham alterações locais prévias ao registro `source_commit`.
