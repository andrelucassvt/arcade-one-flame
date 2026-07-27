# Áudio: não cortar a música do celular + som da nave mais suave

> **Objetivo:** O jogo deixa de interromper a música de outros apps (toca por cima/mistura) e o som de motor da nave fica mais suave (fade-in/fade-out + volume reduzido), com a troca futura do asset de áudio já prevista.

## Contexto

Hoje o áudio do jogo usa a configuração padrão do `audioplayers`, que no iOS adota a categoria `playback` (exclusiva) — por isso, ao tocar qualquer som, a música que o usuário ouve em outro app é cortada. Além disso, o som de motor (`engine_fire.mp3`) é tocado em loop com `play()`/`stop()` abruptos e no mesmo volume dos demais efeitos, o que soa áspero (aspereza de início/fim + possível "click" na emenda do loop do mp3). Queremos: (1) configurar uma sessão de áudio que conviva com outros apps; (2) suavizar o motor por código; (3) deixar pronta a troca do arquivo de áudio caso o ruído esteja no próprio asset.

## Descobertas da investigação (verificadas no pub-cache)

- Pacote instalado: `audioplayers 6.4.0` / `audioplayers_platform_interface 7.1.0`.
- API global confirmada: `AudioPlayer.global.setAudioContext(AudioContext(...))` (`GlobalAudioScope.setAudioContext`, em `src/global_audio_scope.dart`). Aplica a TODOS os players que não definem contexto próprio.
- `enginePlayer`, `deathPlayer` e o `AudioPool` de thrust **não** definem contexto próprio → herdam o contexto global. Logo, **basta setar o contexto global uma vez** para cobrir todos.
- ⚠️ Detalhe do iOS (assert em `AudioContextIOS`, `src/api/audio_context.dart:174-185`): com `category: AVAudioSessionCategory.ambient`, o `mixWithOthers` é ativado **automaticamente** e **não pode** ser passado explícito em `options` (o assert dispara). Portanto, para `ambient`, deixar `options` vazio.
- Android: `AndroidAudioFocus.none` faz o app **não** requisitar foco de áudio, permitindo que a música de outro app continue.
- Som do motor: tocado em `lib/game/arcade_one.dart` (`_playEngineSoundIfStillRequested` / `_stopEngineSound`) diretamente no `enginePlayer`, sem ajuste de volume próprio e sem fade.
- Volume: `AudioCubit._changeVolume` aplica `state.volume` igual para `enginePlayer` e `deathPlayer`.

## Arquitetura / Escopo

| Arquivo | Ação | Responsabilidade |
|---------|------|-----------------|
| `lib/bootstrap.dart` | editar | Setar o `AudioContext` global (iOS `ambient`, Android `focus: none`) no bloco "Add cross-flavor configuration here", antes de `runApp`. |
| `lib/game/cubit/audio/audio_cubit.dart` | editar | Novo `engineVolumeFactor` (motor mais baixo que os demais); expor `startEngineLoop()`/`stopEngineLoop()` com fade-in/fade-out; aplicar fator ao `enginePlayer` em `_changeVolume` e `init`. |
| `lib/game/arcade_one.dart` | editar | Trocar o uso direto de `enginePlayer.play/stop` pelos callbacks `startEngineLoop`/`stopEngineLoop` do cubit (mantendo o timer de delay e as travas de game over). |
| `lib/game/view/game_page.dart` | editar | Injetar os novos callbacks de motor no `ArcadeOne` (hoje injeta `enginePlayer` cru e `playThrustTapSound`). |
| `test/game/cubit/audio_cubit_test.dart` | editar | Novos testes do fator de volume e do start/stop do loop de motor (estende o arquivo existente e reutiliza os mocks). |
| `assets/audio/engine_fire.mp3` | (futuro) | Troca do asset, se o ruído estiver no próprio arquivo — fornecido pelo usuário. |
| `flow/game.md` | editar | Atualizar a documentação do fluxo de áudio (itens de contexto global, volume e motor). |

> **Nota de teste:** O bloco "Suavizar por código" mexe na camada de estado (`AudioCubit`) → segue TDD (testes antes da implementação). A configuração de sessão global (Problema 1) é um side-effect de inicialização de plataforma, difícil de cobrir por teste unitário — será validada manualmente em dispositivo (ver Critérios de Sucesso), sem fase de teste automatizado.

## Fases

### Fase 1 — Problema 1: misturar com a música de outros apps

- [ ] Em `lib/bootstrap.dart`, no comentário `// Add cross-flavor configuration here`, adicionar:
  ```dart
  await AudioPlayer.global.setAudioContext(
    AudioContext(
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.ambient,
        // 'ambient' já habilita mixWithOthers automaticamente;
        // passá-lo explícito dispara o assert do pacote.
      ),
      android: AudioContextAndroid(
        isSpeakerphoneOn: false,
        stayAwake: false,
        contentType: AndroidContentType.sonification,
        usageType: AndroidUsageType.game,
        audioFocus: AndroidAudioFocus.none,
      ),
    ),
  );
  ```
- [ ] Adicionar o import `package:audioplayers/audioplayers.dart` em `bootstrap.dart`.
- [ ] Garantir que a chamada ocorre **antes** de `runApp(...)` e antes de qualquer `play()`.
- [ ] Verificação (dispositivo físico): tocar música no Spotify/YouTube Music, abrir o jogo com som ligado, dar thrust e morrer — a música **continua tocando** junto com os sons do jogo (iOS e Android).

### Fase 2 — Problema 2 (testes): contrato do volume e do loop de motor

> Escrever os testes que definem o comportamento. Eles vão falhar até a Fase 3 existir.

- [ ] Em `test/game/cubit/audio_cubit_test.dart`, adicionar `when(() => enginePlayer.play(any(), volume: any(named: 'volume'))).thenAnswer((_) async {})`, `when(() => enginePlayer.setReleaseMode(any())).thenAnswer((_) async {})` e `when(enginePlayer.stop).thenAnswer((_) async {})` no `setUp` (mantendo os mocks atuais).
- [ ] Teste: `startEngineLoop` quando `volume == 1` chama `enginePlayer.setReleaseMode(ReleaseMode.loop)`, toca o asset de motor e atinge o volume-alvo `1 * engineVolumeFactor` (verificar o `setVolume` final com o valor do fator).
- [ ] Teste: `startEngineLoop` quando `volume == 0` (mutado) **não** inicia o som de motor.
- [ ] Teste: `stopEngineLoop` chama `enginePlayer.stop` (após o fade-out).
- [ ] Teste: `toggleVolume`/`_changeVolume` aplica `volume * engineVolumeFactor` no `enginePlayer` e `volume` cheio no `deathPlayer` (ajustar os asserts dos testes existentes `toggleVolume mutes/unmutes` para o motor usar o valor reduzido, não `equals(1)`).
- [ ] Verificação: `flutter test test/game/cubit/audio_cubit_test.dart` compila e os novos testes falham pelos motivos certos (método/fator inexistente), não por erro de sintaxe.

### Fase 3 — Problema 2 (implementação): motor mais suave

- [ ] Em `audio_cubit.dart`, adicionar `static const double engineVolumeFactor = 0.4;` (valor inicial; ajustável depois).
- [ ] Em `_changeVolume` e `init`, aplicar `enginePlayer.setVolume(volume * engineVolumeFactor)` mantendo `deathPlayer.setVolume(volume)` cheio.
- [ ] Implementar `Future<void> startEngineLoop()`: se `state.volume == 0`, retorna; senão `setReleaseMode(ReleaseMode.loop)`, inicia o asset de motor em volume 0 e faz **fade-in** até `state.volume * engineVolumeFactor` (rampa curta via `Timer.periodic`, ~150–250 ms).
- [ ] Implementar `Future<void> stopEngineLoop()`: **fade-out** até 0 e então `enginePlayer.stop()`; cancelar qualquer fade em andamento ao iniciar um novo.
- [ ] Guardar referência do `Timer` de fade no cubit e cancelá-lo em `close()`.
- [ ] Verificação: `flutter test test/game/cubit/audio_cubit_test.dart` — todos passam.

### Fase 4 — Ligar o motor suave ao jogo

- [ ] Em `arcade_one.dart`, substituir `enginePlayer.setReleaseMode(...).then(... enginePlayer.play(...))` (em `_playEngineSoundIfStillRequested`) pela chamada ao callback `startEngineLoop` injetado; substituir `enginePlayer.stop()` (em `_stopEngineSound` e no game over) pelo callback `stopEngineLoop`.
- [ ] Manter intactos o `_engineSoundStartTimer`/`engineSoundStartDelay` e as travas `_isEngineSoundRequested`/`_isEngineSoundPlaying`/`isGameOver`.
- [ ] Adicionar os parâmetros `startEngineLoop`/`stopEngineLoop` ao construtor de `ArcadeOne` (e remover a dependência direta de `enginePlayer` se ela deixar de ser usada — `deathPlayer` permanece).
- [ ] Em `game_page.dart`, passar `startEngineLoop: audioCubit.startEngineLoop` e `stopEngineLoop: audioCubit.stopEngineLoop` ao instanciar `ArcadeOne`.
- [ ] Verificação: `flutter analyze` sem erros e `flutter test` completo verde; em dispositivo, o motor entra/sai com fade suave e o botão de mute continua funcionando.

### Fase 5 — Prever a troca do asset (futuro)

- [ ] Documentar no plano/flow que, se o chiado persistir, a causa é o próprio `assets/audio/engine_fire.mp3` (ruído gravado no arquivo) e **nenhuma mudança de código resolve** — é preciso um novo arquivo reencodado/mais limpo.
- [ ] Quando o usuário fornecer o novo arquivo: substituir `assets/audio/engine_fire.mp3` mantendo o mesmo nome (sem mudar `assets.gen.dart` nem o preload), ou rodar o gerador de assets se o nome mudar.
- [ ] Verificação: rejogar e confirmar que o ruído sumiu.

### Fase 6 — Atualizar Flow

- [ ] Em `flow/game.md`, atualizar:
  - Item de **Áudio global** (passo 21): mencionar que o `bootstrap.dart` agora define `AudioContext` global (iOS `ambient` que mistura com outros apps; Android `focus: none`).
  - Item de **Mudança de volume** (passo ~35/10) e descrição do motor (passos ~40/44): o motor toca com `engineVolumeFactor` (volume reduzido) e com fade-in/fade-out via `startEngineLoop`/`stopEngineLoop` do `AudioCubit`, em vez de `play/stop` direto no `enginePlayer`.

## Critérios de Sucesso

- [ ] Com música tocando em outro app, abrir o jogo com som ligado não corta a música (iOS e Android).
- [ ] O som de motor entra e sai suavemente (sem corte abrupto) e está perceptivelmente mais baixo que o som de morte/efeitos.
- [ ] Botão de mute continua silenciando tudo e o volume persiste entre sessões.
- [ ] `flutter analyze` sem erros e `flutter test` completo passando.

## Riscos e Mitigações

| Risco | Probabilidade | Mitigação |
|-------|--------------|-----------|
| Passar `mixWithOthers` explícito com `ambient` quebra por assert do pacote | Média | Para `ambient`, deixar `options` vazio (já documentado na Fase 1). |
| Fade via `Timer` deixar resíduo de som ou condição de corrida com start/stop rápidos | Média | Cancelar o `Timer` de fade anterior ao iniciar outro e no `close()`; cobrir start/stop por teste. |
| `engineVolumeFactor = 0.4` ficar baixo/alto demais | Baixa | Valor é uma constante única, fácil de calibrar em dispositivo. |
| Ruído estar no próprio asset (código não resolve) | Média | Fase 5 já prevê a troca do arquivo pelo usuário. |
| Som no Android não misturar mesmo com `focus: none` em alguns OEMs | Baixa | Validar em dispositivo real; ajustar `usageType`/`contentType` se necessário. |

## Rollback

Reverter os commits das fases 1–4 (e a troca de asset da fase 5, se feita). As mudanças são localizadas em `bootstrap.dart`, `audio_cubit.dart`, `arcade_one.dart` e `game_page.dart`; restaurar essas versões devolve o comportamento atual de áudio.
