# Flow: App

> **Resumo:** Inicializa o aplicativo Flutter, registra dependencias globais e exibe a tela de loading como primeira experiencia.

## Visão Geral

O fluxo do App começa em um dos entry points de flavor (`main_development`, `main_staging` ou `main_production`). Todos chamam `bootstrap`, que configura o tratamento global de erros, o observer de Bloc e a licenca da fonte Poppins antes de executar `runApp`.

Depois do bootstrap, `App` cria o `AppLocaleCubit` global para controlar o idioma da sessao e o `PreloadCubit` global com caches de imagens e audio sem prefixo. Quando nenhum idioma foi escolhido, o locale fica `null` e o `MaterialApp` resolve pelo sistema. A carga dos assets e iniciada imediatamente via `loadSequentially`, sem aguardar o fim antes de renderizar a UI.

`AppView` monta o `MaterialApp` dentro de um `BlocBuilder<AppLocaleCubit, Locale>`, aplica tema com Poppins, configura localizacoes, passa o locale atual e define `LoadingPage` como `home`. A partir dai, o fluxo segue para a feature de loading.

## Passo a Passo

1. **Entry point** — `lib/main_development.dart`, `lib/main_staging.dart`, `lib/main_production.dart` → `main`
   Cada flavor chama `bootstrap(() => const App())`.
2. **Bootstrap** — `lib/bootstrap.dart` → `bootstrap`
   Registra `FlutterError.onError`, `AppBlocObserver`, licenca Poppins e executa `runApp(await builder())`.
3. **Observer** — `lib/bootstrap.dart` → `AppBlocObserver`
   Loga mudancas e erros de Bloc/Cubit via `dart:developer`.
4. **Provider global de idioma** — `lib/app/view/app.dart` → `App.build`
   Cria `AppLocaleCubit` dentro de `MultiBlocProvider`.
5. **Provider global de preload** — `lib/app/view/app.dart` → `App.build`
   Cria `PreloadCubit(Images(prefix: ''), AudioCache(prefix: ''))` dentro de `MultiBlocProvider` e dispara `loadSequentially`.
6. **Shell visual** — `lib/app/view/app.dart` → `AppView.build`
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
| Configuracao | `pubspec.yaml` | Declara assets, dependencias e geracao Flutter. |
| Configuracao | `l10n.yaml` | Define a geracao de localizacoes usadas pelo `MaterialApp`. |
| Testes | `test/app/view/app_test.dart` | Cobre a montagem da feature App. |
| Testes | `test/helpers/pump_app.dart` | Helper para montar widgets com l10n, locale e providers em testes. |

## Regras de Negócio Relevantes

- **Preload comeca no startup** — `lib/app/view/app.dart`: o `PreloadCubit.loadSequentially()` e disparado assim que o provider e criado.
- **Idioma global em memoria** — `lib/app/view/app.dart` e `lib/app/cubit/app_locale_cubit.dart`: o locale selecionado pelo usuario e aplicado no `MaterialApp`, mas nao e salvo em storage; sem selecao manual, o app usa a resolucao padrao do sistema.
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
