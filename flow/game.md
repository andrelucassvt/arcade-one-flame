# Flow: Game

> **Resumo:** Monta a partida DRIFT em Flame, permite mutar o audio, controla a nave por toque/clique ou joystick virtual, toca som de motor/fogo durante o thrust, toca som de morte no game over e executa background progressivo por KM, pares de asteroides, meteoros soltos, pontuacao por distancia, popup de game over e restart.

## Visão Geral

O fluxo de Game comeca quando `TitleView` navega para `GamePage.route(controlMode: ...)`. O `AudioCubit` ja foi criado globalmente pelo `App` usando o cache de audio do `PreloadCubit`, com players separados para motor/fogo e morte. `GamePage` renderiza `GameView` com o `GameControlMode` selecionado na Title; `GameView` le o cubit global para injetar os players no jogo Flame e para mostrar o botao de volume.

`GameView` nao inicia musica de fundo. Ele cria uma instancia de `ArcadeOne`, injeta l10n, players de audio, estilo de texto e cache de imagens, configura o `GameWidget` com overlay de game over e mantem os controles Flutter dentro de `SafeArea`. O jogo Flame carrega os sprites de jogo e os sprites transparentes de marcos espaciais a partir do cache de imagens, entao monta os componentes principais diretamente na instancia do jogo: `SpaceBackgroundComponent`, `Ship`, `DriftHudComponent` e uma sequencia inicial de paredes com `AsteroidPairComponent`.

Durante a partida em `GameControlMode.touch`, toques e drags na tela ligam o thrust da nave em direcao ao ponteiro. Em `GameControlMode.joystick`, `GameView` sobrepoe `GameJoystick` no `bottomCenter`, com margem inferior que reserva a altura do banner quando ha anuncio configurado; o joystick envia uma direcao normalizada para `ArcadeOne.setJoystickDirection`, que aplica thrust por direcao em vez de alvo de ponteiro. Nesse modo a nave nasce com `joystickShipThrustPower` e `joystickShipMaxSpeed`, deixando a velocidade da nave menor que no modo de toque. Cada inicio de thrust toca imediatamente um SFX curto via `AudioPool`, para que taps rapidos tenham feedback sem cortar o som. O som longo de motor/fogo entra em loop apenas se o input continuar ativo depois de um pequeno atraso. Enquanto o thrust esta ativo, `Ship` anima o sprite da nave com pulso e chama animada; ao soltar, o som de motor/fogo pendente ou ativo para, mas a nave nao para: `Ship` mantem a velocidade acumulada e continua deslizando por inercia. `ArcadeOne.update` incrementa a distancia, calcula a velocidade de scroll, avanca o background progressivo, move a sequencia ativa de obstaculos, verifica colisao com asteroides ou meteoros soltos e encerra a partida se a nave tocar as bordas da tela.

Quando ocorre game over, o jogo marca `isGameOver`, registra a melhor distancia da sessao, para o som de motor/fogo, toca o som de morte e ativa o overlay Flutter de game over. O popup informa que o jogador morreu, mostra a distancia percorrida em KM e oferece botoes para reiniciar a mesma tela ou voltar para a Title.

## Passo a Passo

1. **Origem** — `lib/title/content/title_start_button.dart` -> `TitleStartButton.onPressed`
   O botao Launch chama `Navigator.pushReplacement(GamePage.route(controlMode: controlMode))`, usando a selecao feita em `TitleView`.
2. **Rota** — `lib/game/view/game_page.dart` -> `GamePage.route`
   Cria `MaterialPageRoute<void>` para `GamePage(controlMode: controlMode)`.
3. **Audio global** — `lib/app/view/app.dart` -> `App.build`
   Antes da Game ser aberta, cria `AudioCubit` com dois `AudioPlayer()..audioCache = context.read<PreloadCubit>().audio`: `enginePlayer` para motor/fogo e `deathPlayer` para morte. Tambem cria um `AudioPool` para `assets/audio/thrust_tap.wav`, usado como SFX curto de inicio de thrust.
4. **Shell da Game** — `lib/game/view/game_page.dart` -> `GamePage.build`
   Renderiza `Scaffold(body: GameView(controlMode: controlMode))`, assumindo que `AudioCubit`, `PreloadCubit` e `StorageService` ja existem acima na arvore.
5. **Sem musica de fundo** — `lib/game/view/game_page.dart` -> `GameView`
   A tela nao chama `Bgm` nem toca `Assets.audio.background`; o audio so acontece em resposta a input de thrust ou game over.
6. **Instancia do jogo** — `lib/game/view/game_page.dart` -> `GameView.build`
   Cria `ArcadeOne` com `context.l10n`, `enginePlayer`, `deathPlayer`, callback `AudioCubit.playThrustTap`, `textStyle`, cache de imagens do `PreloadCubit`, `StorageService` e `controlMode`, alem de repassar o padding de `SafeArea` para o HUD Flame.
7. **Renderizacao Flame** — `lib/game/view/game_page.dart` -> `GameWidget`
   Renderiza o `FlameGame` dentro de um `Stack`, registra o overlay `gameOverOverlayKey`, mantem o botao de volume sobreposto no canto superior direito dentro de `SafeArea` e, quando o modo e joystick, mostra `GameJoystick` em `Alignment.bottomCenter`, acima da area reservada ao banner.
8. **Joystick virtual** — `lib/game/widgets/game_joystick.dart` -> `GameJoystick`
   Captura tap/pan dentro da area circular, calcula direcao normalizada com dead zone e chama `ArcadeOne.setJoystickDirection` enquanto ativo ou `ArcadeOne.clearJoystick` ao soltar.
9. **Botao de volume** — `lib/game/view/game_page.dart` -> `BlocBuilder<AudioCubit, AudioState>`
   Mostra `Icons.volume_off` ou `Icons.volume_up` e chama `AudioCubit.toggleVolume`.
10. **Mudanca de volume** — `lib/game/cubit/audio/audio_cubit.dart` -> `toggleVolume`
   Alterna entre volume `0` e `1`, aplicando no player de motor/fogo e no player de morte.
11. **Load do jogo** — `lib/game/arcade_one.dart` -> `ArcadeOne.onLoad`
   Le `best_distance_km` do `StorageService` e inicializa `bestDistanceKm` com o valor persistido (ou `0.0` se nunca salvo). Em seguida chama `_buildRun`, carrega sprites e backgrounds, adiciona `SpaceBackgroundComponent`, `Ship`, `DriftHudComponent` e a primeira sequencia de sete pares de asteroides. Quando `controlMode == GameControlMode.joystick`, a `Ship` recebe thrust e velocidade maxima menores.
12. **Input de thrust por toque** — `lib/game/arcade_one.dart` -> `onTapDown`, `onDragStart`, `onDragUpdate`
    Enquanto a partida esta ativa e `controlMode == GameControlMode.touch`, `onTapDown` e `onDragStart` tocam o SFX curto de thrust via callback do `AudioCubit`. Em seguida, o jogo agenda o inicio de `Assets.audio.engineFire` em loop no `enginePlayer` apos `engineSoundStartDelay` e passa a posicao do toque/drag para `Ship.setThrustTarget`. `onDragUpdate` apenas atualiza o alvo e garante que o loop sustentado continue solicitado.
13. **Input de thrust por joystick** — `lib/game/arcade_one.dart` -> `setJoystickDirection`
    Enquanto a partida esta ativa e `controlMode == GameControlMode.joystick`, o primeiro comando ativo toca o SFX curto, solicita o loop sustentado e passa a direcao do joystick para `Ship.setThrustDirection`.
14. **Soltar input** — `lib/game/arcade_one.dart` -> `onTapUp`, `onTapCancel`, `onDragEnd`, `onDragCancel`, `clearJoystick`
    Cancela o som de motor/fogo se ele ainda estiver pendente, ou para o `enginePlayer` se ele ja estiver tocando, e chama `Ship.clearThrust`, desligando o propulsor sem zerar a velocidade.
15. **Fisica da nave** — `lib/game/entities/ship/ship.dart` -> `Ship.update`
    Aplica aceleracao na direcao do thrust, limita a velocidade por `maxSpeed`, rotaciona a nave suavemente, atualiza a posicao e avanca o tempo da animacao visual quando o thrust esta ativo.
16. **Progressao** — `lib/game/arcade_one.dart` -> `ArcadeOne.update`
    Incrementa `distanceKm`, calcula `driftSpeed = 2 + distanceKm * 0.0008`, deriva `scrollSpeed` e chama `background.advance(scrollSpeed, dt, distanceKm)` para mover o starfield interno e atualizar quais sprites de marcos espaciais aparecem, descem e somem no fundo.
17. **Obstaculos** — `lib/game/components/asteroid_pair_component.dart` e `lib/game/components/loose_meteor_component.dart`
    `ArcadeOne` alterna sequencias de obstaculos sem apagar a sequencia atual. A primeira sequencia e sempre de paredes com sete pares de asteroides; meteoros soltos so podem comecar depois de tres sequencias consecutivas de paredes, entram com chance menor que paredes e nao passam de duas sequencias seguidas. A sequencia anterior continua descendo ate sair da tela naturalmente, enquanto a nova e anexada acima da ultima peca existente, preservando o espacamento em vez de reiniciar no mesmo ponto. Cada par de asteroides move para baixo com o scroll, possui um gap central, reduz o gap conforme a dificuldade aumenta e renderiza uma textura de asteroide quando o sprite esta disponivel. Cada meteoro solto tambem move com o scroll, pode ter drift horizontal leve, renderiza o sprite de meteoro quando disponivel e usa colisao circular.
18. **Colisao e bordas** — `lib/game/arcade_one.dart` -> `_checkBounds`, `AsteroidPairComponent.collidesWith` e `LooseMeteorComponent.collidesWith`
    Tocar nas bordas, intersectar um bloco de asteroide ou bater em um meteoro solto chama `ArcadeOne.endRun`.
19. **Game over** — `lib/game/arcade_one.dart` -> `endRun`
    Marca `isGameOver`. Se `distanceKm > bestDistanceKm`, atualiza `bestDistanceKm` e persiste o novo recorde via `StorageService.setDouble('best_distance_km', ...)`. Para o som de motor/fogo, toca `Assets.audio.death`, limpa o thrust da nave, zera a velocidade e ativa o overlay `gameOverOverlayKey`.
20. **HUD** — `lib/game/components/drift_hud_component.dart` -> `DriftHudComponent.update`
    Atualiza distancia atual e melhor distancia. As mensagens centrais de game over ficam fora do canvas e sao exibidas pelo overlay Flutter.
21. **Popup de game over** — `lib/game/widgets/game_over_popup.dart`
    Exibe `gameOverTitle`, `gameOverMessage`, a distancia percorrida via `gameOverDistanceText`, o botao `restartButtonLabel` e o botao `returnToTitleButtonLabel` dentro de `SafeArea`.
22. **Restart** — `lib/game/view/game_page.dart` -> `GameOverPopup.onRestart` -> `ArcadeOne.restartRun`
    O botao do popup zera a distancia, remove o overlay, reposiciona a nave, remove obstaculos antigos e cria uma nova leva inicial.
23. **Voltar para Title** — `lib/game/view/game_page.dart` -> `GameOverPopup.onReturnToTitle`
    O botao de voltar para a tela inicial chama `Navigator.of(context).pushReplacement(TitleView.route())`, removendo a Game da pilha e abrindo a Title novamente.
24. **Dispose** — `lib/game/cubit/audio/audio_cubit.dart`
    Quando o provider global e descartado, `AudioCubit.close` descarta `enginePlayer`, `deathPlayer` e o `AudioPool` de SFX curto.

### Caminhos alternativos

- **Toque durante game over:** `ArcadeOne.onTapDown` nao aplica thrust; o restart fica centralizado no botao do popup.
- **Soltar o toque durante a partida:** `ArcadeOne` cancela o som de motor/fogo pendente ou para o som ativo, e `Ship.clearThrust` desliga a aceleracao, mas a velocidade atual permanece e a nave continua por inercia.
- **Volume mutado:** `AudioCubit` aplica volume `0` no player de motor/fogo e no player de morte; o SFX curto nao inicia quando o volume esta mutado.
- **Troca de sequencia:** `ArcadeOne.update` remove `AsteroidPairComponent` ou `LooseMeteorComponent` apenas quando eles saem da tela. A proxima sequencia nasce quando a ultima peca da onda atual chega perto do topo e usa a posicao dessa ultima peca como ancora para nao sobrepor paredes nem fechar o corredor.

## Arquivos Envolvidos

| Camada | Arquivo | Responsabilidade |
|--------|---------|------------------|
| Configuracao/App | `lib/app/view/app.dart` | Cria o `AudioCubit` global com `StorageService` e cache de audio do `PreloadCubit`. |
| Apresentacao | `lib/game/view/game_page.dart` | Renderiza `GameWidget`, registra overlay de game over, repassa SafeArea para o HUD e exibe botao de volume usando o `AudioCubit` global. |
| Apresentacao / Widget | `lib/game/widgets/game_joystick.dart` | Joystick virtual menor, posicionado no `bottomCenter` da gameplay acima do banner quando `GameControlMode.joystick` esta ativo. |
| Configuracao de gameplay | `lib/game/game_control_mode.dart` | Enum publico que define os modos `touch` e `joystick`. |
| Servico | `lib/common/services/storage_service.dart` | Interface usada pelo `AudioCubit` (volume) e `ArcadeOne` (melhor distancia) para leitura e escrita de dados persistidos. |
| Jogo Flame | `lib/game/arcade_one.dart` | Classe principal do jogo, input, progressao, spawn, colisao, game over e restart. |
| Assets de audio | `lib/game/game_audio_assets.dart` | Define o caminho manual do SFX curto de thrust usado pelo `AudioPool`. |
| Assets de jogo | `lib/game/game_image_assets.dart` | Define as chaves dos sprites usados pelo cache de imagens do Flame. |
| Cubit | `lib/game/cubit/audio/audio_cubit.dart` | Controla volume, players de motor/fogo e morte, SFX curto de thrust via `AudioPool`, e dispose. |
| Estado | `lib/game/cubit/audio/audio_state.dart` | Guarda o volume atual. |
| Entidade | `lib/game/entities/ship/ship.dart` | Nave, thrust, inercia, velocidade maxima, rotacao, sprite e animacao visual de propulsao. |
| Componente | `lib/game/components/asteroid_pair_component.dart` | Par de asteroides com gap, movimento vertical, sprite opcional e colisao simples. |
| Componente | `lib/game/components/loose_meteor_component.dart` | Meteoro individual com raio, drift horizontal, movimento por scroll, sprite opcional e colisao circular. |
| Background | `lib/game/background/space_landmark.dart` | Modelo imutavel de um marco espacial por distancia. |
| Background | `lib/game/background/space_landmark_catalog.dart` | Catalogo ordenado de marcos e selecao por `distanceKm`. |
| Componente | `lib/game/components/space_background_component.dart` | Fundo progressivo com starfield, imagem ativa, fade entre marcos e fallback procedural. |
| Componente | `lib/game/components/starfield_component.dart` | Fundo espacial procedural com duas velocidades de parallax. |
| Componente | `lib/game/components/drift_hud_component.dart` | HUD de distancia e melhor distancia, reposicionado com padding de SafeArea. |
| Widget | `lib/game/widgets/game_over_popup.dart` | Overlay Flutter de game over com mensagem de morte, botao de restart e botao para voltar a Title. |
| Assets gerados | `assets/images/backgrounds/*.png` | Sprites PNG transparentes dos marcos espaciais exibidos sobre o starfield. |
| Assets gerados | `assets/images/asteroid_tile.png`, `assets/images/loose_meteor.png`, `assets/images/player_ship.png` | Sprites PNG transparentes para paredes de asteroides, meteoros soltos e nave. |
| Assets gerados | `assets/audio/thrust_tap.wav` | SFX curto de inicio de thrust, derivado do motor e usado para taps rapidos. |
| Assets gerados | `lib/gen/assets.gen.dart` | Caminhos tipados para audio de motor/fogo, morte e demais assets. |
| L10n | `lib/l10n/arb/app_en.arb` | Define textos de titulo, distancia, melhor distancia, popup de game over, restart e voltar para Title. |
| Barrel | `lib/game/game.dart` | Exporta view, cubit, entidades, componentes e `ArcadeOne`. |
| Testes | `test/game/arcade_one_test.dart` | Cobre load, distancia, meteoros soltos, game over por borda/meteoro e reset. |
| Testes | `test/game/entities/ship/ship_test.dart` | Cobre thrust, inercia, limite de velocidade e reset da nave. |
| Testes | `test/game/components/asteroid_pair_component_test.dart` | Cobre gap, movimento e colisao dos obstaculos. |
| Testes | `test/game/components/loose_meteor_component_test.dart` | Cobre movimento, offscreen e colisao do meteoro solto. |
| Testes | `test/game/components/drift_hud_component_test.dart` | Cobre textos do HUD vivo e em game over. |
| Testes | `test/game/view/game_page_test.dart` | Cobre rota, renderizacao da tela e botao de volume. |
| Testes | `test/title/view/title_page_test.dart` | Cobre renderizacao do seletor de modo de controle e repasse do modo selecionado para `GamePage.route`. |
| Testes | `test/game/cubit/audio_cubit_test.dart` | Cobre `AudioCubit`. |

## Regras de Negócio Relevantes

- **Modo de controle selecionado na Title** — `lib/game/view/game_page.dart` e `lib/game/game_control_mode.dart`: `GamePage.route` recebe `GameControlMode`; o padrao e `touch`, e o modo `joystick` ativa o controle virtual na tela de gameplay.
- **Thrust direcionado por toque** — `lib/game/arcade_one.dart`: no modo `touch`, `ArcadeOne` envia a posicao do ponteiro para `Ship.setThrustTarget`.
- **Thrust direcionado por joystick** — `lib/game/arcade_one.dart` e `lib/game/widgets/game_joystick.dart`: no modo `joystick`, o canvas ignora tap/drag de gameplay e `GameJoystick` envia direcao normalizada para `Ship.setThrustDirection`.
- **Velocidade menor no joystick** — `lib/game/arcade_one.dart`: no modo `joystick`, a nave usa `joystickShipThrustPower` e `joystickShipMaxSpeed`, reduzindo aceleracao e velocidade maxima da `Ship` sem alterar o scroll do cenario.
- **SFX curto por inicio de thrust** — `lib/game/arcade_one.dart` + `lib/game/cubit/audio/audio_cubit.dart`: `onTapDown`, `onDragStart` e o primeiro comando ativo do joystick tocam `assets/audio/thrust_tap.wav` via `AudioPool`, para que inputs rapidos tenham feedback e possam sobrepor sem cortar o mesmo player.
- **Som de motor/fogo por thrust sustentado** — `lib/game/arcade_one.dart`: `ArcadeOne` toca `Assets.audio.engineFire` em loop apenas se o thrust continuar ativo depois de `engineSoundStartDelay`, e cancela/paralisa o som quando o input termina.
- **Animacao de thrust** — `Ship` pulsa o sprite e desenha uma chama animada enquanto `isThrusting == true`.
- **Inercia real no MVP** — `Ship.clearThrust` nao altera `velocity`; a nave continua deslizando.
- **Velocidade maxima da nave** — `Ship.update` limita `velocity.length` por `maxSpeed`.
- **Pontuacao por distancia** — `ArcadeOne.update` incrementa `distanceKm` enquanto `isGameOver == false`.
- **Marcos no background por distancia** — `SpaceBackgroundComponent` usa `visibleLandmarksForDistance(distanceKm)` para mostrar Terra/Lua, Marte, Cintura de asteroides, Jupiter, Saturno, Urano/Netuno, Cintura de Kuiper, Nebulosa de Orion, Pilares da Criacao, Buraco negro, Andromeda e Quasar como sprites distantes sobre o starfield.
- **Progressao de velocidade** — `driftSpeed = 2 + distanceKm * 0.0008`; `scrollSpeed` usa esse valor multiplicado por uma escala visual.
- **Sequencias continuas de obstaculos** — a partida comeca com sete pares de asteroides. `ArcadeOne` favorece paredes: meteoros soltos so ficam elegiveis depois de tres sequencias consecutivas de paredes, entram com 25% de chance quando elegiveis e sao limitados a duas sequencias seguidas. A troca e antecipada para evitar espacos vazios grandes, e obstaculos antigos continuam visiveis ate sair da tela.
- **Dificuldade por distancia** — `ArcadeOne.difficulty` cresce ate 1 conforme `distanceKm / 3000`; `AsteroidPairComponent` usa isso para reduzir o gap ate `asteroidMinGap`, e `ArcadeOne` usa o mesmo valor para aumentar gradualmente a quantidade, tamanho e drift dos meteoros soltos.
- **Morte por borda** — se o raio de colisao da nave toca qualquer borda da area de jogo, `ArcadeOne.endRun` e chamado.
- **Morte por obstaculo** — colisao da nave contra os retangulos de asteroides ou colisao circular contra meteoros soltos encerra a partida.
- **Som de morte unico** — `ArcadeOne.endRun` ignora chamadas repetidas quando `isGameOver == true`, garantindo que `Assets.audio.death` toque apenas uma vez por morte.
- **Game over congela progressao** — `ArcadeOne.update` retorna cedo quando `isGameOver == true`.
- **Melhor distancia persistida** — `onLoad` carrega `bestDistanceKm` do storage (chave `best_distance_km`); `endRun` salva apenas quando `distanceKm > bestDistanceKm`, mantendo sempre o maior valor entre sessoes.
- **Restart na mesma tela** — apos game over, o botao do popup chama `restartRun` e nao navega para outra tela.
- **Voltar para Title no game over** — `lib/game/view/game_page.dart`: o botao secundario do popup chama `pushReplacement(TitleView.route())`, entao a Game atual e removida da pilha.
- **Volume binario e persistido** — `lib/game/cubit/audio/audio_cubit.dart`: `toggleVolume` alterna apenas entre `0` e `1` e salva o novo valor via `StorageService`; `init()` restaura o volume salvo na criacao do cubit.

## Dependências Externas

- `flame` para `FlameGame`, `GameWidget`, eventos de input, componentes, vetores e renderizacao.
- Flutter GestureDetector/Material para o joystick virtual sobreposto.
- `audioplayers` para `AudioPlayer` e `AudioPool` dos efeitos sonoros.
- `flutter_bloc` para estado do audio.
- `equatable` para igualdade de `AudioState`.

## Observações

- Nave, paredes de asteroides, meteoros soltos e marcos de background usam sprites PNG quando carregados; os componentes mantem fallback procedural em canvas para testes ou falha de carregamento. O starfield continua procedural dentro de `SpaceBackgroundComponent`.
- O melhor score e persistido em `SharedPreferences` via `StorageService` e sobrevive ao fechamento do app.
- `assets/audio/background.mp3` ainda pode existir no projeto, mas nao e carregado nem tocado pelo fluxo de game.
- Obstaculos de satelite em orbita, clusters de detritos, zonas visuais, skins, rewarded ads e compras ficaram fora deste MVP.
