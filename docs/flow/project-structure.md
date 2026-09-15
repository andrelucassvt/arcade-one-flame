---
generated_at: 2026-07-27
source_commit: 698131b
source_state: clean
verified_at: 2026-09-12
status: current
related_plans: []
---

# Estrutura do Projeto: Arcade One

> **Resumo:** Jogo arcade espacial multiplataforma em Flutter, com Cubits para o estado da interface e um `FlameGame` responsável pela partida, progressão, obstáculos e colisões.

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

O código autoral é organizado por módulos em `lib/`: `app` compõe as dependências globais, `loading` prepara os assets, `title` configura a partida e `game` integra a interface Flutter com a cena Flame. Cubits cuidam de locale, preload, áudio, modo de controle e nave selecionada; os consumidores persistentes dependem da abstração `StorageService`. A navegação é manual, com `Navigator.pushReplacement` e `MaterialPageRoute`, sem router ou service locator dedicado.

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

- `lib/app/view/app.dart` fornece `StorageService`, `AppLocaleCubit`, `PreloadCubit` e `AudioCubit` acima das telas.
- `AppLocaleCubit`, `AudioCubit`, `TitleControlModeCubit`, `TitleShipSelectionCubit` e `ArcadeOne` persistem dados por `StorageService`, sem conhecer `SharedPreferences` diretamente.
- `LoadingPage` substitui sua rota por `TitleView`; `TitleStartButton` substitui a rota pela `GamePage`; o overlay de game over pode retornar à `TitleView`.
- `GameView` lê `PreloadCubit`, `AudioCubit` e `StorageService` do contexto e entrega caches, áudio, localização e persistência a `ArcadeOne`.
- `lib/gen/` e `lib/l10n/gen/` são saídas geradas e ficam excluídas do analyzer.

## Features

| Feature | Caminho principal | Descrição resumida |
|---------|------------------|-------------------|
| App | `lib/app/` | Compõe providers globais, locale, tema, orientação e a tela inicial do aplicativo. |
| Loading | `lib/loading/` | Precarrega áudio e imagens, expõe progresso por Cubit e encaminha para a tela de título. |
| Title | `lib/title/` | Troca idioma e volume, persiste o modo de controle e a nave selecionada, aplica desbloqueios por melhor distância e inicia a partida. |
| Game | `lib/game/` | Executa a partida Flame, controles por toque ou joystick, áudio, HUD, cenários por distância, obstáculos, colisões, game over e melhor distância persistida. |

## Camadas / Módulos Compartilhados

| Tipo | Caminho | Responsabilidade |
|------|---------|-----------------|
| Persistência | `lib/common/services/storage_service.dart`, `lib/common/services/shared_preferences_storage_service.dart` | Define o contrato de armazenamento e sua implementação com `SharedPreferences`. |
| Anúncios | `lib/common/services/ads/` | Inicializa o Google Mobile Ads, resolve IDs de banner principal, alternativo e intersticial por plataforma e gerencia o ciclo do intersticial com cooldown. |
| Widgets compartilhados | `lib/common/widgets/` | Fornece o banner com fallback de unidade em caso de falha no carregamento. |
| Localização | `lib/l10n/` | Mantém ARBs em inglês e português, a configuração gerada e a extensão `context.l10n`. |
| Assets gerados | `lib/gen/` | Expõe acesso tipado aos assets declarados no `pubspec.yaml`. |
| Assets | `assets/audio/`, `assets/images/`, `assets/licenses/` | Armazena trilhas, efeitos, sprites, cenários e a licença da fonte Poppins. |
| Test helpers | `test/helpers/` | Reúne montagem de widgets, mocks e uma instância de jogo voltada à suíte automatizada. |

## Configuração

| Componente | Arquivo | Responsabilidade |
|-----------|---------|-----------------|
| Manifesto | `pubspec.yaml` | Define o pacote `arcade_one` `1.0.0+1`, SDKs, dependências, geração e diretórios de assets. |
| Entry points | `lib/main_development.dart`, `lib/main_staging.dart`, `lib/main_production.dart` | Inicializam cada flavor e entregam o `SharedPreferences` carregado ao `App`. |
| Bootstrap | `lib/bootstrap.dart` | Configura erros Flutter, `BlocObserver`, licença Poppins, contexto global de áudio, Mobile Ads, `SharedPreferences` e `runApp`. |
| Composição global | `lib/app/view/app.dart` | Registra o repository/provider e os Cubits, cria o `MaterialApp`, tema, delegates de localização e `LoadingPage`. |
| Navegação | `lib/loading/view/loading_page.dart`, `lib/title/content/title_start_button.dart`, `lib/game/view/game_page.dart` | Implementa o fluxo manual entre loading, título e jogo. |
| Localização | `l10n.yaml` | Usa `lib/l10n/arb/app_en.arb` como template e gera a saída em `lib/l10n/gen/`. |
| Análise estática | `analysis_options.yaml` | Inclui Very Good Analysis e Bloc Lint e exclui as saídas geradas. |
| Flavors e ícones | `flutter_launcher_icons-development.yaml`, `flutter_launcher_icons-staging.yaml`, `flutter_launcher_icons-production.yaml` | Mantém configurações de ícone específicas de cada flavor. |
| Plataformas | `android/`, `ios/`, `macos/`, `web/`, `windows/` | Contém os projetos e arquivos de integração gerados para cada plataforma. |

## Dependências Externas Principais

| Pacote | Versão | Uso no projeto |
|--------|--------|---------------|
| `bloc` | `^9.2.0` | Base de Cubit e `BlocObserver`; usado diretamente no bootstrap e no preload. |
| `flutter_bloc` | `^9.1.1` | Providers, builders, listeners e acesso aos Cubits na interface Flutter. |
| `flame` | `^1.37.0` | `FlameGame`, `GameWidget`, eventos, componentes e cache de imagens da partida. |
| `audioplayers` | `^6.6.0` | Cache e reprodução do efeito de morte, loop do motor da nave e configuração global de volume. |
| `equatable` | `^2.0.8` | Igualdade dos estados de preload e áudio. |
| `shared_preferences` | `^2.3.0` | Backend local para locale, volume, modo de controle, nave escolhida e melhor distância. |
| `google_mobile_ads` | `^9.0.0` | Inicialização do SDK, banner com fallback e intersticial de game over em Android e iOS. |
| `google_fonts` | `^8.1.0` | Aplica Poppins ao tema do `MaterialApp`. |
| `flutter_localizations` | SDK Flutter | Fornece os delegates usados pelas localizações geradas. |
| `bloc_test` | `^10.0.0` | Suporte aos testes de Cubit. |
| `flame_test` | `^2.2.4` | Suporte aos testes de entidades e componentes Flame. |
| `mocktail` | `^1.0.5` | Mocks em testes unitários e de widgets. |
| `mockingjay` | `^2.1.0` | Mocks de navegação nos testes de widgets. |
| `very_good_analysis` | `^10.2.0` | Conjunto principal de regras do analyzer. |
| `bloc_lint` | `^0.4.1` | Regras específicas para Bloc e Cubit. |

## Observações

- A revisão partiu de uma árvore Git limpa no commit `698131b`; as alterações desta regeneração ficam restritas à documentação e às instruções do projeto.
- Os três entry points de flavor executam a mesma inicialização; `lib/bootstrap.dart` mantém o ponto indicado para configuração específica por flavor.
- Não há router nem service locator: a navegação é manual e a composição de dependências usa providers do `flutter_bloc`.
- `PreloadCubit` carrega antecipadamente `Assets.audio.death`, `Assets.audio.engineFire`, `Assets.images.unicornAnimation.path` e `gameImageAssets`; não há música de fundo — `ArcadeOne` toca `engine_fire.mp3` em loop enquanto a nave impulsiona.
- O catálogo de naves e o catálogo de marcos espaciais compartilham os mesmos limiares de distância, de `0`/Terra até `8500` km/quasar profundo.
- O banner possui IDs apenas para Android e iOS; em outras plataformas `AdConfig.maybeBanner` retorna `null` e a interface não reserva o espaço do anúncio.
- A suíte em `test/` espelha `app`, `common`, `loading`, `title` e `game`, cobrindo Cubits, widgets, storage, catálogos, entidades e componentes Flame.
