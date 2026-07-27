---
generated_at: 2026-07-27
source_commit: 2bc98a5
source_state: dirty
verified_at: 2026-07-27
status: current
related_plans: []
---

# Flow: Loading

> **Resumo:** Precarrega o efeito de morte e as imagens da partida, mostra o progresso localizado e troca a tela por `TitleView` ao concluir.

## Visão Geral

O fluxo começa durante a montagem de `App`, que cria um `PreloadCubit` global com caches de imagens e áudio sem prefixo e dispara `loadSequentially`. O carregamento é dividido em duas fases executadas em ordem: `audio` e `images`.

O Cubit emite o total de fases, o label da fase atual e a quantidade concluída. `LoadingPage` transforma esse estado em mensagem localizada e progresso visual; cada fase dura pelo menos 200 ms para que a atualização seja perceptível.

Quando `PreloadState.isComplete` muda de falso para verdadeiro, a tela aguarda os 300 ms da animação da barra, confirma que ainda está montada e usa `Navigator.pushReplacement` para abrir `TitleView`.

## Passo a Passo

1. **Provider global** — `lib/app/view/app.dart` → `App.build`
   Cria `PreloadCubit(Images(prefix: ''), AudioCache(prefix: ''))` e dispara `loadSequentially`.
2. **Definição das fases** — `lib/loading/cubit/preload/preload_cubit.dart` → `PreloadCubit.loadSequentially`
   Monta uma lista com as fases `audio` e `images` e emite `totalCount: 2`.
3. **Preload de áudio** — `lib/loading/cubit/preload/preload_cubit.dart` → fase `audio`
   Carrega `Assets.audio.death` com `AudioCache.loadAll`.
4. **Preload de imagens** — `lib/loading/cubit/preload/preload_cubit.dart` → fase `images`
   Carrega `Assets.images.unicornAnimation.path` e todos os caminhos de `gameImageAssets` com `Images.loadAll`.
5. **Execução sequencial** — `lib/loading/cubit/preload/preload_cubit.dart` → loop de `PreloadPhase`
   Emite `currentLabel`, aguarda o carregamento e um atraso mínimo de 200 ms e incrementa `loadedCount` ao terminar cada fase.
6. **Progresso derivado** — `lib/loading/cubit/preload/preload_state.dart` → `PreloadState`
   Calcula `progress` como `loadedCount / totalCount` e `isComplete` quando o resultado chega a `1.0`.
7. **Renderização** — `lib/loading/view/loading_page.dart` → `_LoadingInternal.build`
   `BlocBuilder` localiza o label com `loadingPhaseLabel`, monta a mensagem `loading` e atualiza `AnimatedProgressBar`.
8. **Detecção da conclusão** — `lib/loading/view/loading_page.dart` → `BlocListener`
   Escuta somente a transição de um estado incompleto para um estado completo e chama `onPreloadComplete`.
9. **Transição de tela** — `lib/loading/view/loading_page.dart` → `onPreloadComplete`
   Aguarda `AnimatedProgressBar.intrinsicAnimationDuration`, verifica `mounted` e executa `navigator.pushReplacement(TitleView.route())`.

### Caminhos alternativos

- **Widget desmontado durante a espera:** `onPreloadComplete` retorna sem navegar quando `mounted` é falso.

## Arquivos Envolvidos

| Camada | Arquivo | Responsabilidade |
|--------|---------|------------------|
| Configuração / origem | `lib/app/view/app.dart` | Cria os caches, fornece o Cubit e inicia o preload. |
| Estado / Cubit | `lib/loading/cubit/preload/preload_cubit.dart` | Define e executa as fases sequenciais. |
| Estado | `lib/loading/cubit/preload/preload_state.dart` | Guarda contadores e label e deriva progresso e conclusão. |
| Apresentação | `lib/loading/view/loading_page.dart` | Exibe o estado, detecta conclusão e navega para a Title. |
| Widget | `lib/loading/widgets/animated_progress_bar.dart` | Anima visualmente o progresso durante 300 ms. |
| Assets | `lib/game/game_image_assets.dart` | Lista as imagens usadas pela partida e incluídas no preload. |
| Assets gerados | `lib/gen/assets.gen.dart` | Fornece os caminhos tipados do efeito de morte e da imagem legada. |
| Localização | `lib/l10n/arb/app_en.arb` | Define as mensagens e labels de loading em inglês. |
| Localização | `lib/l10n/arb/app_pt.arb` | Define as mensagens e labels de loading em português. |
| Destino | `lib/title/view/title_page.dart` | Expõe `TitleView.route`, destino após a conclusão. |
| Testes | `test/loading/cubit/preload/preload_cubit_test.dart` | Cobre ordem, estados emitidos e chamadas aos caches. |
| Testes | `test/loading/cubit/preload/preload_state_test.dart` | Cobre estado inicial, progresso e conclusão. |
| Testes | `test/loading/view/loading_page_test.dart` | Cobre layout, textos localizados e navegação. |

## Regras de Negócio Relevantes

- **Duas fases fixas e sequenciais** — `lib/loading/cubit/preload/preload_cubit.dart`: áudio termina antes de imagens.
- **Assets de áudio limitados ao preload** — `lib/loading/cubit/preload/preload_cubit.dart`: somente `Assets.audio.death` é antecipado; a BGM não entra nessa fase.
- **Catálogo único de imagens do jogo** — `lib/game/game_image_assets.dart`: asteroides, meteoro, naves e cenários são reunidos em `gameImageAssets`.
- **Duração visual mínima** — `lib/loading/cubit/preload/preload_cubit.dart`: cada fase aguarda pelo menos 200 ms.
- **Navegação após a animação** — `lib/loading/view/loading_page.dart`: a troca de tela espera os 300 ms definidos por `AnimatedProgressBar`.
- **Substituição da rota** — `lib/loading/view/loading_page.dart`: `pushReplacement` remove a Loading da pilha.

## Dependências Externas

- `flutter_bloc` e `bloc` para estado, renderização e listener.
- `flame` para `Images`.
- `audioplayers` para `AudioCache`.
- `equatable` para igualdade de `PreloadState`.

## Observações

- Os labels `audio` e `images` são identificadores internos convertidos em texto por `loadingPhaseLabel` nos ARBs.
- Não existe tratamento específico de erro ou retry; uma exceção de cache interrompe `loadSequentially` antes de o estado chegar a completo.
- `Assets.images.unicornAnimation.path` ainda é carregado, embora a gameplay atual use a nave em `lib/game/entities/ship/ship.dart`.
