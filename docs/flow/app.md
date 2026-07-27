---
generated_at: 2026-07-27
source_commit: 2bc98a5
source_state: dirty
verified_at: 2026-07-27
status: current
related_plans: []
---

# Flow: App

> **Resumo:** Inicializa o flavor escolhido, prepara serviços globais e monta o `MaterialApp` com locale, tema, Cubits e `LoadingPage`.

## Visão Geral

O fluxo começa em um dos três entry points de flavor. Cada `main` chama `bootstrap` e fornece um builder que cria `App` com a instância de `SharedPreferences` carregada durante a inicialização.

O bootstrap configura o binding do Flutter, logs globais de erros e mudanças de Bloc, registra a licença Poppins, define o contexto de áudio e inicializa o Google Mobile Ads. Depois obtém `SharedPreferences` e executa `runApp`.

`App` expõe `StorageService` e os Cubits globais de locale, preload e áudio. `AppView` limita a orientação a retrato, reage ao locale atual e monta o `MaterialApp` com tema Poppins, localizações em inglês e português e `LoadingPage` como tela inicial.

## Passo a Passo

1. **Entry point** — `lib/main_development.dart`, `lib/main_staging.dart`, `lib/main_production.dart` → `main`
   O flavor selecionado chama `bootstrap((prefs) => App(prefs: prefs))`.
2. **Inicialização Flutter** — `lib/bootstrap.dart` → `bootstrap`
   Executa `WidgetsFlutterBinding.ensureInitialized`, registra `FlutterError.onError` e instala `AppBlocObserver` para logar mudanças e erros de Bloc/Cubit.
3. **Configuração global** — `lib/bootstrap.dart` → `bootstrap`
   Registra a licença Poppins, configura `AudioPlayer.global` com categoria ambiente no iOS e sem foco exclusivo no Android e inicializa `AdService`.
4. **Persistência e montagem** — `lib/bootstrap.dart` → `bootstrap`
   Obtém `SharedPreferences.getInstance()`, chama o builder recebido e entrega o widget resultante a `runApp`.
5. **Provider de persistência** — `lib/app/view/app.dart` → `App.build`
   Cria `SharedPreferencesStorageService` e o fornece como `StorageService` por `RepositoryProvider`.
6. **Cubits globais** — `lib/app/view/app.dart` → `App.build`
   Cria `AppLocaleCubit`, `PreloadCubit` e `AudioCubit`; dispara `init()` ou `loadSequentially()` sem bloquear a primeira renderização.
7. **Restauração do locale** — `lib/app/cubit/app_locale_cubit.dart` → `AppLocaleCubit.init`
   Lê `app_locale` no storage e emite um `Locale` quando existe um valor salvo.
8. **Orientação** — `lib/app/view/app.dart` → `_AppViewState.initState`
   Após o primeiro frame, solicita apenas `DeviceOrientation.portraitUp`.
9. **Shell visual** — `lib/app/view/app.dart` → `AppView.build`
   `BlocBuilder<AppLocaleCubit, Locale?>` monta o `MaterialApp`, aplica tema Poppins, delegates, locales suportados e `home: const LoadingPage()`.

### Caminhos alternativos

- **Locale ainda não escolhido:** `AppLocaleCubit` permanece com estado `null`; o `MaterialApp` deixa o Flutter resolver o idioma pelo sistema.
- **Locale persistido:** `AppLocaleCubit.init` emite `Locale(saved)` e o `BlocBuilder` reconstrói o `MaterialApp` com esse locale.

## Arquivos Envolvidos

| Camada | Arquivo | Responsabilidade |
|--------|---------|------------------|
| Entry point | `lib/main_development.dart` | Entrada do flavor development. |
| Entry point | `lib/main_staging.dart` | Entrada do flavor staging. |
| Entry point | `lib/main_production.dart` | Entrada do flavor production. |
| Bootstrap | `lib/bootstrap.dart` | Configura erros, Bloc, licença, áudio, anúncios, preferências e `runApp`. |
| Apresentação | `lib/app/view/app.dart` | Compõe providers, orientação, tema, localização e tela inicial. |
| Estado / Cubit | `lib/app/cubit/app_locale_cubit.dart` | Restaura, persiste e emite o locale escolhido. |
| Serviços | `lib/common/services/storage_service.dart` | Define a interface de persistência consumida pelos Cubits e pelo jogo. |
| Serviços | `lib/common/services/shared_preferences_storage_service.dart` | Implementa `StorageService` com `SharedPreferences`. |
| Serviços | `lib/common/services/ads/ad_service.dart` | Inicializa o Google Mobile Ads uma vez por instância. |
| Estado / Cubit | `lib/loading/cubit/preload/preload_cubit.dart` | Mantém os caches globais e inicia o preload. |
| Estado / Cubit | `lib/game/cubit/audio/audio_cubit.dart` | Controla players, volume persistido e BGM. |
| Configuração | `l10n.yaml` | Define a geração das localizações usadas no `MaterialApp`. |
| Testes | `test/app/cubit/app_locale_cubit_test.dart` | Cobre estado inicial, restauração e persistência do locale. |
| Testes | `test/app/view/app_test.dart` | Verifica que `App` monta `AppView`. |
| Testes | `test/common/services/storage_service_test.dart` | Cobre a implementação de storage com `SharedPreferences`. |

## Regras de Negócio Relevantes

- **Mesma inicialização para todos os flavors** — `lib/main_development.dart`, `lib/main_staging.dart`, `lib/main_production.dart`: os três entry points executam o mesmo builder.
- **Dependência por abstração** — `lib/app/view/app.dart`: consumidores recebem `StorageService`; somente a composição global conhece `SharedPreferencesStorageService`.
- **Inicialização assíncrona não bloqueante dos Cubits** — `lib/app/view/app.dart`: `AppLocaleCubit.init`, `PreloadCubit.loadSequentially` e `AudioCubit.init` são disparados com `unawaited`.
- **Locale persistido** — `lib/app/cubit/app_locale_cubit.dart`: a chave é `app_locale`, e selecionar o locale atual novamente não grava nem emite outro estado.
- **Orientação retrato** — `lib/app/view/app.dart`: a aplicação solicita somente `portraitUp`.
- **Tela inicial fixa** — `lib/app/view/app.dart`: o `home` do `MaterialApp` é sempre `LoadingPage`.

## Dependências Externas

- Flutter para binding, orientação, `MaterialApp`, localização e registro de licença.
- `bloc` e `flutter_bloc` para observer, Cubits e providers.
- `shared_preferences` para persistência local.
- `audioplayers` para contexto global, cache e players.
- `flame` para o cache global de imagens.
- `google_mobile_ads` para inicialização do SDK.
- `google_fonts` para o tema Poppins.

## Observações

- O comentário `Add cross-flavor configuration here` em `lib/bootstrap.dart` marca o ponto previsto para diferenças futuras entre flavors.
- `bootstrap` não captura falhas da inicialização de anúncios ou de `SharedPreferences`; uma exceção nessas etapas impede que `runApp` seja alcançado.
