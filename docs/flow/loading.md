# Flow: Loading

> **Resumo:** Precarrega audio e imagens, mostra o progresso ao usuario e navega automaticamente para a tela de titulo quando conclui.

## Visão Geral

O fluxo de loading e iniciado pelo `App`, que cria um `PreloadCubit` global e chama `loadSequentially`. Esse Cubit recebe os caches de imagem e audio e percorre uma lista fixa de fases: `audio` e `images`.

Enquanto as fases rodam, `LoadingPage` observa o estado do Cubit. A UI traduz o label da fase atual via l10n, mostra uma mensagem de carregamento e anima a barra de progresso com base em `loadedCount / totalCount`.

Quando `PreloadState.isComplete` passa a ser verdadeiro, `LoadingPage` espera a duracao intrinseca da animacao da barra e faz `pushReplacement` para `TitlePage.route()`.

## Passo a Passo

1. **Provider global** — `lib/app/view/app.dart` → `App.build`
   Cria `PreloadCubit` com `Images(prefix: '')` e `AudioCache(prefix: '')`, entao chama `loadSequentially`.
2. **Cubit** — `lib/loading/cubit/preload/preload_cubit.dart` → `PreloadCubit.loadSequentially`
   Define as fases `audio` e `images`, emite o `totalCount` e executa cada fase em ordem.
3. **Assets de audio** — `lib/loading/cubit/preload/preload_cubit.dart` → fase `audio`
   Carrega `Assets.audio.background` e `Assets.audio.effect` com `AudioCache.loadAll`.
4. **Assets de imagem** — `lib/loading/cubit/preload/preload_cubit.dart` → fase `images`
   Carrega `Assets.images.unicornAnimation.path` com `Images.loadAll`.
5. **Throttle visual** — `lib/loading/cubit/preload/preload_cubit.dart` → `Future.wait`
   Cada fase demora pelo menos 200ms para permitir feedback visual.
6. **Estado** — `lib/loading/cubit/preload/preload_state.dart` → `PreloadState`
   Calcula `progress` e `isComplete` a partir de `loadedCount` e `totalCount`.
7. **UI** — `lib/loading/view/loading_page.dart` → `_LoadingInternal.build`
   Usa `BlocBuilder` para renderizar `AnimatedProgressBar` e mensagem localizada.
8. **Navegacao** — `lib/loading/view/loading_page.dart` → `BlocListener`
   Quando `isComplete` muda para verdadeiro, chama `onPreloadComplete`.
9. **Destino** — `lib/loading/view/loading_page.dart` → `onPreloadComplete`
   Aguarda `AnimatedProgressBar.intrinsicAnimationDuration`, valida `mounted` e troca a tela por `TitlePage.route()`.

## Arquivos Envolvidos

| Camada | Arquivo | Responsabilidade |
|--------|---------|------------------|
| Apresentacao | `lib/loading/view/loading_page.dart` | Renderiza loading, escuta conclusao e navega para title. |
| Widget | `lib/loading/widgets/animated_progress_bar.dart` | Barra de progresso animada usada na tela de loading. |
| Cubit | `lib/loading/cubit/preload/preload_cubit.dart` | Orquestra o carregamento sequencial dos assets. |
| Estado | `lib/loading/cubit/preload/preload_state.dart` | Guarda total, carregados, label atual, progresso e conclusao. |
| Assets gerados | `lib/gen/assets.gen.dart` | Fornece caminhos tipados de audio, imagem e licenca. |
| L10n | `lib/l10n/arb/app_en.arb` | Define textos `loading` e `loadingPhaseLabel`. |
| Barrel | `lib/loading/loading.dart` | Exporta cubit, view e widgets da feature. |
| Testes | `test/loading/cubit/preload/preload_cubit_test.dart` | Cobre comportamento do `PreloadCubit`. |
| Testes | `test/loading/cubit/preload/preload_state_test.dart` | Cobre estado e calculos do preload. |
| Testes | `test/loading/view/loading_page_test.dart` | Cobre UI e navegacao apos conclusao. |

## Regras de Negócio Relevantes

- **Fases fixas de preload** — `lib/loading/cubit/preload/preload_cubit.dart`: apenas `audio` e `images` sao carregados.
- **Progresso derivado** — `lib/loading/cubit/preload/preload_state.dart`: `progress` e `loadedCount / totalCount`, com fallback `0` quando `totalCount == 0`.
- **Conclusao por progresso total** — `lib/loading/cubit/preload/preload_state.dart`: `isComplete` e verdadeiro somente quando `progress == 1.0`.
- **Transicao pos-animacao** — `lib/loading/view/loading_page.dart`: a navegacao espera `AnimatedProgressBar.intrinsicAnimationDuration`.

## Dependências Externas

- `flutter_bloc` para `BlocBuilder` e `BlocListener`.
- `flame` para cache de imagens.
- `audioplayers` para cache de audio.
- `equatable` para igualdade do estado.

## Observações

- O label das fases e uma string interna (`audio`, `images`) traduzida por `loadingPhaseLabel` em ARB.
- Nao ha tratamento especifico de erro para falha no carregamento dos assets.
