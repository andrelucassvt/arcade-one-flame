# BGM em Loop + Remoção do Som de Thrust Tap

> **Objetivo:** Substituir o SFX de toque na nave (thrust tap) por silêncio, e adicionar `beyond_the_far_rim.mp3` como música de fundo em loop durante a gameplay, silenciável pelo mesmo botão de volume existente.

## Contexto

O `AudioCubit` atual gerencia três fontes de áudio: `enginePlayer` (loop do motor durante thrust sustentado), `deathPlayer` (som de morte no game over) e `AudioPool` de thrust tap (SFX curto ao tocar a nave). O usuário quer remover completamente o SFX curto de toque, e adicionar uma música de fundo em loop que começa com a GamePage e termina quando o jogador volta ao título. O botão de volume existente já alterna `volume` entre `0` e `1`; a BGM deve respeitar esse mesmo estado sem nenhuma mudança na UI.

## Arquitetura / Escopo

| Arquivo | Ação | Responsabilidade |
|---------|------|-----------------|
| `lib/game/game_audio_assets.dart` | modificar | Trocar `thrustTapAudioAsset` por `bgmAudioAsset` |
| `lib/game/cubit/audio/audio_cubit.dart` | modificar | Remover `thrustTapPool`/`playThrustTap`; adicionar `bgmPlayer`, `startBgm`, `stopBgm` |
| `lib/app/view/app.dart` | modificar | Remover `AudioPool.create`; passar `bgmPlayer` ao `AudioCubit` |
| `lib/game/view/game_page.dart` | modificar | Remover callback `playThrustTapSound`; iniciar/parar BGM no ciclo de vida de `_GameViewState` |
| `lib/game/arcade_one.dart` | modificar | Remover parâmetro `playThrustTapSound` e todas as chamadas |
| `test/game/cubit/audio_cubit_test.dart` | modificar | Remover testes de thrust tap; adicionar testes de BGM |
| `test/game/arcade_one_test.dart` | modificar | Remover contadores e asserções de `thrustTapSoundCount` |

## Fases

### Fase 1 — Testes (contrato antes da implementação)

> Escreva os testes que definem o comportamento esperado. Eles vão falhar inicialmente — isso é intencional.

**`test/game/cubit/audio_cubit_test.dart`**

- [ ] Remover: `_MockAudioPool`, variável `thrustTapPool`, setup e teardown relacionados, grupo `playThrustTap`, asserção de `dispose` do pool
- [ ] Adicionar mock `_MockAudioPlayer` para `bgmPlayer` (já existe mock para os outros players — seguir o mesmo padrão)
- [ ] Adicionar teste: `startBgm` chama `bgmPlayer.setReleaseMode(ReleaseMode.loop)` e `bgmPlayer.play(AssetSource(bgmAudioAsset))` com o volume atual
- [ ] Adicionar teste: `startBgm` não inicia quando volume é `0` (mudo)
- [ ] Adicionar teste: `stopBgm` chama `bgmPlayer.stop()`
- [ ] Adicionar teste: `toggleVolume` (desmutar) aplica o novo volume no `bgmPlayer` via `setVolume`
- [ ] Adicionar teste: `toggleVolume` (mutar) aplica `0` no `bgmPlayer` via `setVolume`
- [ ] Adicionar teste: `close` faz `bgmPlayer.dispose()`
- [ ] Verificação: todos os novos testes compilam e **falham** pelos motivos certos (símbolo não existe ainda)

**`test/game/arcade_one_test.dart`**

- [ ] Remover: variável `thrustTapSoundCount`, closure `playThrustTapSound: () async { thrustTapSoundCount += 1; }` do construtor de `ArcadeOne`
- [ ] Remover: `expect(thrustTapSoundCount, ...)` nas linhas ~398, ~425, ~430, ~447
- [ ] Verificação: arquivo ainda compila sem erros de lint (exceto falha esperada por parâmetro ainda existente em `ArcadeOne`)

### Fase 2 — Implementação do AudioCubit

- [ ] **`lib/game/game_audio_assets.dart`**: renomear `thrustTapAudioAsset` → remover e adicionar `const String bgmAudioAsset = 'assets/audio/beyond_the_far_rim.mp3';`
- [ ] **`lib/game/cubit/audio/audio_cubit.dart`**:
  - Remover: campo `_thrustTapPool`, parâmetro `thrustTapPool` dos dois construtores, método `playThrustTap`, método `_disposeThrustTapPool` e sua chamada em `close`
  - Adicionar: campo `final AudioPlayer bgmPlayer` com `required` nos dois construtores
  - Adicionar: `bool _isBgmPlaying = false;`
  - Adicionar método `startBgm()`: retorna cedo se `state.volume == 0`; chama `bgmPlayer.setReleaseMode(ReleaseMode.loop)` e `bgmPlayer.play(AssetSource(bgmAudioAsset), volume: state.volume)`; marca `_isBgmPlaying = true`
  - Adicionar método `stopBgm()`: chama `bgmPlayer.stop()`; marca `_isBgmPlaying = false`
  - Atualizar `_changeVolume`: chamar `await bgmPlayer.setVolume(volume)` junto com os outros players
  - Atualizar `close`: chamar `await bgmPlayer.dispose()`
- [ ] Verificação: testes de BGM passam; testes de thrust tap foram removidos; testes restantes passam

### Fase 3 — Limpeza do AudioCubit no App e ArcadeOne

- [ ] **`lib/app/view/app.dart`**: remover `AudioPool.create(source: AssetSource(thrustTapAudioAsset), ...)` e o import de `game_audio_assets.dart` se ficar órfão; adicionar `bgmPlayer: AudioPlayer()..audioCache = preloadCubit.audio` na criação de `AudioCubit`
- [ ] **`lib/game/arcade_one.dart`**: remover o parâmetro `playThrustTapSound` (definição e campo), remover o tipo `PlayThrustTapSound`, remover chamadas `unawaited(playThrustTapSound())` em `onTapDown`, `onDragStart` e `setJoystickDirection`; manter `startEngineLoop`/`stopEngineLoop` intactos
- [ ] Verificação: `dart analyze` sem erros, `flutter test` passa

### Fase 4 — Ciclo de vida da BGM na GameView

- [ ] **`lib/game/view/game_page.dart`**:
  - Adicionar campo `AudioCubit? _audioCubit` em `_GameViewState`
  - Sobrescrever `didChangeDependencies`: na primeira chamada (`_audioCubit == null`), fazer `_audioCubit = context.read<AudioCubit>(); unawaited(_audioCubit!.startBgm());`
  - Sobrescrever `dispose`: chamar `unawaited(_audioCubit?.stopBgm())` antes de `super.dispose()`
  - Remover `playThrustTapSound: audioCubit.playThrustTap` da criação de `ArcadeOne`
- [ ] Verificação: BGM começa ao entrar na GamePage, para ao voltar para a Title, persiste pelo restart (não reinicia ao clicar em "reiniciar" pois a GameView não é descartada)

## Critérios de Sucesso

- [ ] Nenhum som ao tocar/clicar na nave (thrust tap removido)
- [ ] `beyond_the_far_rim.mp3` toca em loop assim que a gameplay começa
- [ ] Botão de volume muta/desmuta tanto a BGM quanto os sons de motor e morte
- [ ] Volume persistido pelo `StorageService` — se o jogo for reaberto mudo, a BGM não começa
- [ ] BGM para ao voltar para a Title
- [ ] BGM não reinicia ao clicar em "Reiniciar" (mesma instância de `_GameViewState`)
- [ ] `flutter test` passa sem erros
- [ ] `dart analyze` sem warnings novos

## Riscos e Mitigações

| Risco | Probabilidade | Mitigação |
|-------|--------------|-----------|
| `didChangeDependencies` chamado múltiplas vezes e BGM iniciada em duplicata | Baixa | Guard `_audioCubit == null` garante inicialização única |
| BGM não para ao navegar de volta (Navigator pop) | Baixa | `dispose` de `_GameViewState` é chamado pelo Flutter ao fazer pop da rota; `stopBgm` ali garante parada |
| Delay de carregamento no primeiro play do arquivo grande | Média | `audioplayers` carrega de forma assíncrona; o loop começa assim que o buffer estiver pronto — aceitável para música de fundo |
| Testes do `arcade_one_test.dart` testavam comportamento de som que é removido | Baixa | Remover asserções de contagem de thrust tap; comportamento do motor/fogo permanece testado |

## Rollback

Reverter os commits desta branch. Não há mudanças de schema, persistência ou assets externos — tudo é código Dart e Dart testes.

---

## Após a Implementação

Atualizar `./flow/game.md`:
- Seção **Passo a Passo**: remover passo 6 atual ("Sem música de fundo") e substituir por descrição do BGM; atualizar passos 4, 7 e 11 para refletir remoção do thrust tap pool e adição do bgmPlayer
- Seção **Arquivos Envolvidos**: atualizar linha de `audio_cubit.dart` e `game_audio_assets.dart`
- Seção **Regras de Negócio**: remover item "SFX curto por início de thrust"; adicionar item "BGM em loop durante gameplay"
