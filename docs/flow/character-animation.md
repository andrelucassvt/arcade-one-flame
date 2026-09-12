---
generated_at: 2026-09-12
source_commit: 698131b
source_state: clean
verified_at: 2026-09-12
status: current
related_plans:
  - docs/plan/implement-drift-mvp.md
---

# Flow: Character Animation

> **Resumo:** Registra o spritesheet legado do unicórnio, hoje apenas precarregado, e mapeia a animação ativa da nave: pulso do sprite, giro e chama procedural enquanto há thrust.

## Visão Geral

O nome deste flow é legado. `assets/images/unicorn_animation.png` continua no pacote, é exposto pelo código gerado e entra no preload, mas nenhuma classe da aplicação cria uma animação a partir desse spritesheet.

A animação visível do personagem jogável acontece em `Ship`. Eventos de toque, drag ou joystick definem uma direção de thrust; a entidade acelera, limita a velocidade, gira gradualmente e avança um relógio interno de animação.

Durante a renderização, uma nave com sprite recebe um pulso de escala e uma chama desenhada em canvas. Sem sprite carregado, o corpo inteiro possui fallback procedural e usa a mesma chama. Ao soltar o controle, o thrust e a chama param, mas a inércia da nave continua.

## Passo a Passo

1. **Asset legado** — `assets/images/unicorn_animation.png`
   O arquivo permanece sob um diretório declarado no `pubspec.yaml`.
2. **Acesso gerado** — `lib/gen/assets.gen.dart` → `Assets.images.unicornAnimation`
   FlutterGen expõe o caminho tipado usado pelo preload; esse arquivo é saída gerada.
3. **Preload legado** — `lib/loading/cubit/preload/preload_cubit.dart` → `PreloadCubit.loadSequentially`
   Inclui `Assets.images.unicornAnimation.path` na fase de imagens, embora o gameplay atual não o consuma.
4. **Entrada de movimento** — `lib/game/arcade_one.dart` → callbacks de toque/drag e `setJoystickDirection`
   Converte o input permitido pelo `GameControlMode` em alvo ou direção de thrust para `Ship`.
5. **Atualização física e visual** — `lib/game/entities/ship/ship.dart` → `Ship.update`
   Acelera a nave, limita `velocity`, gira em direção ao movimento e incrementa `_thrustAnimationTime` enquanto o thrust está ativo.
6. **Renderização com sprite** — `lib/game/entities/ship/ship.dart` → `_renderSpriteShip`
   Aplica uma pequena escala senoidal ao sprite selecionado e desenha a chama antes da imagem.
7. **Renderização sem sprite** — `lib/game/entities/ship/ship.dart` → `render`
   Desenha casco, cockpit e asas em canvas; quando há thrust, acrescenta a mesma chama animada.
8. **Fim do thrust** — `lib/game/entities/ship/ship.dart` → `clearThrust`
   Zera a direção de aceleração; no próximo update o relógio visual volta a zero, mas a velocidade acumulada permanece.

### Caminhos alternativos

- **Imagem da nave indisponível:** `Ship.render` usa o desenho procedural completo.
- **Sem thrust e com velocidade:** a nave continua se movendo por inércia e gira em direção à velocidade, sem pulso ou chama.
- **Game over ou restart:** `ArcadeOne.endRun` limpa thrust e velocidade; `Ship.reset` também restaura posição, velocidade e ângulo.

## Arquivos Envolvidos

| Camada | Arquivo | Responsabilidade |
|--------|---------|------------------|
| Asset legado | `assets/images/unicorn_animation.png` | Spritesheet ainda empacotado e precarregado. |
| Preload | `lib/loading/cubit/preload/preload_cubit.dart` | Coloca o spritesheet legado no cache. |
| Orquestração | `lib/game/arcade_one.dart` | Encaminha inputs e estados de rodada para a nave. |
| Entidade | `lib/game/entities/ship/ship.dart` | Executa física, giro, relógio de animação e renderização. |
| Assets | `lib/game/player_ship/player_ship_skin.dart` | Identifica o sprite da nave selecionada. |
| Testes | `test/game/entities/ship/ship_test.dart` | Cobre thrust, inércia, limite de velocidade e reset. |
| Testes | `test/game/arcade_one_test.dart` | Cobre encaminhamento dos controles e interrupção em game over. |

## Regras de Negócio Relevantes

- **Animação condicionada ao thrust** — `lib/game/entities/ship/ship.dart`: pulso e chama só aparecem enquanto a direção de thrust é diferente de zero.
- **Inércia após soltar** — `lib/game/entities/ship/ship.dart`: limpar o thrust não zera a velocidade; a nave continua no vetor acumulado.
- **Limite de velocidade por controle** — `lib/game/arcade_one.dart`: touch usa máximo `250`, enquanto joystick usa máximo `170` e thrust reduzido.

## Dependências Externas

- Flame para `PositionComponent`, `Vector2` e ciclo de atualização/renderização.
- Flutter Canvas/`dart:ui` para transformações e desenho procedural.

## Observações

- Não há `SpriteAnimation`, grade de frames ou consumidor do spritesheet do unicórnio no código atual; o preload desse arquivo é legado.
- Os testes validam a mecânica que aciona a animação, mas não inspecionam o pulso, a chama ou pixels renderizados.
