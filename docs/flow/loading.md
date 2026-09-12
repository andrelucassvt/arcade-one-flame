---
generated_at: 2026-07-27
source_commit: 698131b
source_state: clean
verified_at: 2026-09-12
status: current
related_plans: []
---

# Flow: Loading

> **Resumo:** Precarrega sequencialmente o efeito de morte e as imagens da partida, publica progresso localizado e substitui a tela por `TitleView` ao concluir.

## Visão Geral

`App` cria um `PreloadCubit` global com caches de imagens e áudio configurados sem prefixo. A carga começa imediatamente e possui duas fases em ordem fixa: `audio` e `images`.

O Cubit publica total, quantidade concluída e label da fase atual. `LoadingPage` transforma esse estado em barra animada e mensagem localizada, impondo duração mínima de 200 ms por fase para tornar a progressão perceptível.

Quando o estado passa a completo, a tela aguarda os 300 ms da animação da barra e usa `Navigator.pushReplacement` para abrir `TitleView`. Não existe estado de erro ou retry: uma exceção durante o preload interrompe o método antes da navegação.

## Passo a Passo

1. **Provider global** — `lib/app/view/app.dart` → `App.build`
   Cria `PreloadCubit(Images(prefix: ''), AudioCache(prefix: ''))` e dispara `loadSequentially` sem aguardar.
2. **Planejamento das fases** — `lib/loading/cubit/preload/preload_cubit.dart` → `PreloadCubit.loadSequentially`
   Monta as fases `audio` e `images` e emite `totalCount: 2`.
3. **Fase de áudio** — `lib/loading/cubit/preload/preload_cubit.dart` → `audio.loadAll`
   Precarrega somente `Assets.audio.death`.
4. **Fase de imagens** — `lib/loading/cubit/preload/preload_cubit.dart` → `images.loadAll`
   Precarrega `Assets.images.unicornAnimation.path` e todos os caminhos de `gameImageAssets`.
5. **Controle de duração** — `lib/loading/cubit/preload/preload_cubit.dart` → loop de fases
   Aguarda em paralelo a operação da fase e um atraso de 200 ms; só depois incrementa `loadedCount`.
6. **Cálculo de progresso** — `lib/loading/cubit/preload/preload_state.dart` → `progress` e `isComplete`
   Divide carregados pelo total e considera completo apenas quando o resultado é exatamente `1.0`.
7. **Apresentação** — `lib/loading/view/loading_page.dart` → `_LoadingInternal.build`
   Localiza o label de `currentLabel`, monta a mensagem e entrega `progress` ao `AnimatedProgressBar`.
8. **Detecção de conclusão** — `lib/loading/view/loading_page.dart` → `BlocListener.listenWhen`
   Reage somente à transição de incompleto para completo.
9. **Saída da tela** — `lib/loading/view/loading_page.dart` → `onPreloadComplete`
   Aguarda `AnimatedProgressBar.intrinsicAnimationDuration`, confirma `mounted` e substitui a rota por `TitleView.route()`.

### Caminhos alternativos

- **Estado ainda inicial:** com `totalCount == 0`, o progresso é `0` e o label localizado cai no caso `other`.
- **Widget desmontado durante o atraso final:** a verificação de `mounted` evita a navegação.
- **Falha de asset:** não há captura nem estado de falha em `PreloadCubit`; a conclusão não é emitida e `LoadingPage` permanece sem retry visível.

## Arquivos Envolvidos

| Camada | Arquivo | Responsabilidade |
|--------|---------|------------------|
| Composição | `lib/app/view/app.dart` | Cria caches, Cubit e inicia o preload. |
| Estado | `lib/loading/cubit/preload/preload_cubit.dart` | Executa as fases e publica contadores/labels. |
| Estado | `lib/loading/cubit/preload/preload_state.dart` | Modela progresso e conclusão. |
| Apresentação | `lib/loading/view/loading_page.dart` | Exibe o estado e navega ao concluir. |
| Apresentação | `lib/loading/widgets/animated_progress_bar.dart` | Anima visualmente o valor de progresso. |
| Assets | `lib/game/game_image_assets.dart` | Lista as imagens do gameplay incluídas no preload. |
| Localização | `lib/l10n/arb/app_en.arb` | Define mensagens e labels das fases em inglês. |
| Localização | `lib/l10n/arb/app_pt.arb` | Define mensagens e labels das fases em português. |
| Testes | `test/loading/cubit/preload/preload_cubit_test.dart` | Cobre sequência de estados e chamadas aos caches. |
| Testes | `test/loading/cubit/preload/preload_state_test.dart` | Cobre cálculo de progresso e conclusão. |
| Testes | `test/loading/view/loading_page_test.dart` | Cobre layout, labels e redirecionamento. |

## Regras de Negócio Relevantes

- **Ordem fixa** — `lib/loading/cubit/preload/preload_cubit.dart`: áudio termina antes do início da fase de imagens.
- **Tempo mínimo visível** — `lib/loading/cubit/preload/preload_cubit.dart`: cada fase dura pelo menos 200 ms.
- **Transição após animação** — `lib/loading/view/loading_page.dart`: a rota só muda após os 300 ms intrínsecos da barra.
- **Assets da rodada prontos antes do título** — `lib/loading/cubit/preload/preload_cubit.dart`: `gameImageAssets` é carregado integralmente antes de `TitleView` abrir.

## Dependências Externas

- Flame `Images` para cache de imagens.
- `audioplayers` `AudioCache` para cache do efeito de morte.
- `bloc`/`flutter_bloc` para estado e reação de conclusão.

## Observações

- O spritesheet `unicorn_animation.png` continua no preload, embora não tenha consumidor no gameplay atual.
- `test/loading/cubit/preload/preload_cubit_test.dart` ainda espera `Assets.audio.engineFire` junto de `Assets.audio.death`, enquanto a implementação carrega apenas o efeito de morte; essa divergência é objetiva e pode causar falha no teste do Cubit.
- A BGM é iniciada posteriormente pelo `AudioCubit` e não participa deste preload.
