# Arcade One

Jogo arcade espacial multiplataforma em Flutter, com Cubits na interface e Flame na cena jogável.

## Stack e arquitetura

- Dart `^3.11.0` e Flutter `^3.41.0`
- `flutter_bloc`/`bloc` para Cubits e providers globais; `flame` para gameplay
- `audioplayers` para BGM e efeito de morte; Google Mobile Ads para banners
- `shared_preferences` atrás de `StorageService`
- Very Good Analysis e `bloc_lint`; flavors `development`, `staging` e `production`
- Fluxo principal: entry point → `bootstrap` → providers globais → loading → title → `GameWidget<ArcadeOne>`

## Estrutura

- `lib/main_development.dart`, `lib/main_staging.dart`, `lib/main_production.dart` — entry points que chamam `bootstrap((prefs) => App(prefs: prefs))`
- `lib/bootstrap.dart` — erros globais, observer de Bloc, licença Poppins, áudio, anúncios, preferências e `runApp`
- `lib/app/` — providers globais, locale, tema, orientação e `LoadingPage`
- `lib/common/` — abstração/implementação de storage, anúncios e widgets compartilhados
- `lib/loading/` — preload sequencial, estado de progresso e tela de loading
- `lib/title/` — idioma, volume, controle, seleção de nave e início da partida
- `lib/game/` — `ArcadeOne`, áudio, entidades, componentes, HUD, background, anúncios e tela do jogo
- `lib/l10n/` — ARBs, localizações geradas e extensão `context.l10n`
- `assets/` — áudios, sprites, cenários e licença Poppins
- `test/` — espelha os módulos e mantém helpers em `test/helpers/`

## Comandos

- `flutter run --flavor development --target lib/main_development.dart` — executa development
- `flutter run --flavor staging --target lib/main_staging.dart` — executa staging
- `flutter run --flavor production --target lib/main_production.dart` — executa production
- `flutter test --coverage --test-randomize-ordering-seed random` — executa a suíte documentada
- `dart run bloc_tools:bloc lint .` — executa os lints específicos de Bloc
- `flutter gen-l10n` — regenera `lib/l10n/gen/` após mudanças nos ARBs

## Convenções

- Siga o padrão atual de Cubits: locale em `app`, preload em `loading`, áudio em `game` e escolhas da tela inicial em `title`.
- Forneça dependências globais com os providers existentes; consumidores de persistência dependem de `StorageService`, não de `SharedPreferences`.
- Mantenha a navegação manual com `Navigator.pushReplacement` e `MaterialPageRoute`; não há router.
- Adicione strings visíveis em `lib/l10n/arb/app_en.arb` e `lib/l10n/arb/app_pt.arb`; acesse-as por `context.l10n`.
- Trate `lib/gen/` e `lib/l10n/gen/` como saída gerada, nunca como código autoral.
- Espelhe a feature em `test/` e reutilize `test/helpers/pump_app.dart` na montagem de widgets.

## Gotchas

- Os três entry points fazem a mesma inicialização; configuração específica de flavor pertence ao ponto marcado em `lib/bootstrap.dart`.
- `PreloadCubit` antecipa `Assets.audio.death`, `Assets.images.unicornAnimation.path` e `gameImageAssets`; a BGM `assets/audio/background_2.mp3` inicia no `AudioCubit`.
- `GamePage`/`GameView` esperam `PreloadCubit`, `AudioCubit` e `StorageService` acima dela; `GameOverPopup` lê `ShareService` do contexto ao compartilhar a run.
- A melhor distância usa a chave `best_distance_km` e persiste por `StorageService`; ela também controla o desbloqueio de naves e o quick play da primeira run.
- Sem `best_distance_km` persistido, `LoadingPage` abre `GamePage(quickPlay: true)` com overlay "toque para jogar" e `ArcadeOne.waitingToStart`; depois da primeira run, o título volta a ser a entrada.
- O banner possui IDs apenas para Android e iOS; outras plataformas omitem o anúncio.

## Não fazer

- Não rode `flutter pub upgrade` sem solicitação explícita.
- Não hardcode strings visíveis em widgets.
- Não edite manualmente localizações ou assets gerados.
- Não substitua o fluxo atual de `Navigator` por um router sem uma tarefa específica de arquitetura de navegação.

## 📖 Documentação de Flows

Para qualquer feature ou fluxo, verifique a pasta `./docs/flow/`: leia os títulos dos arquivos `.md` disponíveis e, se algum for relevante para a tarefa atual, leia-o antes de implementar ou debugar. Invoque a skill `flow` para criar ou atualizar flows individuais.

## 🧪 Teste funcional

Após implementar, não execute o projeto para validar o resultado (rodar o app, emulador/simulador, dispositivo físico, servidor local, screenshots ou interação simulada). Teste funcional/visual é responsabilidade do usuário.

- Limite a verificação a análise estática, build/compile e testes automatizados
- Ao concluir, liste objetivamente o que o usuário deve testar manualmente
- Não pergunte se deve executar o projeto — só faça isso se o usuário pedir explicitamente
