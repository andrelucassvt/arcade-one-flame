import 'package:arcade_one/common/services/storage_service.dart';
import 'package:arcade_one/game/game.dart';
import 'package:arcade_one/title/title.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockStorageService extends Mock implements StorageService {}

void main() {
  group('TitleShipSelectionCubit', () {
    late StorageService storage;

    setUp(() {
      storage = _MockStorageService();
      when(() => storage.getString(any())).thenAnswer((_) async => null);
      when(() => storage.setString(any(), any())).thenAnswer((_) async {});
    });

    test('estado inicial e a nave default', () {
      expect(
        TitleShipSelectionCubit(storage: storage).state,
        equals(defaultPlayerShipSkin),
      );
    });

    blocTest<TitleShipSelectionCubit, PlayerShipSkin>(
      'init emite nave persistida quando ela esta desbloqueada',
      setUp: () {
        when(
          () => storage.getString(TitleShipSelectionCubit.keyPlayerShip),
        ).thenAnswer((_) async => 'mars');
      },
      build: () => TitleShipSelectionCubit(storage: storage),
      act: (cubit) => cubit.init(bestDistanceKm: 250),
      expect: () => [playerShipSkinById('mars')],
    );

    blocTest<TitleShipSelectionCubit, PlayerShipSkin>(
      'init ignora valor invalido persistido',
      setUp: () {
        when(
          () => storage.getString(TitleShipSelectionCubit.keyPlayerShip),
        ).thenAnswer((_) async => 'invalid');
      },
      build: () => TitleShipSelectionCubit(storage: storage),
      act: (cubit) => cubit.init(bestDistanceKm: 8500),
      expect: () => <PlayerShipSkin>[],
    );

    blocTest<TitleShipSelectionCubit, PlayerShipSkin>(
      'init ignora nave persistida ainda bloqueada',
      setUp: () {
        when(
          () => storage.getString(TitleShipSelectionCubit.keyPlayerShip),
        ).thenAnswer((_) async => 'jupiter');
      },
      build: () => TitleShipSelectionCubit(storage: storage),
      act: (cubit) => cubit.init(bestDistanceKm: 999),
      expect: () => <PlayerShipSkin>[],
    );

    blocTest<TitleShipSelectionCubit, PlayerShipSkin>(
      'setShip salva e emite nave desbloqueada',
      build: () => TitleShipSelectionCubit(storage: storage),
      act: (cubit) => cubit.setShip(
        playerShipSkinById('mars'),
        bestDistanceKm: 250,
      ),
      expect: () => [playerShipSkinById('mars')],
      verify: (_) {
        verify(
          () => storage.setString(
            TitleShipSelectionCubit.keyPlayerShip,
            'mars',
          ),
        ).called(1);
      },
    );

    blocTest<TitleShipSelectionCubit, PlayerShipSkin>(
      'setShip ignora nave bloqueada',
      build: () => TitleShipSelectionCubit(storage: storage),
      act: (cubit) => cubit.setShip(
        playerShipSkinById('asteroid_belt'),
        bestDistanceKm: 250,
      ),
      expect: () => <PlayerShipSkin>[],
      verify: (_) {
        verifyNever(
          () => storage.setString(
            TitleShipSelectionCubit.keyPlayerShip,
            'asteroid_belt',
          ),
        );
      },
    );
  });
}
