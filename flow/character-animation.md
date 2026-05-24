# Flow: Character Animation

> **Resumo:** Documentacao legada do spritesheet antigo; o MVP atual de DRIFT nao usa personagem animado por spritesheet, mas a nave possui sprite PNG e animacao procedural de thrust.

## Visão Geral

O projeto ainda possui `assets/images/unicorn_animation.png` declarado em assets, mas a feature `game` atual nao instancia mais `Unicorn`, `TappingBehavior` ou `CounterComponent`. O jogo principal agora renderiza a nave com `assets/images/player_ship.png` quando o sprite esta disponivel e mantem fallback em canvas por `lib/game/entities/ship/ship.dart`.

Este flow fica registrado principalmente como historico do asset legado. A animacao atual da nave nao usa spritesheet: `Ship.update` avanca um tempo interno enquanto o thrust esta ativo, e `Ship.render` aplica pulso visual no sprite e desenha uma chama animada.

## Passo a Passo

1. **Asset legado** — `assets/images/unicorn_animation.png`
   Arquivo ainda presente no projeto e carregavel pelo pipeline de assets Flutter.
2. **Geracao de assets** — `lib/gen/assets.gen.dart`
   FlutterGen ainda expoe o caminho tipado enquanto o asset continuar declarado no `pubspec.yaml`.
3. **Asset atual da nave** — `assets/images/player_ship.png`
   Sprite PNG transparente carregado pelo cache de imagens do Flame usando a chave definida em `lib/game/game_image_assets.dart`.
4. **Jogo atual** — `lib/game/entities/ship/ship.dart`
   A nave do MVP renderiza o sprite quando disponivel, desenha fallback em canvas quando nao houver imagem e anima visualmente o thrust ao clicar/tocar.

## Arquivos Envolvidos

| Camada | Arquivo | Responsabilidade |
|--------|---------|------------------|
| Asset legado | `assets/images/unicorn_animation.png` | Spritesheet antigo mantido no reposititorio. |
| Asset atual | `assets/images/player_ship.png` | Sprite PNG transparente da nave DRIFT. |
| Constantes | `lib/game/game_image_assets.dart` | Define a chave do sprite da nave no cache do Flame. |
| Assets gerados | `lib/gen/assets.gen.dart` | Expoe caminhos tipados para assets declarados. |
| Entidade atual | `lib/game/entities/ship/ship.dart` | Renderiza a nave DRIFT por sprite/fallback canvas, controla fisica e anima o thrust. |

## Regras de Negócio Relevantes

- **Sem uso em runtime no MVP** — o fluxo atual de jogo nao referencia o spritesheet legado.
- **Animacao sem spritesheet** — o clique/toque ativa `isThrusting`, que aciona pulso do sprite e chama animada, sem alterar fisica ou colisao.
- **Arte final futura exige novo flow** — se a nave passar a usar spritesheet, documentar tamanho de frames, ordem de animacao e carregamento no Flame.

## Dependências Externas

- `flame` para componentes e renderizacao do jogo atual.

## Observações

- A dependencia `flame_behaviors` foi removida porque era usada apenas pela mecanica antiga de toque no unicornio.
- Remover o arquivo PNG legado e uma decisao separada de limpeza de assets; o MVP nao depende disso.
