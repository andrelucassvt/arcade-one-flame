# Flow: App

> **Resumo:** Inicializa o aplicativo Flutter, registra dependencias globais e exibe a tela de loading como primeira experiencia.

## Visão Geral

O fluxo do App começa em um dos entry points de flavor (`main_development`, `main_staging` ou `main_production`). Todos chamam `bootstrap`, que configura o tratamento global de erros, o observer de Bloc e a licenca da fonte Poppins antes de executar `runApp`.

Depois do bootstrap, `App` cria providers globais para `StorageService`, `AppLocaleCubit`, `PreloadCubit` e `AudioCubit`. O `AppLocaleCubit` controla o idioma da sessao, o `PreloadCubit` mantem caches de imagens e audio sem prefixo, e o `AudioCubit` usa o cache de audio para manter os players de motor/fogo e morte disponiveis tanto na Title quanto na Game. Quando nenhum idioma foi escolhido, o locale fica `null` e o `MaterialApp` resolve pelo sistema. A carga dos assets e iniciada imediatamente via `loadSequentially`, sem aguardar o fim antes de renderizar a UI.

`AppView` monta o `MaterialApp` dentro de um `BlocBuilder<AppLocaleCubit, Locale>`, aplica tema com Poppins, configura localizacoes, passa o locale atual e define `LoadingPage` como `home`. A partir dai, o fluxo segue para a feature de loading.

## Passo a Passo

1. **Entry point** — `lib/main_development.dart`, `lib/main_staging.dart`, `lib/main_production.dart` → `main`
   Cada flavor chama `bootstrap(() => const App())`.
2. **Bootstrap** — `lib/bootstrap.dart` → `bootstrap`
   Registra `FlutterError.onError`, `AppBlocObserver`, licenca Poppins e executa `runApp(await builder())`.
3. **Observer** — `lib/bootstrap.dart` → `AppBlocObserver`
   Loga mudancas e erros de Bloc/Cubit via `dart:developer`.
4. **Provider global de storage** — `lib/app/view/app.dart` → `App.build`
   Cria `SharedPreferencesStorageService` a partir das preferencias recebidas no construtor.
5. **Provider global de idioma** — `lib/app/view/app.dart` → `App.build`
   Cria `AppLocaleCubit` dentro de `MultiBlocProvider` e chama `init()` para restaurar o locale salvo.
6. **Provider global de preload** — `lib/app/view/app.dart` → `App.build`
   Cria `PreloadCubit(Images(prefix: ''), AudioCache(prefix: ''))` dentro de `MultiBlocProvider` e dispara `loadSequentially`.
7. **Provider global de audio** — `lib/app/view/app.dart` → `App.build`
   Cria `AudioCubit` com `enginePlayer` e `deathPlayer` ligados ao `AudioCache` do `PreloadCubit`, passa `StorageService` e chama `init()` para restaurar o volume salvo.
8. **Shell visual** — `lib/app/view/app.dart` → `AppView.build`
   Escuta `AppLocaleCubit`, configura `MaterialApp`, tema, localizacoes, locale atual e `home: const LoadingPage()`.

## Arquivos Envolvidos

| Camada | Arquivo | Responsabilidade |
|--------|---------|------------------|
| Entry point | `lib/main_development.dart` | Entrada do flavor development. |
| Entry point | `lib/main_staging.dart` | Entrada do flavor staging. |
| Entry point | `lib/main_production.dart` | Entrada do flavor production. |
| Bootstrap | `lib/bootstrap.dart` | Configura erros, Bloc observer, licenca Poppins e `runApp`. |
| Apresentacao | `lib/app/view/app.dart` | Compoe providers globais, tema, l10n e tela inicial. |
| Barrel | `lib/app/app.dart` | Exporta cubits e view da feature App. |
| Estado / Cubit | `lib/app/cubit/app_locale_cubit.dart` | Mantem o locale atual da sessao. |
| Estado / Cubit | `lib/loading/cubit/preload/preload_cubit.dart` | Cubit global criado pelo App para carregar assets. |
| Estado / Cubit | `lib/game/cubit/audio/audio_cubit.dart` | Cubit global criado pelo App para controlar volume e players de audio usados pela Title e pela Game. |
| Estado | `lib/game/cubit/audio/audio_state.dart` | Guarda o volume atual usado pelos botoes de mute. |
| Servico | `lib/common/services/storage_service.dart` | Interface de persistencia usada por locale, volume e melhor distancia. |
| Servico | `lib/common/services/shared_preferences_storage_service.dart` | Implementacao de storage usada pelo App em runtime. |
| Configuracao | `pubspec.yaml` | Declara assets, dependencias e geracao Flutter. |
| Configuracao | `l10n.yaml` | Define a geracao de localizacoes usadas pelo `MaterialApp`. |
| Testes | `test/app/view/app_test.dart` | Cobre a montagem da feature App. |
| Testes | `test/helpers/pump_app.dart` | Helper para montar widgets com l10n, locale e providers em testes. |

## Regras de Negócio Relevantes

- **Preload comeca no startup** — `lib/app/view/app.dart`: o `PreloadCubit.loadSequentially()` e disparado assim que o provider e criado.
- **Idioma global persistido** — `lib/app/view/app.dart` e `lib/app/cubit/app_locale_cubit.dart`: o locale selecionado pelo usuario e salvo em storage, restaurado no startup e aplicado no `MaterialApp`; sem selecao manual, o app usa a resolucao padrao do sistema.
- **Volume global persistido** — `lib/app/view/app.dart` e `lib/game/cubit/audio/audio_cubit.dart`: o volume e restaurado no startup e compartilhado entre Title e Game pelo mesmo `AudioCubit`.
- **Tema global Poppins** — `lib/app/view/app.dart` e `lib/bootstrap.dart`: `GoogleFonts.poppinsTextTheme()` define o texto, e a licenca Poppins e registrada no bootstrap.
- **Tela inicial fixa** — `lib/app/view/app.dart`: `LoadingPage` e sempre o `home` do `MaterialApp`.

## Dependências Externas

- `flutter_bloc` para `MultiBlocProvider`, `BlocProvider` e `BlocBuilder`.
- `flame/cache.dart` para `Images`.
- `audioplayers` para `AudioCache`.
- `google_fonts` para o tema Poppins.
- `flutter_localizations` e `intl` por meio dos delegates gerados.

## Observações

- Os tres entry points de flavor ainda executam a mesma configuracao.
- `bootstrap.dart` contem o comentario `Add cross-flavor configuration here`, indicando um ponto preparado para diferenciacao futura entre flavors.
