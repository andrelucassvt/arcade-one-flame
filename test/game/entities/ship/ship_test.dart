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

    test('keeps moving with inertia when thrust is cleared', () {
      final ship = Ship(position: Vector2.zero());

      ship.setThrustTarget(Vector2(100, 0));
      ship.update(0.1);
      final velocityAfterThrust = ship.velocity.x;

      ship.clearThrust();
      ship.update(0.1);

      expect(ship.isThrusting, isFalse);
      expect(ship.velocity.x, equals(velocityAfterThrust));
      expect(ship.position.x, greaterThan(velocityAfterThrust * 0.1));
    });

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
    });
  });
}
