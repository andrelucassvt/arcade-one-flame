// Make test files more explicit rather than collapsing calls
// ignore_for_file: cascade_invocations

import 'package:arcade_one/game/game.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Ship', () {
    test('accelerates toward the thrust target', () {
      final ship = Ship(position: Vector2.zero());

      ship.setThrustTarget(Vector2(100, 0));
      ship.update(0.1);

      expect(ship.isThrusting, isTrue);
      expect(ship.velocity.x, greaterThan(0));
      expect(ship.position.x, greaterThan(0));
    });

    test('keeps steering toward the current target every frame', () {
      final ship = Ship(position: Vector2.zero());

      ship.setThrustTarget(Vector2(100, 0));
      ship.update(0.1);
      expect(ship.velocity.y, equals(0));

      ship.setThrustTarget(ship.position + Vector2(0, 100));
      ship.update(0.1);

      expect(ship.velocity.y, greaterThan(0));
    });

    test('stops thrusting when the target is inside the dead zone', () {
      final ship = Ship(position: Vector2.zero());

      ship.setThrustTarget(Vector2(shipThrustDeadZone - 1, 0));
      ship.update(0.1);

      expect(ship.isThrusting, isFalse);
      expect(ship.velocity, equals(Vector2.zero()));
    });

    test(
      'keeps moving with inertia but decelerates when thrust is cleared',
      () {
        final ship = Ship(position: Vector2.zero());

        ship.setThrustTarget(Vector2(100, 0));
        ship.update(0.1);
        final velocityAfterThrust = ship.velocity.x;
        final positionAfterThrust = ship.position.x;

        ship.clearThrust();
        ship.update(0.1);

        expect(ship.isThrusting, isFalse);
        expect(ship.velocity.x, lessThan(velocityAfterThrust));
        expect(ship.velocity.x, greaterThan(0));
        expect(ship.position.x, greaterThan(positionAfterThrust));
      },
    );

    test('does not exceed max speed', () {
      final ship = Ship(position: Vector2.zero(), maxSpeed: 40);

      ship.setThrustTarget(Vector2(100, 0));
      for (var i = 0; i < 20; i++) {
        ship.update(0.1);
      }

      expect(ship.velocity.length, lessThanOrEqualTo(40.0001));
    });

    test('reset clears movement state', () {
      final ship = Ship(position: Vector2.zero());

      ship.setThrustTarget(Vector2(100, 0));
      ship.update(0.1);
      ship.reset(Vector2(10, 20));

      expect(ship.position, equals(Vector2(10, 20)));
      expect(ship.velocity, equals(Vector2.zero()));
      expect(ship.isThrusting, isFalse);
      expect(ship.hasShield, isFalse);
      expect(ship.invulnerable, isFalse);
    });

    test('consumes a granted shield only once', () {
      final ship = Ship(position: Vector2.zero());

      expect(ship.hasShield, isFalse);
      expect(ship.consumeShield(), isFalse);

      ship.grantShield();

      expect(ship.hasShield, isTrue);
      expect(ship.consumeShield(), isTrue);
      expect(ship.hasShield, isFalse);
      expect(ship.consumeShield(), isFalse);
    });

    test('tracks the invulnerability flag', () {
      final ship = Ship(position: Vector2.zero());

      expect(ship.invulnerable, isFalse);

      ship.invulnerable = true;

      expect(ship.invulnerable, isTrue);
    });
  });
}
