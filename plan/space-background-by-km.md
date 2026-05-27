# Space Background by KM

> **Objetivo:** Fazer o fundo do jogo evoluir conforme `distanceKm`, exibindo planetas do sistema solar e marcos famosos do espaco em camadas de background, com assets PNG gerados e preloadados.

## Contexto

O jogo ja calcula `distanceKm` em `lib/game/arcade_one.dart` e usa esse valor para velocidade, dificuldade, HUD e progressao de obstaculos. Hoje o fundo e o `StarfieldComponent`, que desenha um campo de estrelas procedural com parallax simples. A mudanca deve manter esse campo como base, mas adicionar marcos visuais por faixa de KM para dar sensacao de viagem espacial e progressao.

Como a selecao depende de distancia e precisa ser testavel, o escopo e tratado como **Logic**: primeiro criar testes do contrato de marcos por KM, depois implementar o componente e integrar no jogo.

## Arquitetura / Escopo

| Arquivo | Acao | Responsabilidade |
|---------|------|-----------------|
| `lib/game/background/space_landmark.dart` | criar | Definir o modelo imutavel de cada marco espacial: id, asset, inicio em KM, fim opcional, escala, opacidade e posicao relativa. |
| `lib/game/background/space_landmark_catalog.dart` | criar | Centralizar a tabela de progressao por KM e manter a ordem dos marcos. |
| `lib/game/components/space_background_component.dart` | criar | Renderizar starfield + imagem ativa do marco espacial com fade/parallax leve, sem interferir em nave, HUD e obstaculos. |
| `lib/game/components/starfield_component.dart` | modificar | Permitir reutilizacao pelo novo componente ou manter apenas a camada de estrelas como subcomponente. |
| `lib/game/arcade_one.dart` | modificar | Trocar/adicionar o componente de background e atualizar o marco ativo com base em `distanceKm`. |
| `lib/game/game_image_assets.dart` | modificar | Registrar os novos assets de background em `gameImageAssets` para preload pelo `PreloadCubit`. |
| `lib/game/components/components.dart` | modificar | Exportar `space_background_component.dart`. |
| `assets/images/backgrounds/*.png` | criar | Armazenar os PNGs gerados para os marcos espaciais, com composicao propria para fundo de jogo. |
| `test/game/background/space_landmark_catalog_test.dart` | criar | Testar a tabela de KM e a selecao do marco ativo. |
| `test/game/components/space_background_component_test.dart` | criar | Testar troca de marco, continuidade de scroll e ausencia de salto visual no fade. |
| `test/game/arcade_one_test.dart` | modificar | Cobrir integracao: o jogo carrega o novo background e atualiza a distancia sem quebrar obstaculos/HUD. |
| `flow/game.md` | modificar | Atualizar documentacao do fluxo porque novos arquivos e responsabilidade de background entram no Game. |

### Tabela Inicial de Marcos por KM

Esses KM sao escala de gameplay, nao escala astronomica real. A ideia e dar ritmo visual dentro de uma partida curta/media.

| Inicio KM | Marco | Asset sugerido | Direcao visual |
|-----------|-------|----------------|----------------|
| `0` | Terra e Lua | `assets/images/backgrounds/space_earth_moon.png` | Terra pequena no canto inferior distante, Lua menor, fundo escuro limpo. |
| `250` | Marte | `assets/images/backgrounds/space_mars.png` | Planeta vermelho lateral, poeira sutil e algumas estrelas quentes. |
| `600` | Cintura de asteroides | `assets/images/backgrounds/space_asteroid_belt.png` | Faixa distante de rochas pequenas, sem confundir com obstaculos jogaveis. |
| `1000` | Jupiter | `assets/images/backgrounds/space_jupiter.png` | Jupiter grande ao fundo, Grande Mancha Vermelha visivel, baixa opacidade. |
| `1500` | Saturno | `assets/images/backgrounds/space_saturn.png` | Aneis diagonais ocupando parte do fundo, contraste moderado. |
| `2100` | Urano e Netuno | `assets/images/backgrounds/space_ice_giants.png` | Dois planetas azulados distantes, atmosfera fria e estrelas mais densas. |
| `2800` | Plutao / Cintura de Kuiper | `assets/images/backgrounds/space_kuiper_belt.png` | Objetos pequenos e gelo distante, clima de fronteira do sistema solar. |
| `3600` | Nebulosa de Orion | `assets/images/backgrounds/space_orion_nebula.png` | Nebulosa colorida ampla, opacidade baixa para nao atrapalhar gameplay. |
| `4500` | Pilares da Criacao | `assets/images/backgrounds/space_pillars_creation.png` | Colunas nebulosas verticais ao fundo, enquadradas fora da rota central. |
| `5600` | Buraco negro | `assets/images/backgrounds/space_black_hole.png` | Disco de acrecao distante, sem centro claro atras da nave. |
| `7000` | Galaxia de Andromeda | `assets/images/backgrounds/space_andromeda.png` | Galaxia espiral larga, usada como marco de deep space. |
| `8500` | Quasar / espaco profundo | `assets/images/backgrounds/space_deep_quasar.png` | Feixe distante e campo estelar denso para runs longas. |

## Fases

### Fase 1 — Testes (contrato antes da implementacao)

> Escreva os testes que definem o comportamento esperado. Eles vao falhar inicialmente - isso e intencional.

- [ ] Criar `test/game/background/space_landmark_catalog_test.dart`.
- [ ] Testar que `spaceLandmarks` esta ordenado por `startKm` crescente e nao possui ids ou assets duplicados.
- [ ] Testar caso de sucesso: `landmarkForDistance(0)`, `landmarkForDistance(250)`, `landmarkForDistance(1000)` e `landmarkForDistance(8500)` retornam os marcos esperados.
- [ ] Testar bordas de faixa: `249.99` ainda usa Terra/Lua, `250` usa Marte, `999.99` ainda usa Cintura de asteroides e `1000` usa Jupiter.
- [ ] Criar `test/game/components/space_background_component_test.dart`.
- [ ] Testar que `SpaceBackgroundComponent.advance(scrollSpeed, dt, distanceKm)` mantem o starfield continuo e troca o marco ativo quando cruza a proxima faixa.
- [ ] Modificar `test/game/arcade_one_test.dart` para validar que `ArcadeOne` cria o componente de background e o atualiza quando `distanceKm` cresce.
- [ ] Verificacao: todos os testes compilam e falham por classes/metodos ainda inexistentes, nao por erro de sintaxe.

### Fase 2 — Catalogo e Assets

- [ ] Criar `lib/game/background/space_landmark.dart` com classe `SpaceLandmark` imutavel, campos `id`, `assetPath`, `startKm`, `scale`, `anchor`, `opacity`, `parallaxFactor` e `copyWith`.
- [ ] Criar `lib/game/background/space_landmark_catalog.dart` com `const List<SpaceLandmark> spaceLandmarks` e funcao `SpaceLandmark landmarkForDistance(double distanceKm)`.
- [ ] Criar os PNGs em `assets/images/backgrounds/` seguindo a tabela inicial, em proporcao vertical compativel com mobile (`1080x1920` ou maior) e com areas centrais sem excesso de brilho.
- [ ] Atualizar `lib/game/game_image_assets.dart` para incluir todos os assets de background em `gameImageAssets`.
- [ ] Verificar se `pubspec.yaml` ja cobre `assets/images/backgrounds/` via `assets/images/`; se o build nao reconhecer subpasta, adicionar explicitamente `assets/images/backgrounds/`.
- [ ] Verificacao: `PreloadCubit` continua carregando `gameImageAssets` sem mudanca de contrato.

### Fase 3 — Componente de Background

- [ ] Criar `lib/game/components/space_background_component.dart` como `PositionComponent` responsavel por renderizar o retangulo base, estrelas e a imagem do `SpaceLandmark` ativo.
- [ ] Reaproveitar a logica de estrelas de `StarfieldComponent` ou mover a responsabilidade de estrelas para dentro de `SpaceBackgroundComponent`, mantendo o comportamento testado de loop/parallax.
- [ ] Implementar fade curto entre marcos para evitar troca seca quando `distanceKm` cruza o inicio de uma nova faixa.
- [ ] Garantir que as imagens fiquem atras da nave, obstaculos e HUD, usando ordem de `add`/priority adequada no Flame.
- [ ] Exportar o novo componente em `lib/game/components/components.dart`.
- [ ] Verificacao: testes de `space_background_component_test.dart` passam e `starfield_component_test.dart` continua cobrindo continuidade, ou e adaptado para o novo componente equivalente.

### Fase 4 — Integracao no Jogo

- [ ] Modificar `lib/game/arcade_one.dart` para trocar `StarfieldComponent? starfield` por `SpaceBackgroundComponent? background`, ou manter `starfield` apenas se ele virar subcomponente interno.
- [ ] Atualizar `_buildRun()` para carregar os assets de background do cache de imagens e adicionar o novo componente antes de `Ship`, `DriftHudComponent` e obstaculos.
- [ ] Atualizar `update(double dt)` para chamar `background?.advance(scrollSpeed, dt, distanceKm)` logo apos calcular `scrollSpeed`.
- [ ] Atualizar `restartRun()` para resetar o background para o marco de `0 KM` junto com `distanceKm = 0`.
- [ ] Manter fallback procedural se alguma imagem nao carregar, para os testes e para falhas de cache nao quebrarem a partida.
- [ ] Verificacao: `test/game/arcade_one_test.dart` passa e confirma que distancia, scroll, obstaculos, colisoes e restart continuam funcionando.

### Fase 5 — Validacao Visual e Performance

- [ ] Rodar `dart format` nos arquivos Dart alterados.
- [ ] Rodar `flutter test test/game/background test/game/components test/game/arcade_one_test.dart`.
- [ ] Rodar `flutter analyze`.
- [ ] Executar o jogo localmente e validar visualmente as faixas principais usando ajuste temporario de `distanceKm` em ambiente de debug ou teste manual controlado.
- [ ] Confirmar que os marcos nao escondem nave, asteroides, meteoros, textos do HUD ou botao de volume.
- [ ] Verificacao: os backgrounds aparecem atras do gameplay, com transicao perceptivel e sem queda visivel de frame.

### Fase 6 — Atualizar Flow

- [ ] Atualizar `flow/game.md` no resumo para citar background progressivo por KM.
- [ ] Atualizar o passo de `ArcadeOne.onLoad` para mencionar `SpaceBackgroundComponent` e assets de marcos espaciais.
- [ ] Atualizar o passo de `ArcadeOne.update` para incluir `background.advance(scrollSpeed, dt, distanceKm)`.
- [ ] Atualizar a tabela de arquivos envolvidos com `lib/game/background/space_landmark.dart`, `lib/game/background/space_landmark_catalog.dart`, `lib/game/components/space_background_component.dart` e `assets/images/backgrounds/*.png`.
- [ ] Atualizar regras de negocio com a tabela resumida de faixas de KM.
- [ ] Verificacao: o flow continua refletindo a ordem real UI -> Flame Game -> componentes -> assets.

## Critérios de Sucesso

- [ ] O fundo muda automaticamente conforme `distanceKm`, seguindo a tabela inicial de marcos por KM.
- [ ] Todos os assets de planeta/nebulosa/buraco negro sao carregados pelo preload antes da partida.
- [ ] O starfield continua se movendo em parallax sem salto visual no loop.
- [ ] As imagens de background nao atrapalham leitura do HUD nem colisao visual com obstaculos jogaveis.
- [ ] `restartRun()` volta o background para Terra/Lua.
- [ ] Build sem erros.
- [ ] Todos os testes unitarios passando.

## Riscos e Mitigações

| Risco | Probabilidade | Mitigacao |
|-------|--------------|-----------|
| Assets muito pesados aumentarem tempo de preload e memoria | Media | Gerar PNGs otimizados, limitar dimensao, comprimir imagens e validar tamanho total antes do build. |
| Backgrounds brilhantes reduzirem legibilidade da nave/obstaculos/HUD | Media | Definir opacidade por marco no catalogo e manter area central menos contrastada nos prompts de imagem. |
| Marcos confundirem gameplay por parecerem obstaculos | Media | Renderizar objetos famosos como elementos distantes, grandes ou desfocados, nunca no mesmo estilo/tamanho de meteoros colidiveis. |
| Troca de marco causar salto visual | Baixa | Implementar fade curto e manter starfield independente da imagem ativa. |
| Subpasta `assets/images/backgrounds/` nao ser incluida no bundle | Baixa | Validar com `flutter test`/build; se necessario, registrar a subpasta explicitamente no `pubspec.yaml`. |

## Rollback

Remover os arquivos novos de `lib/game/background/`, remover `lib/game/components/space_background_component.dart`, voltar `ArcadeOne` a usar `StarfieldComponent`, remover os assets `assets/images/backgrounds/*.png`, retirar esses caminhos de `gameImageAssets` e reverter os testes adicionados para a feature.
