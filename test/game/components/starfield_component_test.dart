import 'package:arcade_one/game/game.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StarfieldComponent', () {
    test('keeps parallax layers continuous across its loop point', () async {
      final starfield = StarfieldComponent(gameSize: Vector2(390, 700));
      await starfield.onLoad();

      const scrollSpeed = 100.0;
      starfield.advance(scrollSpeed, 699.99);
      final beforeLoop = starfield.debugStarYs();

      starfield.advance(scrollSpeed, 0.02);
      final afterLoop = starfield.debugStarYs();

      for (var i = 0; i < beforeLoop.length; i++) {
        final delta = (afterLoop[i] - beforeLoop[i]).abs();
        final wrappedDelta = 700 - delta;
        expect(
          delta < 2 || wrappedDelta < 2,
          isTrue,
          reason: 'star $i jumped by $delta px at the starfield loop point',
        );
      }
    });
  });
}
