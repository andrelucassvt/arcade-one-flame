// Make test files more explicit rather than collapsing calls
// ignore_for_file: cascade_invocations

import 'package:arcade_one/game/game.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SpaceBackgroundComponent', () {
    test('keeps starfield continuous while revealing next landmark', () async {
      final background = SpaceBackgroundComponent(gameSize: Vector2(390, 700));
      await background.onLoad();

      const scrollSpeed = 100.0;
      background.advance(scrollSpeed, 699.99, 249.99);
      final beforeLoop = background.debugStarYs();

      background.advance(scrollSpeed, 0.02, 250);
      final afterLoop = background.debugStarYs();

      expect(background.activeLandmark.id, equals('mars'));
      expect(
        background.visibleLandmarks.map((landmark) => landmark.id),
        containsAll(['earth_moon', 'mars']),
      );

      for (var i = 0; i < beforeLoop.length; i++) {
        final delta = (afterLoop[i] - beforeLoop[i]).abs();
        final wrappedDelta = 700 - delta;
        expect(
          delta < 2 || wrappedDelta < 2,
          isTrue,
          reason: 'star $i jumped by $delta px at the background loop point',
        );
      }
    });

    test('removes a landmark after it scrolls out of view', () async {
      final background = SpaceBackgroundComponent(gameSize: Vector2(390, 700));
      await background.onLoad();

      background.advance(100, 0.1, 430);

      expect(background.activeLandmark.id, equals('mars'));
      expect(
        background.visibleLandmarks.map((landmark) => landmark.id),
        isNot(contains('earth_moon')),
      );
    });

    test('moves landmarks at a constant visual rate', () async {
      final background = SpaceBackgroundComponent(gameSize: Vector2(390, 700));
      await background.onLoad();

      final mars = spaceLandmarks.firstWhere(
        (landmark) => landmark.id == 'mars',
      );
      final midpointDistance = mars.startKm + mars.visibleKm / 2;

      background.advance(0, 0, midpointDistance);

      expect(
        background.debugLandmarkCenter(mars),
        equals(
          Offset(
            390 * (mars.startAnchor.dx + mars.endAnchor.dx) / 2,
            700 * (mars.startAnchor.dy + mars.endAnchor.dy) / 2,
          ),
        ),
      );
    });

    test('reset returns to the first landmark', () async {
      final background = SpaceBackgroundComponent(gameSize: Vector2(390, 700));
      await background.onLoad();

      background.advance(100, 0.1, 1000);

      background.reset();

      expect(background.activeLandmark.id, equals('earth_moon'));
      expect(
        background.visibleLandmarks.map((landmark) => landmark.id),
        contains('earth_moon'),
      );
    });
  });
}
