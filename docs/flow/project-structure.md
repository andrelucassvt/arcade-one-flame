---
generated_at: 2026-07-27
source_commit: 2bc98a5
source_state: dirty
verified_at: 2026-07-27
status: current
related_plans: []
---

# Estrutura do Projeto: Arcade One

> **Resumo:** Jogo arcade espacial multiplataforma em Flutter, com Cubits para estado da interface e um `FlameGame` para a cena jogável, os obstáculos e a progressão da partida.

## Stack e Tecnologias

| Elemento | Valor |
|----------|-------|
| Linguagem | Dart `^3.11.0` |
| Framework | Flutter `^3.41.0` e Flame `^1.37.0` |
| Gerenciador de pacotes | pub |
| Interface e estado | Material, `flutter_bloc` e Cubit |
| Persistência local | `StorageService` sobre `shared_preferences` |
| Áudio e anúncios | `audioplayers` e Google Mobile Ads |
| Localização | ARB, `flutter_localizations` e código gerado pelo Flutter |
| Principais dependências | `bloc`, `flutter_bloc`, `flame`, `audioplayers`, `equatable`, `shared_preferences`, `google_mobile_ads`, `google_fonts` |

## Arquitetura

O código é organizado por módulos em `lib/`: `app` compõe as dependências globais, `loading` prepara os assets, `title` configura a partida e `game` reúne a UI Flutter e a cena Flame. Os Cubits cuidam de locale, preload, áudio, modo de controle e nave selecionada; a persistência passa pela abstração `StorageService`. A navegação usa `Navigator.pushReplacement` com `MaterialPageRoute`, sem router ou contêiner de injeção dedicado.

```text
main_<flavor>
  → bootstrap
  → App / providers globais
  → LoadingPage
  → TitleView
  → GamePage
  → GameWidget<ArcadeOne>

UI Flutter → Cubits → StorageService → SharedPreferences
GamePage → caches do PreloadCubit → ArcadeOne → componentes Flame
```

### Regras de dependência

- `lib/app/view/app.dart` fornece `StorageService`, `AppLocaleCubit`, `PreloadCubit` e `AudioCubit` acima de todas as telas.
- `AppLocaleCubit`, `AudioCubit`, `TitleControlModeCubit`, `TitleShipSelectionCubit` e `ArcadeOne` dependem de `StorageService`, não diretamente de `SharedPreferences`.
- `LoadingPage` navega para `TitleView`; `TitleStartButton` navega para `GamePage`; o overlay de game over pode retornar para `TitleView`.
- `GameView` lê `PreloadCubit`, `AudioCubit` e `StorageService` do contexto e entrega os caches, o áudio e a persistência a `ArcadeOne`.
- `lib/gen/` e `lib/l10n/gen/` são saídas geradas e estão excluídas do analyzer.

## Features

| Feature | Caminho principal | Descrição resumida |
|---------|------------------|-------------------|
| App | `lib/app/` | Compõe providers globais, locale, tema, orientação e a tela inicial do aplicativo. |
| Loading | `lib/loading/` | Precarrega o áudio de morte e as imagens do jogo, exibe o progresso e encaminha para a tela de título. |
| Title | `lib/title/` | Exibe a tela inicial, troca o idioma, persiste o modo de controle, seleciona naves desbloqueadas e inicia a partida. |
| Game | `lib/game/` | Executa a partida Flame, controles por toque ou joystick, áudio, HUD, cenários por distância, obstáculos, colisões, game over e melhor distância persistida. |

## Camadas / Módulos Compartilhados

| Tipo | Caminho | Responsabilidade |
|------|---------|-----------------|
| Persistência | `lib/common/services/storage_service.dart`, `lib/common/services/shared_preferences_storage_service.dart` | Define a interface de armazenamento e sua implementação com `SharedPreferences`. |
| Anúncios | `lib/common/services/ads/` | Centraliza IDs por plataforma e inicializa o Google Mobile Ads. |
| Widgets compartilhados | `lib/common/widgets/` | Fornece o banner com tentativa de unidade alternativa em caso de falha. |
| Localização | `lib/l10n/` | Mantém ARBs em inglês e português, configuração gerada e a extensão `context.l10n`. |
| Assets gerados | `lib/gen/` | Expõe acesso tipado aos assets declarados no `pubspec.yaml`. |
| Assets | `assets/audio/`, `assets/images/`, `assets/licenses/` | Armazena trilhas e efeitos, sprites e cenários, além da licença da fonte Poppins. |
| Test helpers | `test/helpers/` | Reúne montagem de widgets, mocks e um jogo de teste para a suíte. |

## Configuração

| Componente | Arquivo | Responsabilidade |
|-----------|---------|-----------------|
| Manifesto | `pubspec.yaml` | Define o pacote `arcade_one` `1.0.0+1`, SDKs, dependências, geração e diretórios de assets. |
| Entry points | `lib/main_development.dart`, `lib/main_staging.dart`, `lib/main_production.dart` | Inicializam cada flavor e entregam o `SharedPreferences` carregado ao `App`. |
| Bootstrap | `lib/bootstrap.dart` | Configura erros Flutter, `BlocObserver`, licença Poppins, contexto global de áudio, Mobile Ads, `SharedPreferences` e `runApp`. |
| Composição global | `lib/app/view/app.dart` | Registra repository/provider e Cubits, cria o `MaterialApp`, tema, delegates de localização e `LoadingPage`. |
| Navegação | `lib/loading/view/loading_page.dart`, `lib/title/view/title_page.dart`, `lib/title/content/title_start_button.dart`, `lib/game/view/game_page.dart` | Implementa o fluxo manual entre loading, título e jogo. |
| Localização | `l10n.yaml` | Usa `lib/l10n/arb/app_en.arb` como template e gera saída em `lib/l10n/gen/`. |
| Análise estática | `analysis_options.yaml` | Inclui Very Good Analysis e Bloc Lint e exclui as saídas geradas. |
| Flavors e ícones | `flutter_launcher_icons-development.yaml`, `flutter_launcher_icons-staging.yaml`, `flutter_launcher_icons-production.yaml` | Mantém a configuração de ícones específica de cada flavor. |

## Dependências Externas Principais

| Pacote | Versão | Uso no projeto |
|--------|--------|---------------|
| `bloc` | `^9.2.0` | Base de Cubit e `BlocObserver`; usado diretamente no bootstrap e no preload. |
| `flutter_bloc` | `^9.1.1` | Providers, builders, listeners e acesso aos Cubits na interface Flutter. |
| `flame` | `^1.37.0` | `FlameGame`, `GameWidget`, eventos, componentes e cache de imagens da partida. |
| `audioplayers` | `^6.6.0` | Cache do efeito de morte, música em loop e configuração global de áudio. |
| `equatable` | `^2.0.8` | Igualdade dos estados de preload e áudio. |
| `shared_preferences` | `^2.3.0` | Backend local para locale, volume, modo de controle, nave escolhida e melhor distância. |
| `google_mobile_ads` | `^9.0.0` | Inicialização do SDK e banner exibido na tela de jogo em Android e iOS. |
| `google_fonts` | `^8.1.0` | Aplica Poppins ao tema do `MaterialApp`. |
| `flutter_localizations` | SDK Flutter | Fornece os delegates usados pelas localizações geradas. |
| `bloc_test` | `^10.0.0` | Suporte aos testes de Cubit. |
| `flame_test` | `^2.2.4` | Suporte aos testes de entidades e componentes Flame. |
| `mocktail` | `^1.0.5` | Mocks em testes unitários e de widgets. |
| `mockingjay` | `^2.1.0` | Mocks de navegação nos testes de widgets. |
| `very_good_analysis` | `^10.2.0` | Conjunto principal de regras do analyzer. |
| `bloc_lint` | `^0.4.1` | Regras específicas para Bloc e Cubit. |

## Observações

- O estado analisado já estava `dirty`: `pubspec.yaml` e `pubspec.lock` possuem alterações locais.
- Os três entry points de flavor executam a mesma inicialização; `lib/bootstrap.dart` mantém o ponto indicado para configuração específica por flavor.
- Não há router nem service locator: a navegação é manual e a composição de dependências usa providers do `flutter_bloc`.
- `PreloadCubit` carrega antecipadamente `Assets.audio.death`, `Assets.images.unicornAnimation.path` e a lista `gameImageAssets`; a música `assets/audio/background_2.mp3` é iniciada pelo `AudioCubit`.
- O banner é configurado apenas para Android e iOS; `AdConfig.maybeBanner` retorna `null` nas demais plataformas.
- A suíte em `test/` espelha `app`, `common`, `loading`, `title` e `game`, com testes de Cubits, widgets, serviços, catálogos, entidades e componentes Flame.
