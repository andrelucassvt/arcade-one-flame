# Flow: Game

> **Resumo:** Monta a partida DRIFT em Flame, toca musica de fundo, permite mutar o audio e controla uma nave com thrust, inercia, obstaculos, pontuacao por distancia, game over e restart.

## Visão Geral

O fluxo de Game comeca quando `TitleView` navega para `GamePage.route()`. `GamePage` cria um `AudioCubit` local usando o cache de audio ja carregado pelo `PreloadCubit`, entao renderiza `GameView`.

`GameView` inicia a musica de fundo em `initState`, cria uma instancia de `ArcadeOne` e injeta l10n, player de efeito, estilo de texto e cache de imagens. O jogo Flame monta os componentes principais diretamente na instancia do jogo: `StarfieldComponent`, `Ship`, `DriftHudComponent` e uma sequencia inicial de `AsteroidPairComponent`.

Durante a partida, toques e drags na tela ligam o thrust da nave em direcao ao ponteiro. Ao soltar, a nave nao para: `Ship` mantem a velocidade acumulada e continua deslizando por inercia. `ArcadeOne.update` incrementa a distancia, calcula a velocidade de scroll, move obstaculos, verifica colisao com asteroides e encerra a partida se a nave tocar as bordas da tela.

Quando ocorre game over, o jogo marca `isGameOver`, registra a melhor distancia da sessao, toca o efeito sonoro e o HUD mostra a mensagem de restart. Um novo toque reinicia a mesma tela, reposicionando a nave e recriando os obstaculos.

## Passo a Passo

1. **Origem** — `lib/title/view/title_page.dart` -> `TitleView.onPressed`
   O botao Launch chama `Navigator.pushReplacement(GamePage.route())`.
2. **Rota** — `lib/game/view/game_page.dart` -> `GamePage.route`
   Cria `MaterialPageRoute<void>` para `GamePage`.
3. **Audio local** — `lib/game/view/game_page.dart` -> `GamePage.build`
   Cria `AudioCubit` com `AudioPlayer()..audioCache = context.read<PreloadCubit>().audio` e `Bgm(audioCache: audioCache)`.
4. **Musica de fundo** — `lib/game/view/game_page.dart` -> `GameView.initState`
   Le `bgm` do `AudioCubit` e chama `bgm.play(Assets.audio.background)`.
5. **Instancia do jogo** — `lib/game/view/game_page.dart` -> `GameView.build`
   Cria `ArcadeOne` com `context.l10n`, `effectPlayer`, `textStyle` e cache de imagens do `PreloadCubit`.
6. **Renderizacao Flame** — `lib/game/view/game_page.dart` -> `GameWidget`
   Renderiza o `FlameGame` dentro de um `Stack` e mantem o botao de volume sobreposto no canto superior direito.
7. **Botao de volume** — `lib/game/view/game_page.dart` -> `BlocBuilder<AudioCubit, AudioState>`
   Mostra `Icons.volume_off` ou `Icons.volume_up` e chama `AudioCubit.toggleVolume`.
8. **Mudanca de volume** — `lib/game/cubit/audio/audio_cubit.dart` -> `toggleVolume`
   Alterna entre volume `0` e `1`, aplicando no player de efeito e no player de BGM.
9. **Load do jogo** — `lib/game/arcade_one.dart` -> `ArcadeOne.onLoad`
   Chama `_buildRun`, adicionando `StarfieldComponent`, `Ship`, `DriftHudComponent` e quatro pares iniciais de asteroides.
10. **Input de thrust** — `lib/game/arcade_one.dart` -> `onTapDown`, `onDragStart`, `onDragUpdate`
    Enquanto a partida esta ativa, passa a posicao do toque/drag para `Ship.setThrustTarget`.
11. **Soltar input** — `lib/game/arcade_one.dart` -> `onTapUp`, `onTapCancel`, `onDragEnd`, `onDragCancel`
    Chama `Ship.clearThrust`, desligando o propulsor sem zerar a velocidade.
12. **Fisica da nave** — `lib/game/entities/ship/ship.dart` -> `Ship.update`
    Aplica aceleracao na direcao do thrust, limita a velocidade por `maxSpeed`, rotaciona a nave suavemente e atualiza a posicao.
13. **Progressao** — `lib/game/arcade_one.dart` -> `ArcadeOne.update`
    Incrementa `distanceKm`, calcula `driftSpeed = 2 + distanceKm * 0.0008`, deriva `scrollSpeed` e avanca o starfield.
14. **Obstaculos** — `lib/game/components/asteroid_pair_component.dart`
    Cada par de asteroides move para baixo com o scroll, possui um gap central e reduz o gap conforme a dificuldade aumenta.
15. **Colisao e bordas** — `lib/game/arcade_one.dart` -> `_checkBounds` e `AsteroidPairComponent.collidesWith`
    Tocar nas bordas ou intersectar um bloco de asteroide chama `ArcadeOne.endRun`.
16. **Game over** — `lib/game/arcade_one.dart` -> `endRun`
    Marca `isGameOver`, atualiza `bestDistanceKm`, toca `Assets.audio.effect` e limpa o thrust da nave.
17. **HUD** — `lib/game/components/drift_hud_component.dart` -> `DriftHudComponent.update`
    Atualiza distancia atual, melhor distancia e, quando `isGameOver == true`, mostra `gameOverTitle` e `restartHint`.
18. **Restart** — `lib/game/arcade_one.dart` -> `onTapDown` e `restartRun`
    Se o jogo esta em game over, um toque zera a distancia, reposiciona a nave, remove obstaculos antigos e cria uma nova leva inicial.
19. **Dispose** — `lib/game/view/game_page.dart` e `lib/game/cubit/audio/audio_cubit.dart`
    `GameView.dispose` pausa o BGM; `AudioCubit.close` descarta `effectPlayer` e `bgm`.

### Caminhos alternativos

- **Toque durante game over:** `ArcadeOne.onTapDown` nao aplica thrust; chama `restartRun`.
- **Soltar o toque durante a partida:** `Ship.clearThrust` desliga a aceleracao, mas a velocidade atual permanece e a nave continua por inercia.
- **Volume mutado:** `AudioCubit` aplica volume `0` no player de efeito e no player de BGM; eventos ainda chamam `play`, mas sem volume audivel.
- **Obstaculo fora da tela:** `ArcadeOne.update` remove o `AsteroidPairComponent` da lista e da arvore Flame.

## Arquivos Envolvidos

| Camada | Arquivo | Responsabilidade |
|--------|---------|------------------|
| Apresentacao | `lib/game/view/game_page.dart` | Cria o `AudioCubit`, inicia BGM, renderiza `GameWidget` e botao de volume. |
| Jogo Flame | `lib/game/arcade_one.dart` | Classe principal do jogo, input, progressao, spawn, colisao, game over e restart. |
| Cubit | `lib/game/cubit/audio/audio_cubit.dart` | Controla volume, players de audio e dispose. |
| Estado | `lib/game/cubit/audio/audio_state.dart` | Guarda o volume atual. |
| Entidade | `lib/game/entities/ship/ship.dart` | Nave, thrust, inercia, velocidade maxima, rotacao e renderizacao pixelada. |
| Componente | `lib/game/components/asteroid_pair_component.dart` | Par de asteroides com gap, movimento vertical e colisao simples. |
| Componente | `lib/game/components/starfield_component.dart` | Fundo espacial procedural com duas velocidades de parallax. |
| Componente | `lib/game/components/drift_hud_component.dart` | HUD de distancia, melhor distancia e mensagens de game over/restart. |
| Assets gerados | `lib/gen/assets.gen.dart` | Caminhos tipados para audio usado por BGM e efeito de colisao. |
| L10n | `lib/l10n/arb/app_en.arb` | Define textos de titulo, distancia, melhor distancia, game over e restart. |
| Barrel | `lib/game/game.dart` | Exporta view, cubit, entidades, componentes e `ArcadeOne`. |
| Testes | `test/game/arcade_one_test.dart` | Cobre load, distancia, game over por borda e reset. |
| Testes | `test/game/entities/ship/ship_test.dart` | Cobre thrust, inercia, limite de velocidade e reset da nave. |
| Testes | `test/game/components/asteroid_pair_component_test.dart` | Cobre gap, movimento e colisao dos obstaculos. |
| Testes | `test/game/components/drift_hud_component_test.dart` | Cobre textos do HUD vivo e em game over. |
| Testes | `test/game/view/game_page_test.dart` | Cobre rota, renderizacao da tela e botao de volume. |
| Testes | `test/game/cubit/audio_cubit_test.dart` | Cobre `AudioCubit`. |

## Regras de Negócio Relevantes

- **Thrust direcionado por toque** — `ArcadeOne` envia a posicao do ponteiro para `Ship.setThrustTarget`.
- **Inercia real no MVP** — `Ship.clearThrust` nao altera `velocity`; a nave continua deslizando.
- **Velocidade maxima da nave** — `Ship.update` limita `velocity.length` por `maxSpeed`.
- **Pontuacao por distancia** — `ArcadeOne.update` incrementa `distanceKm` enquanto `isGameOver == false`.
- **Progressao de velocidade** — `driftSpeed = 2 + distanceKm * 0.0008`; `scrollSpeed` usa esse valor multiplicado por uma escala visual.
- **Dificuldade por distancia** — `ArcadeOne.difficulty` cresce ate 1 conforme `distanceKm / 3000`; `AsteroidPairComponent` usa isso para reduzir o gap ate `asteroidMinGap`.
- **Morte por borda** — se o raio de colisao da nave toca qualquer borda da area de jogo, `ArcadeOne.endRun` e chamado.
- **Morte por obstaculo** — colisao circular simples da nave contra os retangulos de asteroides encerra a partida.
- **Game over congela progressao** — `ArcadeOne.update` retorna cedo quando `isGameOver == true`.
- **Melhor distancia da sessao** — `endRun` atualiza `bestDistanceKm` com o maior valor entre a melhor distancia anterior e a distancia atual.
- **Restart na mesma tela** — apos game over, `onTapDown` chama `restartRun` e nao navega para outra tela.
- **Volume binario** — `lib/game/cubit/audio/audio_cubit.dart`: `toggleVolume` alterna apenas entre `0` e `1`.

## Dependências Externas

- `flame` para `FlameGame`, `GameWidget`, eventos de input, componentes, vetores e renderizacao.
- `flame_audio` para `Bgm`.
- `audioplayers` para efeito sonoro.
- `flutter_bloc` para estado do audio.
- `equatable` para igualdade de `AudioState`.

## Observações

- O MVP usa formas desenhadas em canvas para nave, asteroides e starfield; nao depende de novos assets visuais.
- O melhor score fica apenas em memoria na instancia de `ArcadeOne`; ainda nao ha persistencia local.
- Obstaculos de satelite em orbita, clusters de detritos, zonas visuais, skins, rewarded ads e compras ficaram fora deste MVP.
