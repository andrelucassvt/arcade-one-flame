# Persistência Local (Idioma, Melhor KM, Som)

> **Objetivo:** Persistir localmente o idioma selecionado, a melhor distância em KM e o estado de som (ativado/desativado) usando `shared_preferences`, para que os dados sobrevivam ao fechamento do app.

## Contexto

Hoje os três dados vivem apenas em memória: `AppLocaleCubit` esquece o idioma ao reiniciar; `AudioCubit` sempre inicia com volume 1; `ArcadeOne.bestDistanceKm` é zerado a cada nova sessão do app. O projeto não possui nenhum serviço de storage nem a dependência `shared_preferences`. A persistência exige um `StorageService` (interface + implementação), inicialização assíncrona no bootstrap, e adaptação de três componentes existentes para ler/salvar dados.

## Arquitetura / Escopo

| Arquivo | Ação | Responsabilidade |
|---------|------|-----------------|
| `pubspec.yaml` | modificar | Adicionar dependência `shared_preferences` |
| `lib/common/services/storage_service.dart` | criar | Interface abstrata `StorageService` — contrato de leitura/escrita |
| `lib/common/services/shared_preferences_storage_service.dart` | criar | Implementação concreta com `SharedPreferences` |
| `lib/bootstrap.dart` | modificar | Inicializar `SharedPreferences` antes de `runApp`; repassar ao builder |
| `lib/main_development.dart` | modificar | Assinar nova assinatura do `bootstrap` |
| `lib/main_staging.dart` | modificar | Assinar nova assinatura do `bootstrap` |
| `lib/main_production.dart` | modificar | Assinar nova assinatura do `bootstrap` |
| `lib/app/view/app.dart` | modificar | Receber `SharedPreferences`, criar `StorageService` e expor como `RepositoryProvider<StorageService>` acima do `MultiBlocProvider`; injetar em `AppLocaleCubit` |
| `lib/app/cubit/app_locale_cubit.dart` | modificar | Receber `StorageService`, carregar locale salvo no `init()`, salvar na troca |
| `lib/game/cubit/audio/audio_cubit.dart` | modificar | Receber `StorageService`, carregar volume salvo no `init()`, salvar ao `toggleVolume` |
| `lib/game/view/game_page.dart` | modificar | Passar `StorageService` ao `AudioCubit` e a `ArcadeOne` |
| `lib/game/arcade_one.dart` | modificar | Receber `StorageService`, ler `bestDistanceKm` no `onLoad`, salvar no `endRun` |
| `test/common/services/storage_service_test.dart` | criar | Testes do `SharedPreferencesStorageService` |
| `test/app/cubit/app_locale_cubit_test.dart` | criar | Testes de carregamento e persistência do locale |
| `test/game/cubit/audio_cubit_test.dart` | modificar | Adicionar testes de carregamento e persistência do volume |
| `test/game/arcade_one_test.dart` | modificar | Adicionar testes de carregamento e persistência da melhor distância |
| `test/app/view/app_test.dart` | modificar | Passar `SharedPreferences` mockado para o widget `App` |

## Fases

### Fase 1 — StorageService: interface, implementação e testes

> Fundação que todas as fases seguintes precisam. Criada antes de qualquer adaptação de Cubit.

- [ ] Adicionar `shared_preferences: ^2.3.0` (ou versão compatível com `flutter ^3.41.0`) em `pubspec.yaml` e rodar `flutter pub get`
- [ ] Criar `lib/common/services/storage_service.dart` com `abstract class StorageService` expondo: `Future<int?> getInt(String key)`, `Future<void> setInt(String key, int value)`, `Future<double?> getDouble(String key)`, `Future<void> setDouble(String key, double value)`, `Future<String?> getString(String key)`, `Future<void> setString(String key, String value)`, `Future<bool?> getBool(String key)`, `Future<void> setBool(String key, bool value)`, `Future<void> remove(String key)`
- [ ] Criar `lib/common/services/shared_preferences_storage_service.dart` implementando `StorageService` com `SharedPreferences`; receber instância via construtor `const SharedPreferencesStorageService(this._prefs)`
- [ ] Criar `test/common/services/storage_service_test.dart` usando `SharedPreferences.setMockInitialValues({})` para cobrir: leitura de chave inexistente retorna `null`; escrita seguida de leitura retorna o valor correto (para `int`, `double`, `String`, `bool`); `remove` apaga a chave
- [ ] Verificação: `flutter test test/common/services/storage_service_test.dart` — todos os testes passam

### Fase 2 — Bootstrap e injeção de dependência

- [ ] Modificar `bootstrap()` em `lib/bootstrap.dart`: mudar assinatura do builder para `FutureOr<Widget> Function(SharedPreferences prefs) builder`; adicionar `final prefs = await SharedPreferences.getInstance();` antes de `runApp`; passar `prefs` ao chamar `builder(prefs)`
- [ ] Atualizar `lib/main_development.dart`, `lib/main_staging.dart` e `lib/main_production.dart` para repassar `prefs` ao `App(prefs: prefs)`
- [ ] Modificar `lib/app/view/app.dart`: `App` recebe `final SharedPreferences prefs`; criar `SharedPreferencesStorageService(prefs)` e registrá-lo com `RepositoryProvider<StorageService>(create: (_) => SharedPreferencesStorageService(prefs), ...)` envolvendo o `MultiBlocProvider`
- [ ] Atualizar `test/app/view/app_test.dart`: chamar `SharedPreferences.setMockInitialValues({})` no `setUp` e passar a instância para `App(prefs: prefs)`
- [ ] Verificação: `flutter run --flavor development --target lib/main_development.dart` compila e abre sem erros

### Fase 3 — Testes: contratos de persistência (escrever antes de implementar)

> Os testes abaixo vão **falhar** inicialmente porque a lógica ainda não existe. Isso é intencional.

- [ ] Criar `test/app/cubit/app_locale_cubit_test.dart` com `class MockStorageService extends Mock implements StorageService`:
  - Teste: `init()` lê `getString('app_locale')` e emite `Locale('pt')` quando storage retorna `'pt'`
  - Teste: `init()` não emite nada (estado permanece `null`) quando storage retorna `null`
  - Teste: `setLocale(Locale('en'))` chama `storage.setString('app_locale', 'en')` e emite `Locale('en')`
- [ ] Adicionar em `test/game/cubit/audio_cubit_test.dart` um `MockStorageService`:
  - Teste: `init()` lê `getDouble('audio_volume')` e emite `AudioState(volume: 0)` quando storage retorna `0.0`
  - Teste: `init()` não emite nada quando storage retorna `null` (mantém `AudioState(volume: 1)` padrão)
  - Teste: `toggleVolume()` chama `storage.setDouble('audio_volume', 0)` ao mutar
  - Teste: `toggleVolume()` chama `storage.setDouble('audio_volume', 1)` ao desmutar
- [ ] Adicionar em `test/game/arcade_one_test.dart` um `MockStorageService`:
  - Teste: após `onLoad`, `bestDistanceKm` é inicializado com `3.5` quando storage retorna `3.5` para `'best_distance_km'`
  - Teste: após `onLoad`, `bestDistanceKm` é `0.0` quando storage retorna `null`
  - Teste: `endRun` salva via `storage.setDouble('best_distance_km', ...)` quando `distanceKm > bestDistanceKm`
  - Teste: `endRun` não chama `storage.setDouble` quando `distanceKm <= bestDistanceKm`
- [ ] Verificação: testes compilam e **falham pelos motivos certos** — `NoSuchMethodError` ou método `init` ausente, não por erro de sintaxe

### Fase 4 — Implementação: AppLocaleCubit com persistência

- [ ] Modificar `lib/app/cubit/app_locale_cubit.dart`: receber `StorageService` no construtor; adicionar `static const _keyLocale = 'app_locale'`
- [ ] Adicionar `Future<void> init()`: lê `_keyLocale` via `storage.getString`, e se não-null emite `Locale(languageCode)`
- [ ] Modificar `setLocale()`: salvar `locale.languageCode` via `storage.setString(_keyLocale, ...)` antes de emitir
- [ ] Em `lib/app/view/app.dart`, adaptar o `BlocProvider` de `AppLocaleCubit`:
  ```dart
  BlocProvider(
    create: (ctx) {
      final cubit = AppLocaleCubit(ctx.read<StorageService>());
      unawaited(cubit.init());
      return cubit;
    },
  )
  ```
- [ ] Verificação: `flutter test test/app/cubit/app_locale_cubit_test.dart` — todos os testes passam

### Fase 5 — Implementação: AudioCubit com persistência

- [ ] Modificar `lib/game/cubit/audio/audio_cubit.dart`: receber `StorageService storage` no construtor; adicionar `static const _keyVolume = 'audio_volume'`
- [ ] Adicionar `Future<void> init()`: lê `_keyVolume` via `storage.getDouble`; se não-null, chama `_changeVolume(savedVolume)` sem emitir `Loading`
- [ ] Modificar `toggleVolume()`: após `_changeVolume`, salvar novo volume via `storage.setDouble(_keyVolume, ...)`
- [ ] Adaptar `AudioCubit.test` factory para aceitar `StorageService` opcional (usar `FakeStorageService` ou `null`-safe) para não quebrar testes existentes que não passam storage
- [ ] Em `lib/game/view/game_page.dart`, adaptar o `BlocProvider` de `AudioCubit`:
  ```dart
  BlocProvider(
    create: (ctx) {
      final cubit = AudioCubit(
        enginePlayer: enginePlayer,
        deathPlayer: deathPlayer,
        storage: ctx.read<StorageService>(),
      );
      unawaited(cubit.init());
      return cubit;
    },
  )
  ```
- [ ] Verificação: `flutter test test/game/cubit/audio_cubit_test.dart` — todos os testes passam (incluindo os existentes)

### Fase 6 — Implementação: ArcadeOne best distance com persistência

- [ ] Modificar construtor de `ArcadeOne` em `lib/game/arcade_one.dart`: adicionar `required StorageService storage`; adicionar `static const _keyBestDistance = 'best_distance_km'`
- [ ] Em `onLoad`: após `_buildRun`, ler `storage.getDouble(_keyBestDistance)` e inicializar `bestDistanceKm` com o valor (ou `0.0` se null)
- [ ] Em `endRun`: após `bestDistanceKm = math.max(bestDistanceKm, distanceKm)`, salvar via `storage.setDouble(_keyBestDistance, bestDistanceKm)`
- [ ] Em `lib/game/view/game_page.dart` (`GameView.build`), passar `storage: context.read<StorageService>()` ao construtor de `ArcadeOne`
- [ ] Verificação: `flutter test test/game/arcade_one_test.dart` — todos os testes passam (incluindo os existentes)

### Fase 7 — Atualizar Flows

- [ ] Atualizar `flow/title.md`: na tabela de arquivos, adicionar `lib/common/services/storage_service.dart`; na Regra de Negócio "Idioma muda em memória" → "Idioma persistido em storage: carregado no `init()` do `AppLocaleCubit` e salvo em cada troca via `setLocale`"; atualizar passo 6 para mencionar que a troca persiste
- [ ] Atualizar `flow/game.md`: Regra "Melhor distância da sessão" → "Melhor distância persistida em storage e carregada no `onLoad`"; atualizar passo 9 (onLoad) e passo 16 (endRun) para refletir leitura/escrita; remover a Observação sobre falta de persistência local; adicionar `lib/common/services/storage_service.dart` à tabela de arquivos
- [ ] Atualizar `flow/l10n.md`: Regra "Troca de idioma sem persistência" → "Idioma salvo em storage no momento da troca e restaurado no próximo lançamento via `AppLocaleCubit.init()`"; atualizar passo 8 (AppLocaleCubit)
- [ ] Verificação final: `flutter test --coverage --test-randomize-ordering-seed random` — todos os testes passam

## Critérios de Sucesso

- [ ] Idioma selecionado é mantido após fechar e reabrir o app
- [ ] Melhor distância em KM é mantida entre sessões
- [ ] Estado de som (mutado/ativo) é mantido entre sessões
- [ ] `AppLocaleCubit`, `AudioCubit` e `ArcadeOne` não acessam `SharedPreferences` diretamente — todos passam pelo `StorageService`
- [ ] Build sem erros em todos os flavors (`development`, `staging`, `production`)
- [ ] Todos os testes unitários passando, incluindo os pré-existentes de `audio_cubit_test.dart` e `arcade_one_test.dart`

## Riscos e Mitigações

| Risco | Probabilidade | Mitigação |
|-------|--------------|-----------|
| `bootstrap()` muda de assinatura e quebra os 3 entry points | Baixa | Atualizar os três `main_*.dart` na Fase 2 antes de compilar; são arquivos pequenos e idênticos |
| Testes existentes de `AudioCubit` quebram porque o construtor ganhou novo parâmetro | Média | Tornar `storage` opcional com `StorageService? storage` no construtor; usar `FakeStorageService` no `AudioCubit.test` factory |
| Testes de `ArcadeOne` quebram porque o construtor ganhou `storage` obrigatório | Média | Adicionar `MockStorageService` no `setUp` de `arcade_one_test.dart` e passar ao construtor |
| `test/app/view/app_test.dart` cria `App()` sem `prefs` e quebra | Média | Usar `SharedPreferences.setMockInitialValues({})` no `setUp` e passar `prefs` ao `App` — descrito na Fase 2 |
| `onLoad` de `ArcadeOne` é async (lê storage), mas `_buildRun` é sync hoje | Baixa | `onLoad` já retorna `Future<void>` no Flame; basta `await` a leitura antes de `_buildRun` ou logo após |
| Versão de `shared_preferences` incompatível com `flutter ^3.41.0` | Baixa | Checar `flutter pub outdated` antes de fixar versão; a `^2.3.0` é amplamente compatível |

## Rollback

Cada fase adiciona uma camada independente. Para reverter:
- **Fase 1–2 (StorageService + Bootstrap):** `git revert` dos commits das fases; os Cubits voltam ao estado sem parâmetro `storage`
- **Fases 4–6 individualmente:** reversão de um Cubit não afeta os outros; o `StorageService` e o bootstrap podem ser mantidos para futuras features
- Os flows (Fase 7) são documentação; revertê-los não afeta comportamento em runtime
