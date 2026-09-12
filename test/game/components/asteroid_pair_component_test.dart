// Make test files more explicit rather than collapsing calls
// ignore_for_file: cascade_invocations

import 'dart:math' as math;

import 'package:arcade_one/game/game.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AsteroidPairComponent', () {
    test('reduces gap as difficulty increases', () {
      final easy = AsteroidPairComponent(
        gameSize: Vector2(390, 700),
        y: 0,
        difficulty: 0,
      );
      final hard = AsteroidPairComponent(
        gameSize: Vector2(390, 700),
        y: 0,
        difficulty: 1,
      );

      expect(easy.gapSize, greaterThan(hard.gapSize));
      expect(hard.gapSize, greaterThanOrEqualTo(asteroidMinGap));
    });

    test('moves by scroll speed', () {
      final obstacle = AsteroidPairComponent(
        gameSize: Vector2(390, 700),
        y: -20,
        difficulty: 0,
      );

      obstacle.moveByScroll(100, 0.5);

      expect(obstacle.position.y, equals(30));
    });

    test('detects collision with asteroid block', () {
      final obstacle = AsteroidPairComponent(
        gameSize: Vector2(390, 700),
        y: 100,
        difficulty: 0,
        gapCenterX: 195,
      );
      final ship = Ship(position: Vector2(20, 130));

      expect(obstacle.collidesWith(ship), isTrue);
    });

    test('does not collide inside the gap', () {
      final obstacle = AsteroidPairComponent(
        gameSize: Vector2(390, 700),
        y: 100,
        difficulty: 0,
        gapCenterX: 195,
      );
      final ship = Ship(position: Vector2(195, 130));

      expect(obstacle.collidesWith(ship), isFalse);
    });

    test('oscillates the gap when drift is configured', () {
      final obstacle = AsteroidPairComponent(
        gameSize: Vector2(390, 700),
        y: 0,
        difficulty: 0,
        gapCenterX: 195,
        gapDriftAmplitude: 40,
        gapDriftSpeed: 1,
      );

      final initialGapCenter = obstacle.gapCenterX;
      obstacle.update(math.pi / 2);

      expect(obstacle.isMovingGap, isTrue);
      expect(obstacle.gapCenterX, greaterThan(initialGapCenter));
    });

    test('keeps the moving gap inside the play area', () {
      final obstacle = AsteroidPairComponent(
        gameSize: Vector2(390, 700),
        y: 0,
        difficulty: 0,
        gapCenterX: 20,
        gapDriftAmplitude: 500,
        gapDriftSpeed: 1,
      );

      obstacle.update(math.pi / 2);
      final edge = obstacle.gapSize / 2 + asteroidGapEdgeMargin;

      expect(obstacle.gapCenterX, greaterThanOrEqualTo(edge));
      expect(obstacle.gapCenterX, lessThanOrEqualTo(390 - edge));
    });

    test('registers a near miss only once', () {
      final obstacle = AsteroidPairComponent(
        gameSize: Vector2(390, 700),
        y: 100,
        difficulty: 0,
        gapCenterX: 195,
      );
      final ship = Ship(position: Vector2(139, 130));

      expect(obstacle.tryRegisterNearMiss(ship, 18), isTrue);
      expect(obstacle.tryRegisterNearMiss(ship, 18), isFalse);
    });

    test('does not register a near miss when the ship is far away', () {
      final obstacle = AsteroidPairComponent(
        gameSize: Vector2(390, 700),
        y: 100,
        difficulty: 0,
        gapCenterX: 195,
      );
      final ship = Ship(position: Vector2(195, 500));

      expect(obstacle.tryRegisterNearMiss(ship, 18), isFalse);
    });
  });
}
