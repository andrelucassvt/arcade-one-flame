# Implementar MVP do DRIFT

> **Objetivo:** Entregar um MVP jogavel de DRIFT em Flutter/Flame com nave por inercia, scroll vertical, obstaculos simples, pontuacao por distancia e estado de game over.

## Contexto

O projeto atual ja possui uma base Flutter com Flame, audio pre-carregado, `GamePage`, `GameWidget`, testes de jogo e um fluxo documentado em `flow/game.md`. Hoje o jogo e um prototipo simples de tocar no unicornio para incrementar contador. O MVP de DRIFT deve reaproveitar essa estrutura, mas trocar a mecanica principal por uma experiencia de navegacao espacial baseada em momentum, conforme descrito em `ideia.md`.

Para reduzir risco, o MVP nao inclui monetizacao, skins, missoes, rewarded ads, satelites em orbita, clusters de detritos, trilhas por zona ou arte final. A primeira entrega foca no loop central: controlar a nave, sobreviver, passar por gaps e reiniciar apos colisao.

## Arquitetura / Escopo

| Arquivo | Acao | Responsabilidade |
|---------|------|-----------------|
| `test/game/arcade_one_test.dart` | criar/atualizar | Cobrir inicializacao do jogo DRIFT, pontuacao por distancia, game over e reset. |
| `test/game/entities/ship/ship_test.dart` | criar | Validar aceleracao em direcao ao toque, inercia, limite de velocidade e rotacao visual da nave. |
| `test/game/components/asteroid_pair_component_test.dart` | criar | Validar tamanho do gap, movimento vertical, variacao por dificuldade e colisao. |
| `test/game/components/drift_hud_component_test.dart` | criar | Validar texto de distancia e estado de game over no HUD Flame. |
| `lib/game/arcade_one.dart` | atualizar | Manter a classe principal `ArcadeOne`, mas substituir o jogo de unicornio pelo loop de DRIFT. |
| `lib/game/entities/ship/ship.dart` | criar | Representar a nave, fisica de thrust, velocidade, rotacao, trail e bounds de morte. |
| `lib/game/entities/ship/entities.dart` | criar | Barrel export da entidade da nave. |
| `lib/game/entities/entities.dart` | atualizar | Remover export principal do unicornio e exportar `ship/entities.dart`. |
| `lib/game/components/asteroid_pair_component.dart` | criar | Obstaculo MVP com dois asteroides retangulares e gap central. |
| `lib/game/components/starfield_component.dart` | criar | Fundo parallax simples com duas camadas de estrelas desenhadas por Flame. |
| `lib/game/components/drift_hud_component.dart` | criar | HUD de distancia, melhor pontuacao da sessao e mensagem de restart. |
| `lib/game/components/components.dart` | atualizar | Exportar os novos componentes e remover dependencias de `CounterComponent` se nao forem mais usadas. |
| `lib/game/view/game_page.dart` | atualizar | Preservar `AudioCubit` e `GameWidget`, conectando input/restart ao novo jogo quando necessario. |
| `lib/l10n/arb/app_en.arb` | atualizar | Trocar textos de contador por textos de DRIFT: distancia, game over e restart. |
| `lib/title/view/title_page.dart` | atualizar | Ajustar titulo/copy inicial para DRIFT sem alterar a navegacao para `GamePage.route()`. |
| `flow/game.md` | atualizar | Documentar o novo fluxo UI -> GameWidget -> ArcadeOne -> Ship -> Obstacles -> HUD. |

## Fases

### Fase 1 — Testes (contrato antes da implementacao)

> Escreva os testes que definem o comportamento esperado. Eles vao falhar inicialmente — isso e intencional.

- [ ] Criar `test/game/entities/ship/ship_test.dart`.
- [ ] Testar caso de sucesso: ao aplicar thrust para um ponto acima/ao lado da nave, a velocidade acumula nessa direcao e a posicao muda apos `update`.
- [ ] Testar caso de inercia: ao soltar o thrust, a nave continua se movendo com a velocidade acumulada, sem parar instantaneamente.
- [ ] Testar limite de velocidade: thrust continuo nao ultrapassa `maxShipSpeed`.
- [ ] Criar `test/game/components/asteroid_pair_component_test.dart`.
- [ ] Testar caso de sucesso: `AsteroidPairComponent` cria dois corpos com um gap atravessavel e diminui o gap quando a dificuldade aumenta.
- [ ] Testar caso de colisao: intersecao entre nave e asteroide chama `ArcadeOne.endRun()`.
- [ ] Criar ou atualizar `test/game/arcade_one_test.dart`.
- [ ] Testar estado inicial: jogo carrega `Ship`, `StarfieldComponent`, `DriftHudComponent` e pelo menos um `AsteroidPairComponent`.
- [ ] Testar pontuacao: `distanceKm` aumenta com o tempo usando `speed = 2 + score * 0.0008`.
- [ ] Testar game over: tocar nas bordas da tela ou em obstaculo pausa a progressao, marca `isGameOver` e mostra a mensagem de restart.
- [ ] Testar reset: apos game over, chamada de restart zera distancia, reposiciona nave e limpa obstaculos antigos.
- [ ] Criar `test/game/components/drift_hud_component_test.dart`.
- [ ] Testar HUD: renderiza distancia em km enquanto vivo e mensagem de restart quando `isGameOver == true`.
- [ ] Verificacao: todos os testes compilam e falham pelos motivos certos, sem erros de sintaxe ou imports quebrados.

### Fase 2 — Modelo de jogo e fisica da nave

- [ ] Criar `lib/game/entities/ship/ship.dart` com `Ship` estendendo `PositionComponent` e armazenando `velocity`, `acceleration`, `maxSpeed`, `thrustPower` e `isThrusting`.
- [ ] Implementar `Ship.setThrustTarget(Vector2 target)` para calcular a direcao normalizada do thrust em relacao a posicao atual da nave.
- [ ] Implementar `Ship.clearThrust()` para desligar o propulsor sem zerar `velocity`.
- [ ] Implementar `Ship.update(double dt)` aplicando aceleracao quando `isThrusting`, mantendo inercia quando solto e limitando a velocidade acumulada.
- [ ] Implementar rotacao visual suave da nave para apontar na direcao do thrust ou da velocidade atual.
- [ ] Criar `lib/game/entities/ship/entities.dart` e atualizar `lib/game/entities/entities.dart`.
- [ ] Verificacao: testes de `ship_test.dart` passam sem alterar `GamePage`.

### Fase 3 — Loop principal do DRIFT em Flame

- [ ] Atualizar `lib/game/arcade_one.dart` para manter `ArcadeOne`, mas trocar `counter` por `distanceKm`, `bestDistanceKm`, `isGameOver`, `scrollSpeed`, `difficulty` e referencias para `Ship`/HUD.
- [ ] Adicionar mixins de input compatíveis com Flame para capturar pressionar/arrastar/soltar e direcionar `Ship.setThrustTarget`/`Ship.clearThrust`.
- [ ] Em `ArcadeOne.onLoad`, criar `World`, `CameraComponent`, `StarfieldComponent`, `Ship`, `DriftHudComponent` e a primeira leva de obstaculos.
- [ ] Em `ArcadeOne.update`, incrementar distancia enquanto vivo, aplicar a formula `speed = 2 + score * 0.0008`, mover obstaculos para baixo e spawnar novos pares de asteroides acima da tela.
- [ ] Implementar `ArcadeOne.endRun()` para marcar game over, congelar spawn/progressao, tocar `Assets.audio.effect` e atualizar melhor distancia da sessao.
- [ ] Implementar `ArcadeOne.restartRun()` para resetar nave, distancia, velocidade, obstaculos e estado de game over.
- [ ] Verificacao: `arcade_one_test.dart` passa e o jogo carrega sem referencias obrigatorias ao unicornio.

### Fase 4 — Obstaculos, colisao e fundo

- [ ] Criar `lib/game/components/asteroid_pair_component.dart` com dois blocos de asteroides, gap central e dimensoes responsivas ao tamanho visivel do jogo.
- [ ] Implementar ajuste de dificuldade no gap: iniciar largo na zona inicial e reduzir gradualmente conforme `distanceKm` aumenta, respeitando um gap minimo jogavel.
- [ ] Implementar movimento vertical relativo ao `scrollSpeed` e remover obstaculos que sairem da tela.
- [ ] Implementar colisao entre `Ship` e asteroides usando bounds simples de `PositionComponent` para o MVP.
- [ ] Criar `lib/game/components/starfield_component.dart` com duas camadas de estrelas parallax desenhadas em canvas, sem depender de novos assets.
- [ ] Atualizar `lib/game/components/components.dart` para exportar `AsteroidPairComponent`, `StarfieldComponent` e `DriftHudComponent`.
- [ ] Verificacao: testes de obstaculo passam e uma partida manual mostra fundo, nave e gaps atravessaveis.

### Fase 5 — HUD, textos e experiencia de MVP

- [ ] Criar `lib/game/components/drift_hud_component.dart` para exibir distancia atual em km, melhor distancia da sessao e mensagem de restart no game over.
- [ ] Atualizar `lib/l10n/arb/app_en.arb`, removendo ou deixando sem uso `counterText` e adicionando `distanceText`, `bestDistanceText`, `gameOverTitle` e `restartHint`.
- [ ] Rodar `flutter gen-l10n` para regenerar `lib/l10n/gen/app_localizations*.dart`.
- [ ] Atualizar `lib/title/view/title_page.dart` e as chaves de l10n relacionadas para comunicar `DRIFT` como jogo principal.
- [ ] Atualizar `test/title/view/title_page_test.dart` e `test/game/view/game_page_test.dart` para os novos textos, mantendo o botao de volume e a rota de jogo.
- [ ] Verificacao: tela inicial navega para o jogo, HUD mostra distancia e o restart funciona apos game over.

### Fase 6 — Limpeza de legado e validacao

- [ ] Remover ou isolar exports de `lib/game/entities/unicorn/` para que o jogo principal nao dependa mais da entidade antiga.
- [ ] Remover ou substituir testes antigos de `test/game/entities/unicorn/` que validavam a mecanica de toque no unicornio.
- [ ] Remover referencias a `CounterComponent` em `lib/game/arcade_one.dart`, `lib/game/components/components.dart` e testes.
- [ ] Rodar `dart format lib test`.
- [ ] Rodar `flutter test`.
- [ ] Rodar `flutter analyze`.
- [ ] Verificacao: formatacao, testes e analise passam sem erros.

### Fase 7 — Atualizar Flow

- [ ] Atualizar `flow/game.md` para trocar o resumo do fluxo de "tocar no unicornio" para "controlar nave com thrust e sobreviver ao scroll vertical".
- [ ] Atualizar o passo a passo com os novos pontos: `TitleView`, `GamePage`, `GameWidget`, `ArcadeOne.onLoad`, input de thrust, `Ship.update`, spawn de `AsteroidPairComponent`, colisao, HUD e restart.
- [ ] Atualizar a tabela de arquivos envolvidos com `Ship`, `AsteroidPairComponent`, `StarfieldComponent` e `DriftHudComponent`.
- [ ] Atualizar as regras de negocio para refletir inercia, morte por borda/colisao, pontuacao por distancia e reset de partida.
- [ ] Verificacao: `flow/game.md` descreve os arquivos e regras reais apos a implementacao.

## Criterios de Sucesso

- [ ] Ao iniciar o jogo, a tela mostra DRIFT com fundo espacial, nave centralizada, HUD de distancia e botao de volume.
- [ ] Segurar/arrastar na tela acelera a nave em direcao ao toque.
- [ ] Soltar a tela mantem a nave deslizando por inercia.
- [ ] A distancia aumenta continuamente enquanto a nave esta viva.
- [ ] Obstaculos em pares aparecem com gap atravessavel e ficam mais dificeis com o aumento da distancia.
- [ ] Colidir com asteroides ou tocar as bordas encerra a partida.
- [ ] Apos game over, o jogador consegue reiniciar a partida sem sair da tela.
- [ ] Build sem erros.
- [ ] Todos os testes unitarios passando.

## Riscos e Mitigacoes

| Risco | Probabilidade | Mitigacao |
|-------|--------------|-----------|
| A fisica ficar dificil demais para um MVP jogavel | Media | Comecar com `thrustPower`, `maxSpeed` e gap generosos; expor constantes no topo de `arcade_one.dart` ou em arquivo de configuracao simples para balancear rapidamente. |
| Testes Flame ficarem frageis por dependerem de renderizacao | Media | Testar fisica e colisao por estado/posicao, evitando asserts visuais ou temporizadores reais sempre que possivel. |
| Remocao da mecanica do unicornio quebrar exports/testes existentes | Alta | Atualizar barrels e testes na mesma fase de limpeza, mantendo `GamePage` e `ArcadeOne` como pontos publicos para reduzir impacto. |
| Input de segurar/arrastar variar entre mobile, web e teste | Media | Centralizar input no `ArcadeOne` e cobrir `setThrustTarget`/`clearThrust` diretamente nos testes de nave. |
| Ausencia de arte final deixar o MVP pouco legivel | Baixa | Usar formas pixeladas simples com cores contrastantes e starfield procedural, deixando sprites finais para uma fase posterior. |

## Rollback

Reverter os arquivos alterados em `lib/game/`, `test/game/`, `lib/l10n/arb/app_en.arb`, `lib/l10n/gen/`, `lib/title/view/title_page.dart`, `test/title/view/title_page_test.dart` e `flow/game.md`. Como a estrategia preserva `GamePage` e a classe publica `ArcadeOne`, o rollback pode restaurar a mecanica anterior do unicornio sem alterar a navegacao principal do app.
