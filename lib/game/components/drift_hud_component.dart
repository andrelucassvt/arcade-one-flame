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
    ]);
  }

  @override
  void update(double dt) {
    super.update(dt);

    distanceText.text = game.l10n.distanceText(game.distanceKm.floor());
    bestText.text = game.l10n.bestDistanceText(game.bestDistanceKm.floor());
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
