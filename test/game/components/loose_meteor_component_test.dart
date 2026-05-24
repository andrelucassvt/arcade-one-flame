import 'package:arcade_one/game/game.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LooseMeteorComponent', () {
    test('moves by scroll speed and horizontal drift', () {
      final meteor = LooseMeteorComponent(
        gameSize: Vector2(390, 700),
        position: Vector2(120, -20),
        radius: 14,
        horizontalDrift: 12,
      );

      expect(
        (meteor..moveByScroll(100, 0.5)).position,
        equals(Vector2(126, 30)),
      );
    });

    test('is offscreen after leaving the bottom edge', () {
      final meteor = LooseMeteorComponent(
        gameSize: Vector2(390, 700),
        position: Vector2(120, 715),
        radius: 14,
      );

      expect(meteor.isOffscreen, isTrue);
    });

    test('detects collision with ship', () {
      final meteor = LooseMeteorComponent(
        gameSize: Vector2(390, 700),
        position: Vector2(120, 140),
        radius: 14,
      );
      final ship = Ship(position: Vector2(126, 146));

      expect(meteor.collidesWith(ship), isTrue);
    });

    test('does not collide when ship is outside radius', () {
      final meteor = LooseMeteorComponent(
        gameSize: Vector2(390, 700),
        position: Vector2(120, 140),
        radius: 14,
      );
      final ship = Ship(position: Vector2(180, 200));

      expect(meteor.collidesWith(ship), isFalse);
    });
  });
}
