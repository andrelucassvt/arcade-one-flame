# Flow: Character Animation

> **Resumo:** Documentacao legada do spritesheet antigo; o MVP atual de DRIFT nao usa personagem animado por spritesheet.

## Visão Geral

O projeto ainda possui `assets/images/unicorn_animation.png` declarado em assets, mas a feature `game` atual nao instancia mais `Unicorn`, `TappingBehavior` ou `CounterComponent`. O jogo principal agora renderiza a nave diretamente em canvas por `lib/game/entities/ship/ship.dart`.

Este flow fica registrado apenas como historico do asset legado. Caso a arte final de DRIFT passe a usar spritesheets, este fluxo deve ser refeito para documentar a nova entidade, o novo arquivo de imagem e o ponto de carregamento real no jogo.

## Passo a Passo

1. **Asset legado** — `assets/images/unicorn_animation.png`
   Arquivo ainda presente no projeto e carregavel pelo pipeline de assets Flutter.
2. **Geracao de assets** — `lib/gen/assets.gen.dart`
   FlutterGen ainda expoe o caminho tipado enquanto o asset continuar declarado no `pubspec.yaml`.
3. **Jogo atual** — `lib/game/entities/ship/ship.dart`
   A nave do MVP e desenhada por canvas, sem dependencia do spritesheet legado.

## Arquivos Envolvidos

| Camada | Arquivo | Responsabilidade |
|--------|---------|------------------|
| Asset legado | `assets/images/unicorn_animation.png` | Spritesheet antigo mantido no reposititorio. |
| Assets gerados | `lib/gen/assets.gen.dart` | Expoe caminhos tipados para assets declarados. |
| Entidade atual | `lib/game/entities/ship/ship.dart` | Renderiza a nave DRIFT por canvas e controla fisica. |

## Regras de Negócio Relevantes

- **Sem uso em runtime no MVP** — o fluxo atual de jogo nao referencia o spritesheet legado.
- **Arte final futura exige novo flow** — se a nave passar a usar spritesheet, documentar tamanho de frames, ordem de animacao e carregamento no Flame.

## Dependências Externas

- `flame` para componentes e renderizacao do jogo atual.

## Observações

- A dependencia `flame_behaviors` foi removida porque era usada apenas pela mecanica antiga de toque no unicornio.
- Remover o arquivo PNG legado e uma decisao separada de limpeza de assets; o MVP nao depende disso.
