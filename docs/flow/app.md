---
generated_at: 2026-07-27
source_commit: 698131b
source_state: clean
verified_at: 2026-09-12
status: current
related_plans:
  - docs/plan/local-persistence.md
---

# Flow: App

> **Resumo:** Inicializa o flavor escolhido, configura integrações globais e monta o `MaterialApp` com storage, Cubits, localização, tema e `LoadingPage`.

## Visão Geral

O fluxo começa em um dos três entry points de flavor. Todos chamam `bootstrap` com um builder que cria `App` depois que o `SharedPreferences` está disponível.

O bootstrap inicializa o binding do Flutter, tratamento e logging de erros, observação de Bloc, licença Poppins, contexto global de áudio e Google Mobile Ads. Em seguida, carrega o storage nativo e entrega a instância ao widget raiz.

`App` converte `SharedPreferences` na abstração `StorageService` e fornece os Cubits globais de locale, preload e áudio. `AppView` fixa orientação retrato, reconstrói o `MaterialApp` quando o locale muda e abre `LoadingPage`, que inicia o fluxo visível do produto.

## Passo a Passo

1. **Entry point do flavor** — `lib/main_development.dart`, `lib/main_staging.dart`, `lib/main_production.dart` → `main`
   O executável selecionado chama `bootstrap((prefs) => App(prefs: prefs))`; não há diferença de inicialização entre os três arquivos.
2. **Binding, erros e observação de estado** — `lib/bootstrap.dart` → `bootstrap` e `AppBlocObserver`
   Inicializa o binding, redireciona `FlutterError.onError` para `log` e registra um observer que loga mudanças e erros de Bloc/Cubit.
3. **Integrações globais** — `lib/bootstrap.dart` → `bootstrap`
   Registra a licença Poppins, configura áudio como `ambient` no iOS e sem foco no Android e aguarda `AdService.initialize()`.
4. **Persistência e montagem** — `lib/bootstrap.dart` → `bootstrap`
   Obtém `SharedPreferences.getInstance()` e chama `runApp` com o widget retornado pelo builder.
5. **Repository global** — `lib/app/view/app.dart` → `App.build`
   Cria `SharedPreferencesStorageService` e o expõe como `RepositoryProvider<StorageService>`.
6. **Cubits globais** — `lib/app/view/app.dart` → `App.build`
   Cria `AppLocaleCubit`, `PreloadCubit` e `AudioCubit`; dispara `init`/`loadSequentially` sem bloquear a primeira renderização.
7. **Shell visual** — `lib/app/view/app.dart` → `_AppViewState`
   Solicita orientação `portraitUp` após o primeiro frame e monta o `MaterialApp` com tema Poppins, locale, delegates e locales suportados.
8. **Primeira tela** — `lib/app/view/app.dart` → `AppView.build`
   Define `LoadingPage` como `home`; a partir dela o preload conduz a navegação até `TitleView`.

### Caminhos alternativos

- **Locale ainda não persistido:** `AppLocaleCubit` mantém `null`, e o `MaterialApp` usa a resolução de locale da plataforma.
- **Locale persistido:** `AppLocaleCubit.init` emite `Locale(languageCode)` e o `BlocBuilder` remonta o `MaterialApp` com esse valor.

## Arquivos Envolvidos

| Camada | Arquivo | Responsabilidade |
|--------|---------|------------------|
| Entrada | `lib/main_development.dart` | Inicializa o flavor development. |
| Entrada | `lib/main_staging.dart` | Inicializa o flavor staging. |
| Entrada | `lib/main_production.dart` | Inicializa o flavor production. |
| Bootstrap | `lib/bootstrap.dart` | Configura serviços globais, carrega preferências e executa o app. |
| Apresentação | `lib/app/view/app.dart` | Compõe providers, Cubits e `MaterialApp`. |
| Estado | `lib/app/cubit/app_locale_cubit.dart` | Restaura, persiste e publica o locale. |
| Dados | `lib/common/services/storage_service.dart` | Define o contrato usado pelos consumidores persistentes. |
| Dados | `lib/common/services/shared_preferences_storage_service.dart` | Implementa o contrato com `SharedPreferences`. |
| Serviço | `lib/common/services/ads/ad_service.dart` | Inicializa o SDK Google Mobile Ads. |
| Testes | `test/app/view/app_test.dart` | Verifica a montagem de `AppView`. |
| Testes | `test/app/cubit/app_locale_cubit_test.dart` | Cobre estado inicial, restauração e persistência de locale. |

## Regras de Negócio Relevantes

- **Orientação retrato** — `lib/app/view/app.dart`: a interface solicita apenas `DeviceOrientation.portraitUp`.
- **Locale persistente** — `lib/app/cubit/app_locale_cubit.dart`: a chave `app_locale` guarda somente o `languageCode`; selecionar o locale já ativo não regrava nem emite estado.
- **Dependência por abstração** — `lib/app/view/app.dart`: Cubits recebem `StorageService`, mantendo `SharedPreferences` restrito à composição raiz.

## Dependências Externas

- Flutter/Material para binding, orientação e shell visual.
- `bloc` e `flutter_bloc` para observação, providers e Cubits.
- `shared_preferences` como backend de persistência.
- `audioplayers` para o contexto de áudio e os players globais.
- `google_mobile_ads` para inicialização do SDK de anúncios.
- `google_fonts` para aplicar Poppins ao tema.

## Observações

- O comentário de configuração por flavor fica em `lib/bootstrap.dart`, mas os três entry points executam atualmente o mesmo builder.
- As inicializações dos Cubits são assíncronas e não aguardadas pela montagem; a UI começa com os estados padrão e reage às emissões posteriores.
- Não existe estado visual de falha no bootstrap: exceções de preferências, áudio ou anúncios impedem que `runApp` seja alcançado.
