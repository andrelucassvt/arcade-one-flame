import 'package:arcade_one/game/game.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ParticleBurstComponent', () {
    test('finishes after its lifetime', () async {
      final burst = ParticleBurstComponent(position: Vector2.zero());
      await burst.onLoad();

      expect(burst.isFinished, isFalse);

      burst.update(particleBurstLifetime + 0.01);

      expect(burst.isFinished, isTrue);
    });

    test('advances its progress over time', () async {
      final burst = ParticleBurstComponent(position: Vector2.zero());
      await burst.onLoad();

      expect(burst.progress, equals(0));

      burst.update(particleBurstLifetime / 2);

      expect(burst.progress, closeTo(0.5, 1e-9));
    });
  });
}
