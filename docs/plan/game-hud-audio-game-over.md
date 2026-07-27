# Melhoria do HUD, Audio e Game Over

> **Objetivo:** Ajustar a experiencia do jogo removendo musica de fundo, tocando som de motor/fogo durante o thrust, tocando som de morte no game over, protegendo elementos visuais com SafeArea e exibindo um popup de morte com acao de reiniciar.

## Contexto

O flow atual de `Game` mostra que `GameView` inicia musica de fundo com `Bgm`, `AudioCubit` controla volume de BGM e efeito, e `ArcadeOne.endRun` toca `Assets.audio.effect` ao morrer. O HUD atual e um componente Flame (`DriftHudComponent`) que desenha distancia, melhor distancia e mensagens de game over diretamente no canvas. A melhoria solicitada muda comportamento de audio e estado visual de game over, incluindo um som de morte dedicado, entao deve ser tratada como mudanca de logica com testes antes da implementacao.

## Arquitetura / Escopo

| Arquivo | Acao | Responsabilidade |
|---------|------|-----------------|
| `test/game/cubit/audio_cubit_test.dart` | modificar | Definir contrato sem BGM: volume deve afetar players de motor/fogo e morte, e `close` deve descartar todos os players. |
| `test/game/arcade_one_test.dart` | modificar | Cobrir som de motor/fogo no inicio do thrust, parada do som ao soltar input, som de morte em game over e chamada de overlay de morte. |
| `test/game/view/game_page_test.dart` | modificar | Cobrir que `GameView` nao inicia musica de fundo, renderiza overlay em SafeArea e aciona restart pelo popup. |
| `lib/game/cubit/audio/audio_cubit.dart` | modificar | Remover dependencia de `Bgm` e centralizar players de som do jogo: motor/fogo e morte. |
| `lib/game/cubit/audio/audio_state.dart` | manter/modificar | Manter estado de volume binario; ajustar apenas se o novo contrato de audio exigir nomes mais claros. |
| `lib/game/arcade_one.dart` | modificar | Disparar som de motor/fogo quando thrust comeca, parar quando thrust termina, tocar som de morte e acionar overlay de game over. |
| `lib/game/view/game_page.dart` | modificar | Parar de tocar BGM em `initState`, criar os novos players, configurar `GameWidget.overlayBuilderMap` e aplicar SafeArea nos overlays visuais. |
| `lib/game/components/drift_hud_component.dart` | modificar | Manter distancia/melhor distancia no canvas ou remover textos de game over, deixando o popup Flutter como unica mensagem de morte. |
| `lib/game/widgets/game_over_popup.dart` | criar | Popup visual em Flutter com textos via l10n e botao de reiniciar. |
| `lib/l10n/arb/app_en.arb` | modificar | Adicionar textos localizados para popup de morte e botao de restart se os textos existentes nao forem suficientes. |
| `assets/audio/engine_fire.mp3` | criar/adicionar | Asset curto de motor/fogo usado durante o thrust. Se o asset final ainda nao existir, usar temporariamente `assets/audio/effect.mp3` apenas durante a implementacao local. |
| `assets/audio/death.mp3` | criar/adicionar | Asset curto de morte tocado uma unica vez quando a partida entra em game over. |
| `lib/gen/assets.gen.dart` | gerar | Atualizar paths tipados dos assets apos adicionar o audio novo. |
| `flow/game.md` | modificar | Atualizar a documentacao do fluxo para remover BGM e descrever audio de thrust, som de morte, SafeArea e popup de game over. |

## Fases

### Fase 1 — Testes de Audio e Estado do Game

> Escreva os testes que definem o comportamento esperado. Eles vao falhar inicialmente - isso e intencional.

- [ ] Atualizar `test/game/cubit/audio_cubit_test.dart` para instanciar `AudioCubit` com `enginePlayer` e `deathPlayer`, sem `Bgm`.
- [ ] Testar que `toggleVolume()` aplica volume `0` e `1` nos dois players de efeito.
- [ ] Testar que `AudioCubit.close()` descarta `enginePlayer` e `deathPlayer`.
- [ ] Atualizar `test/game/arcade_one_test.dart` para verificar que `onTapDown` durante uma partida ativa toca o som de motor/fogo.
- [ ] Atualizar `test/game/arcade_one_test.dart` para verificar que `onTapUp`, `onTapCancel`, `onDragEnd` e `onDragCancel` param o som de motor/fogo.
- [ ] Atualizar `test/game/arcade_one_test.dart` para verificar que `endRun()` para o motor/fogo, toca `Assets.audio.death` uma unica vez e solicita o overlay de game over.
- [ ] Verificacao: os testes compilam e falham por falta das novas APIs/comportamentos, nao por erro de sintaxe.

### Fase 2 — Testes de UI, SafeArea e Popup

> Completar o contrato visual antes de mexer na tela.

- [ ] Atualizar `test/game/view/game_page_test.dart` para garantir que `GameView` nao chama `bgm.play(Assets.audio.background)`.
- [ ] Testar que o botao de volume continua dentro de `SafeArea`.
- [ ] Testar que o overlay de game over renderiza um popup com titulo de morte e acao de restart usando textos de l10n.
- [ ] Testar que tocar no botao do popup chama `restartRun()` e remove o overlay de game over.
- [ ] Verificacao: testes de widget falham inicialmente pela ausencia do overlay/popup e pela dependencia atual de BGM.

### Fase 3 — Refatorar Audio Sem Musica de Fundo

- [ ] Modificar `lib/game/cubit/audio/audio_cubit.dart` para remover `Bgm backgroundMusic` e expor `enginePlayer` e `deathPlayer`.
- [ ] Ajustar `AudioCubit.toggleVolume()` para aplicar volume nos dois players de efeito.
- [ ] Ajustar `AudioCubit.close()` para descartar `enginePlayer` e `deathPlayer`.
- [ ] Modificar `lib/game/view/game_page.dart` para remover `bgm`, `initState()` com `bgm.play(Assets.audio.background)` e `dispose()` com `bgm.pause()`.
- [ ] Modificar `GamePage.build` para criar dois `AudioPlayer()` com `audioCache` do `PreloadCubit`.
- [ ] Verificacao: `flutter test test/game/cubit/audio_cubit_test.dart test/game/view/game_page_test.dart` passa nos cenarios de audio removido.

### Fase 4 — Sons de Motor/Fogo e Morte

- [ ] Adicionar `assets/audio/engine_fire.mp3` em `assets/audio/` e atualizar a geracao de assets para expor `Assets.audio.engineFire`.
- [ ] Adicionar `assets/audio/death.mp3` em `assets/audio/` e atualizar a geracao de assets para expor `Assets.audio.death`.
- [ ] Modificar `lib/game/arcade_one.dart` para receber `enginePlayer` e `deathPlayer` no construtor, substituindo o `effectPlayer` unico.
- [ ] Implementar um metodo interno em `ArcadeOne` para iniciar o som de motor/fogo somente quando o thrust comeca, evitando reiniciar o audio a cada `onDragUpdate`.
- [ ] Implementar um metodo interno em `ArcadeOne` para parar o som de motor/fogo quando o usuario solta/cancela o input ou quando `endRun()` e chamado.
- [ ] Tocar o som de morte em `endRun()` usando `deathPlayer.play(AssetSource(Assets.audio.death))`, garantindo que chamadas repetidas de `endRun()` nao repitam o som.
- [ ] Verificacao: `flutter test test/game/arcade_one_test.dart test/game/cubit/audio_cubit_test.dart` passa nos cenarios de audio de thrust e morte.

### Fase 5 — HUD Seguro e Popup de Game Over

- [ ] Criar `lib/game/widgets/game_over_popup.dart` com um widget publico, textos via `context.l10n`, botao de restart e layout responsivo dentro de `SafeArea`.
- [ ] Modificar `lib/game/view/game_page.dart` para configurar `GameWidget.overlayBuilderMap` com uma chave constante de overlay de game over.
- [ ] Modificar `lib/game/arcade_one.dart` para adicionar o overlay no `endRun()` e remover no `restartRun()`.
- [ ] Ajustar `lib/game/components/drift_hud_component.dart` para remover os textos centrais de game over, evitando duplicidade com o popup.
- [ ] Garantir que os elementos Flutter sobrepostos em `GameView` fiquem dentro de `SafeArea`, incluindo botao de volume e popup.
- [ ] Verificacao: ao morrer, aparece apenas o popup de morte; tocar em reiniciar reseta a partida e fecha o popup.

### Fase 6 — Localizacao, Geracao e Validacao

- [ ] Adicionar ou reaproveitar chaves em `lib/l10n/arb/app_en.arb` para titulo do popup e botao de reiniciar, sem strings hardcoded na UI.
- [ ] Rodar `flutter gen-l10n` se as chaves de l10n forem alteradas.
- [ ] Rodar geracao de assets usada pelo projeto apos adicionar `assets/audio/engine_fire.mp3`.
- [ ] Rodar `dart format` nos arquivos Dart modificados.
- [ ] Rodar `flutter analyze`.
- [ ] Rodar `flutter test test/game`.
- [ ] Verificacao: analise estatica e testes do modulo de game passam sem regressao.

### Fase 7 — Atualizar Flow

- [ ] Atualizar `flow/game.md` para remover a etapa de musica de fundo em `GameView.initState`.
- [ ] Atualizar `flow/game.md` para documentar `AudioCubit` com players de motor/fogo e colisao.
- [ ] Atualizar `flow/game.md` para documentar que `ArcadeOne` inicia/para som de motor durante thrust.
- [ ] Atualizar `flow/game.md` para documentar que game over abre overlay/popup em `GameWidget` e o restart acontece pelo botao do popup.
- [ ] Verificacao: o flow reflete a ordem real UI -> GameWidget overlay -> ArcadeOne -> AudioCubit/assets.

## Criterios de Sucesso

- [ ] Nao existe musica de fundo tocando ao entrar no jogo.
- [ ] Ao pressionar/arrastar para controlar a nave, toca som de motor/fogo; ao soltar, o som para.
- [ ] Ao morrer, o som de thrust para e o som de morte toca uma unica vez.
- [ ] Elementos visuais sobrepostos ao game respeitam `SafeArea`.
- [ ] Game over exibe popup informando a morte e oferecendo reinicio.
- [ ] Tocar em reiniciar no popup reseta a partida sem sair da tela.
- [ ] UI nao possui strings hardcoded; textos passam por l10n.
- [ ] Build sem erros.
- [ ] Todos os testes unitarios e de widget do modulo de game passando.

## Riscos e Mitigacoes

| Risco | Probabilidade | Mitigacao |
|-------|--------------|-----------|
| O som de motor reiniciar muitas vezes durante drag e gerar cortes audiveis. | Media | Controlar um boolean interno em `ArcadeOne` para tocar apenas na transicao sem thrust -> com thrust. |
| Um unico `AudioPlayer` interromper morte ou engine quando sons se sobrepoem. | Media | Separar `enginePlayer` e `deathPlayer` no `AudioCubit`. |
| O popup bloquear o toque de restart atual no canvas de forma inconsistente. | Baixa | Centralizar o restart no botao do popup e remover o overlay dentro de `restartRun()`. |
| SafeArea do Flutter nao afetar componentes Flame dentro do canvas. | Media | Aplicar SafeArea nos overlays Flutter e manter o HUD Flame apenas para informacoes que podem ficar dentro da area util configurada. |
| Asset `engine_fire.mp3` nao estar disponivel no momento da implementacao. | Media | Usar `assets/audio/effect.mp3` temporariamente para validar fluxo tecnico e trocar pelo asset final antes da entrega. |

## Rollback

Reverter as alteracoes em `lib/game/**`, `test/game/**`, `lib/l10n/arb/app_en.arb`, `assets/audio/engine_fire.mp3`, `assets/audio/death.mp3`, `lib/gen/assets.gen.dart` e `flow/game.md`. Restaurar o uso anterior de `Bgm` em `GameView.initState` e `AudioCubit` se a remocao da musica de fundo precisar ser desfeita.
