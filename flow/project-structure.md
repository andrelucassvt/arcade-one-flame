# Estrutura do Projeto: Arcade One

> **Resumo:** Aplicativo Flutter/Dart de jogo casual com Flame, organizado em features verticais com Cubits para carregamento e audio.

## Stack e Tecnologias

| Elemento | Valor |
|----------|-------|
| Linguagem | Dart `^3.11.0` |
| Framework | Flutter `^3.41.0`, Flame |
| Gerenciador de pacotes | pub |
| Principais dependencias | `flutter_bloc`, `bloc`, `flame`, `flame_audio`, `audioplayers`, `equatable`, `google_fonts`, `intl` |

## Arquitetura

O projeto usa uma estrutura feature-first em `lib/`, com `app`, `loading`, `title` e `game` separados por responsabilidade. A UI Flutter usa `MaterialApp`, `Navigator`/`MaterialPageRoute` e `flutter_bloc`; o jogo em si fica em `ArcadeOne`, uma classe `FlameGame`, com entidades, behaviors e componentes de Flame. O preload de assets e o controle de audio ficam em Cubits, enquanto assets e l10n sao acessados por codigo gerado.

```text
main_* -> bootstrap -> App -> LoadingPage -> TitlePage -> GamePage
Flutter UI -> Cubit state -> Flame Game -> Entities/Behaviors/Components
Assets/ARB -> generated code -> UI/Game
```

### Regras de dependencia

- `lib/app` inicializa o `PreloadCubit` e define `LoadingPage` como tela inicial.
- `lib/loading` depende de `lib/title` para navegar quando o preload completa.
- `lib/title` depende de `lib/game` para iniciar o jogo.
- `lib/game` depende de `lib/loading/cubit` para reaproveitar os caches de imagens e audio ja carregados.
- Arquivos gerados ficam em `lib/gen` e `lib/l10n/gen` e sao excluidos do analyzer.

## Features

Lista das features/modulos/dominios detectados no projeto.

| Feature | Caminho principal | Descricao resumida |
|---------|------------------|-------------------|
| App | `lib/app/` | Compoe os providers globais, tema, l10n e tela inicial do aplicativo. |
| Loading | `lib/loading/` | Precarrega audio e imagens, mostra progresso e navega para a tela de titulo ao concluir. |
| Title | `lib/title/` | Exibe a tela inicial do jogo e aciona a navegacao para `GamePage`. |
| Game | `lib/game/` | Implementa a tela do jogo, audio, `ArcadeOne`, nave com inercia, obstaculos, HUD e restart. |
| L10n | `lib/l10n/` | Centraliza ARB, codigo gerado de localizacao e extensao `context.l10n`. |

## Camadas / Modulos Compartilhados

Liste os componentes de uso global (fora das features individuais).

| Tipo | Caminho | Responsabilidade |
|------|---------|-----------------|
| Bootstrap | `lib/bootstrap.dart` | Configura tratamento de erros Flutter, `Bloc.observer`, licenca da fonte Poppins e executa `runApp`. |
| Entry points | `lib/main_development.dart`, `lib/main_staging.dart`, `lib/main_production.dart` | Entradas por flavor que chamam `bootstrap(() => const App())`. |
| Assets gerados | `lib/gen/assets.gen.dart` | Acesso tipado aos assets declarados no `pubspec.yaml`. |
| L10n | `lib/l10n/` | ARB, delegados gerados e extensao de acesso a localizacao. |
| Test helpers | `test/helpers/` | Helpers para `pumpApp`, mocks de Cubit/Navigator e `TestGame` para testes de Flame. |
| Assets | `assets/audio/`, `assets/images/`, `assets/licenses/poppins/` | Musica de fundo, efeito sonoro, imagens legadas e licenca da fonte. |

## Configuracao

| Componente | Arquivo | Responsabilidade |
|-----------|---------|-----------------|
| Dependencias e assets | `pubspec.yaml` | Define SDKs, pacotes, assets e geracao Flutter. |
| Analyzer e lints | `analysis_options.yaml` | Inclui `very_good_analysis` e `bloc_lint`, excluindo arquivos gerados. |
| Localizacao | `l10n.yaml` | Configura entrada ARB e saida em `lib/l10n/gen`. |
| Bootstrap | `lib/bootstrap.dart` | Configura erros, observer de Bloc, licenca Poppins e startup. |
| Navegacao | `lib/app/view/app.dart`, `lib/loading/view/loading_page.dart`, `lib/title/view/title_page.dart`, `lib/game/view/game_page.dart` | Usa `home: LoadingPage`, `Navigator.pushReplacement` e rotas `MaterialPageRoute`. |
| CI | `.github/workflows/main.yaml` | Roda semantic PR, pacote Flutter com bloc lint e spell check via Very Good Workflows. |
| License check | `.github/workflows/license_check.yaml` | Verifica licencas permitidas quando `pubspec.yaml` ou workflow mudam. |

## Dependencias Externas Principais

| Pacote / Biblioteca | Versao | Uso no projeto |
|--------------------|--------|---------------|
| `flutter_bloc` | `^9.1.1` | Providers, listeners e builders dos Cubits. |
| `bloc` | `^9.2.0` | Base dos Cubits e `BlocObserver`. |
| `flame` | `^1.37.0` | Engine do jogo, `FlameGame`, componentes, camera e cache de imagens. |
| `flame_audio` | `^2.12.1` | Musica de fundo com `Bgm`. |
| `audioplayers` | `^6.6.0` | Player do efeito sonoro e cache de audio. |
| `equatable` | `^2.0.8` | Igualdade de estados dos Cubits. |
| `google_fonts` | `^8.1.0` | Tema Poppins no `MaterialApp`. |
| `intl` | `^0.20.2` | Suporte de internacionalizacao gerada. |
| `bloc_test` | `^10.0.0` | Testes de Cubit. |
| `flame_test` | `^2.2.4` | Testes de componentes/entidades Flame. |
| `mocktail` | `^1.0.5` | Mocks em testes unitarios. |
| `mockingjay` | `^2.1.0` | Mocks de navegacao em testes de widgets. |
| `very_good_analysis` | `^10.2.0` | Regras de lint. |
| `bloc_lint` | `^0.4.1` | Lints especificos de Bloc. |

## Observacoes

- O README declara suporte a iOS, Android, Web e Windows; o reposititorio tambem contem pasta `macos/`, mas os comandos documentados usam flavors Flutter.
- Os tres entry points de flavor ainda fazem a mesma inicializacao; `bootstrap.dart` contem o comentario `Add cross-flavor configuration here`.
- A navegacao e manual com `Navigator`, sem pacote de router dedicado.
- A cobertura de testes acompanha as features principais (`app`, `loading`, `title`, `game`) e inclui testes de Cubit, widgets e entidades/componentes Flame.
