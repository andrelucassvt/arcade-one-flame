import 'package:arcade_one/game/game.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('spaceLandmarks', () {
    test('is ordered by startKm and has unique ids and assets', () {
      final ids = <String>{};
      final assets = <String>{};

      for (var i = 0; i < spaceLandmarks.length; i++) {
        final landmark = spaceLandmarks[i];
        expect(ids.add(landmark.id), isTrue);
        expect(assets.add(landmark.assetPath), isTrue);

        if (i == 0) {
          continue;
        }

        expect(landmark.startKm, greaterThan(spaceLandmarks[i - 1].startKm));
      }
    });

    test('selects the expected landmark for success cases', () {
      expect(landmarkForDistance(0).id, equals('earth_moon'));
      expect(landmarkForDistance(250).id, equals('mars'));
      expect(landmarkForDistance(1000).id, equals('jupiter'));
      expect(landmarkForDistance(8500).id, equals('deep_quasar'));
    });

    test('keeps lower landmark until the next exact boundary', () {
      expect(landmarkForDistance(249.99).id, equals('earth_moon'));
      expect(landmarkForDistance(250).id, equals('mars'));
      expect(landmarkForDistance(999.99).id, equals('asteroid_belt'));
      expect(landmarkForDistance(1000).id, equals('jupiter'));
    });
  });
}
