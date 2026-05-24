# Adicionar Meteoros Soltos Como Obstaculos

> **Objetivo:** adicionar meteoros soltos ao gameplay, aumentando a variedade de obstaculos alem dos pares de asteroides com gap.

## Contexto

O jogo atualmente cria obstaculos apenas como `AsteroidPairComponent`, que formam blocos laterais com um corredor central. A progressao de dificuldade ja existe em `ArcadeOne.difficulty`, e o fluxo de jogo remove obstaculos fora da tela, checa colisao com a nave e recria a rodada no restart. A nova feature deve reaproveitar esse fluxo para inserir meteoros individuais em posicoes soltas, sem quebrar o comportamento de distancia, bordas, game over e restart.

## Arquitetura / Escopo

| Arquivo | Acao | Responsabilidade |
|---------|------|-----------------|
| `lib/game/components/loose_meteor_component.dart` | criar | Representar um meteoro individual com tamanho, posicao, movimento por scroll, renderizacao em canvas e colisao circular com `Ship`. |
| `lib/game/components/components.dart` | alterar | Exportar o novo componente para o barrel de componentes do jogo. |
| `lib/game/arcade_one.dart` | alterar | Gerenciar listas separadas ou uma colecao comum de obstaculos, criar meteoros soltos junto com pares de asteroides, remover meteoros fora da tela, checar colisao e limpar no restart. |
| `test/game/components/loose_meteor_component_test.dart` | criar | Cobrir movimento, offscreen e colisao do meteoro solto. |
| `test/game/arcade_one_test.dart` | alterar | Cobrir spawn, game over por meteoro solto e limpeza/recriacao no restart. |
| `flow/game.md` | alterar | Documentar o novo componente e a nova regra de obstaculos no fluxo do jogo. |

## Fases

### Fase 1 — Testes (contrato antes da implementacao)

> Escreva os testes que definem o comportamento esperado. Eles vao falhar inicialmente — isso e intencional.

- [ ] Criar `test/game/components/loose_meteor_component_test.dart` com testes para `moveByScroll`, `isOffscreen` e colisao circular contra `Ship`.
- [ ] Alterar `test/game/arcade_one_test.dart` para verificar que `ArcadeOne` cria meteoros soltos durante o load inicial ou durante `_spawnObstaclesIfNeeded`.
- [ ] Alterar `test/game/arcade_one_test.dart` para verificar que colisao entre `Ship` e um meteoro solto chama `endRun` e toca o efeito sonoro uma vez.
- [ ] Alterar `test/game/arcade_one_test.dart` para verificar que `restartRun` remove meteoros antigos e cria uma nova configuracao de obstaculos.
- [ ] Verificacao: `flutter test test/game/components/loose_meteor_component_test.dart test/game/arcade_one_test.dart` compila e falha apenas pela ausencia do novo componente/comportamento.

### Fase 2 — Componente do Meteoro Solto

- [ ] Criar `LooseMeteorComponent` em `lib/game/components/loose_meteor_component.dart` extendendo `PositionComponent`.
- [ ] Definir constantes locais para raio minimo, raio maximo e margem de spawn, mantendo o componente independente de assets externos.
- [ ] Implementar `moveByScroll(double scrollSpeed, double dt)` somando o scroll vertical na posicao do meteoro.
- [ ] Implementar `isOffscreen` considerando `gameSize.y + radius` para remover meteoros que sairam por baixo da tela.
- [ ] Implementar `collidesWith(Ship ship)` usando distancia entre centros e soma dos raios.
- [ ] Implementar `render(Canvas canvas)` com formas simples em canvas, coerente com o estilo atual dos asteroides.
- [ ] Exportar `loose_meteor_component.dart` em `lib/game/components/components.dart`.
- [ ] Verificacao: `flutter test test/game/components/loose_meteor_component_test.dart` passa.

### Fase 3 — Spawn E Progressao No ArcadeOne

- [ ] Adicionar uma colecao `looseMeteors` em `lib/game/arcade_one.dart`, evitando misturar tipos se isso tornar os testes menos claros.
- [ ] Criar metodo privado `_spawnLooseMeteor()` que escolhe `x`, `y`, `radius` e variacao horizontal usando `_random`, `playArea` e `difficulty`.
- [ ] Ajustar `_spawnInitialObstacles()` para criar meteoros soltos junto com os quatro pares iniciais, sem bloquear completamente o corredor inicial da nave.
- [ ] Ajustar `_spawnObstaclesIfNeeded()` para manter uma quantidade maxima controlada de meteoros, aumentando a chance/quantidade conforme `difficulty`.
- [ ] No `update`, mover meteoros com `scrollSpeed`, checar colisao antes da remocao offscreen e chamar `endRun()` em colisao.
- [ ] No `restartRun`, remover meteoros antigos da arvore Flame, limpar a lista e recriar a rodada inicial.
- [ ] Verificacao: `flutter test test/game/arcade_one_test.dart` passa.

### Fase 4 — Balanceamento Visual E Jogabilidade

- [ ] Ajustar espacamento e quantidade para que meteoros soltos aumentem a pressao sem tornar a partida impossivel nos primeiros segundos.
- [ ] Garantir que meteoros soltos nao nascam diretamente sobre a posicao inicial da nave em `_shipStartPosition()`.
- [ ] Ajustar raio/tamanho visual para que a area de colisao pareca justa em relacao ao desenho.
- [ ] Conferir que `difficulty` aumenta quantidade, tamanho ou frequencia de meteoros de forma gradual.
- [ ] Verificacao: rodar o app com `flutter run --flavor development --target lib/main_development.dart` e validar visualmente spawn, movimento, colisao, game over e restart.

### Fase 5 — Qualidade E Regressao

- [ ] Rodar `dart format lib/game test/game`.
- [ ] Rodar `flutter test --coverage --test-randomize-ordering-seed random`.
- [ ] Rodar `flutter analyze`.
- [ ] Corrigir qualquer falha de lint, formatacao ou teste relacionada aos novos meteoros.
- [ ] Verificacao: suite e analyzer passam sem erros.

### Fase 6 — Atualizar Flow

- [ ] Atualizar `flow/game.md` no resumo para mencionar meteoros soltos alem dos pares de asteroides.
- [ ] Atualizar o passo de obstaculos para descrever que `ArcadeOne.update` move e checa colisao de `AsteroidPairComponent` e `LooseMeteorComponent`.
- [ ] Adicionar `lib/game/components/loose_meteor_component.dart` na tabela de arquivos envolvidos.
- [ ] Adicionar regra de negocio sobre spawn gradual de meteoros soltos conforme dificuldade.
- [ ] Verificacao: `flow/game.md` reflete os arquivos e regras realmente implementados.

## Criterios de Sucesso

- [ ] Meteoros soltos aparecem durante a partida junto com os pares de asteroides.
- [ ] Meteoros soltos se movem com o scroll do jogo e somem ao sair da tela.
- [ ] Colisao da nave com meteoro solto encerra a rodada, atualiza melhor distancia e toca o efeito sonoro.
- [ ] Restart remove todos os meteoros antigos e inicia uma nova rodada limpa.
- [ ] A dificuldade aumenta a presenca dos meteoros sem criar bloqueios inevitaveis no inicio da partida.
- [ ] Build sem erros.
- [ ] Todos os testes unitarios passando.

## Riscos e Mitigacoes

| Risco | Probabilidade | Mitigacao |
|-------|--------------|-----------|
| Meteoros nascerem em posicoes impossiveis de desviar | Media | Aplicar margem de spawn, limitar quantidade inicial e evitar area proxima da posicao inicial da nave. |
| Colisao parecer injusta por causa do desenho irregular | Media | Usar raio de colisao menor ou igual ao raio visual principal e cobrir isso em teste. |
| A lista de obstaculos ficar inconsistente no restart | Baixa | Limpar explicitamente `looseMeteors`, remover componentes da arvore Flame e testar restart. |
| A dificuldade crescer rapido demais | Media | Amarrar frequencia/quantidade a `difficulty` com limites maximos e validar manualmente no run local. |

## Rollback

Remover `lib/game/components/loose_meteor_component.dart`, desfazer as alteracoes em `lib/game/components/components.dart`, `lib/game/arcade_one.dart`, `test/game/arcade_one_test.dart`, remover `test/game/components/loose_meteor_component_test.dart` e reverter a atualizacao de `flow/game.md`.
