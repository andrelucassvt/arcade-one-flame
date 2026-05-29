import 'package:arcade_one/game/game.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('playerShipSkins', () {
    test('keeps the default ship unlocked at 0 km', () {
      expect(defaultPlayerShipSkin.unlockKm, equals(0));
      expect(isPlayerShipUnlocked(defaultPlayerShipSkin, 0), isTrue);
      expect(
        unlockedPlayerShipSkins(0),
        equals([defaultPlayerShipSkin]),
      );
    });

    test('uses the background milestone distances as unlock requirements', () {
      expect(
        playerShipSkins.map((ship) => ship.unlockKm).toList(),
        equals(<double>[
          0,
          250,
          600,
          1000,
          1500,
          2100,
          2800,
          3600,
          4500,
          5600,
          7000,
          8500,
        ]),
      );
    });

    test('returns unlocked ships for the best distance', () {
      expect(
        unlockedPlayerShipSkins(1000).map((ship) => ship.id),
        equals(['default', 'mars', 'asteroid_belt', 'jupiter']),
      );
    });

    test('falls back to the default ship for unknown ids', () {
      expect(playerShipSkinById('missing'), equals(defaultPlayerShipSkin));
    });
  });
}
