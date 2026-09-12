import 'package:arcade_one/game/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

const int driftHudPriority = 1000;

class DriftHudComponent extends PositionComponent
    with HasGameReference<ArcadeOne> {
  DriftHudComponent({required super.position})
    : super(anchor: Anchor.topLeft, priority: driftHudPriority);

  late final TextComponent distanceText;
  late final TextComponent bestText;
  late final TextComponent comboText;

  int _lastDistance = -1;
  int _lastBest = -1;
  int _lastCombo = -1;

  @override
  Future<void> onLoad() async {
    final baseRenderer = TextPaint(
      style: game.textStyle.copyWith(fontSize: 18),
    );
    final secondaryRenderer = TextPaint(
      style: game.textStyle.copyWith(fontSize: 12),
    );

    await addAll([
      distanceText = TextComponent(textRenderer: baseRenderer),
      bestText = TextComponent(
        position: Vector2(0, 24),
        textRenderer: secondaryRenderer,
      ),
      comboText = TextComponent(
        position: Vector2(0, 42),
        textRenderer: secondaryRenderer,
      ),
    ]);
  }

  @override
  void update(double dt) {
    super.update(dt);

    final distance = game.distanceKm.floor();
    if (distance != _lastDistance) {
      _lastDistance = distance;
      distanceText.text = game.l10n.distanceText(distance);
    }

    final best = game.bestDistanceKm.floor();
    if (best != _lastBest) {
      _lastBest = best;
      bestText.text = game.l10n.bestDistanceText(best);
    }

    final combo = game.combo;
    if (combo != _lastCombo) {
      _lastCombo = combo;
      comboText.text = combo > 1 ? game.l10n.comboText(combo) : '';
    }
  }

  void reposition(
    Vector2 gameSize, {
    EdgeInsets safeAreaPadding = EdgeInsets.zero,
  }) {
    position = Vector2(
      12 + safeAreaPadding.left,
      12 + safeAreaPadding.top,
    );
  }
}
