import 'package:arcade_one/game/game.dart';
import 'package:flame/components.dart';

const int driftHudPriority = 1000;

class DriftHudComponent extends PositionComponent
    with HasGameReference<ArcadeOne> {
  DriftHudComponent({required super.position})
    : super(anchor: Anchor.topLeft, priority: driftHudPriority);

  late final TextComponent distanceText;
  late final TextComponent bestText;
  late final TextComponent gameOverText;
  late final TextComponent restartText;

  @override
  Future<void> onLoad() async {
    final baseRenderer = TextPaint(
      style: game.textStyle.copyWith(fontSize: 18),
    );
    final secondaryRenderer = TextPaint(
      style: game.textStyle.copyWith(fontSize: 12),
    );
    final titleRenderer = TextPaint(
      style: game.textStyle.copyWith(fontSize: 28),
    );

    await addAll([
      distanceText = TextComponent(textRenderer: baseRenderer),
      bestText = TextComponent(
        position: Vector2(0, 24),
        textRenderer: secondaryRenderer,
      ),
      gameOverText = TextComponent(
        anchor: Anchor.center,
        position: Vector2(game.size.x / 2, game.size.y / 2 - 20),
        textRenderer: titleRenderer,
      ),
      restartText = TextComponent(
        anchor: Anchor.center,
        position: Vector2(game.size.x / 2, game.size.y / 2 + 18),
        textRenderer: secondaryRenderer,
      ),
    ]);
  }

  @override
  void update(double dt) {
    super.update(dt);

    distanceText.text = game.l10n.distanceText(game.distanceKm.floor());
    bestText.text = game.l10n.bestDistanceText(game.bestDistanceKm.floor());

    if (game.isGameOver) {
      gameOverText.text = game.l10n.gameOverTitle;
      restartText.text = game.l10n.restartHint;
    } else {
      gameOverText.text = '';
      restartText.text = '';
    }
  }

  void reposition(Vector2 gameSize) {
    gameOverText.position = Vector2(gameSize.x / 2, gameSize.y / 2 - 20);
    restartText.position = Vector2(gameSize.x / 2, gameSize.y / 2 + 18);
  }
}
