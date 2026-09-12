import 'package:arcade_one/game/game.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PowerUpComponent', () {
    test('collects when the ship overlaps it', () {
      final powerUp = PowerUpComponent(
        gameSize: Vector2(390, 700),
        position: Vector2(120, 140),
        type: PowerUpType.shield,
      );
      final ship = Ship(position: Vector2(126, 146));

      expect(powerUp.collidesWith(ship), isTrue);
    });

    test('does not collect when the ship is far away', () {
      final powerUp = PowerUpComponent(
        gameSize: Vector2(390, 700),
        position: Vector2(120, 140),
        type: PowerUpType.shield,
      );
      final ship = Ship(position: Vector2(300, 400));

      expect(powerUp.collidesWith(ship), isFalse);
    });

    test('moves by scroll speed and horizontal drift', () {
      final powerUp = PowerUpComponent(
        gameSize: Vector2(390, 700),
        position: Vector2(120, -20),
        type: PowerUpType.slowMotion,
        horizontalDrift: 12,
      )..moveByScroll(100, 0.5);

      expect(powerUp.position, equals(Vector2(126, 30)));
    });

    test('is offscreen after leaving the bottom edge', () {
      final powerUp = PowerUpComponent(
        gameSize: Vector2(390, 700),
        position: Vector2(120, 720),
        type: PowerUpType.shield,
      );

      expect(powerUp.isOffscreen, isTrue);
    });

    test('uses a distinct color per type', () {
      expect(PowerUpType.shield.color, equals(shieldPowerUpColor));
      expect(PowerUpType.slowMotion.color, equals(slowMotionPowerUpColor));
    });
  });
}
