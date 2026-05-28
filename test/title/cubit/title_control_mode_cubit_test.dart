import 'package:arcade_one/common/services/storage_service.dart';
import 'package:arcade_one/game/game.dart';
import 'package:arcade_one/title/title.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockStorageService extends Mock implements StorageService {}

void main() {
  group('TitleControlModeCubit', () {
    late StorageService storage;

    setUp(() {
      storage = _MockStorageService();
      when(() => storage.getString(any())).thenAnswer((_) async => null);
      when(() => storage.setString(any(), any())).thenAnswer((_) async {});
    });

    test('estado inicial é touch', () {
      expect(
        TitleControlModeCubit(storage: storage).state,
        equals(GameControlMode.touch),
      );
    });

    blocTest<TitleControlModeCubit, GameControlMode>(
      'init emite modo persistido quando storage retorna joystick',
      setUp: () {
        when(
          () => storage.getString('title_control_mode'),
        ).thenAnswer((_) async => 'joystick');
      },
      build: () => TitleControlModeCubit(storage: storage),
      act: (cubit) => cubit.init(),
      expect: () => [GameControlMode.joystick],
    );

    blocTest<TitleControlModeCubit, GameControlMode>(
      'init ignora valor invalido persistido',
      setUp: () {
        when(
          () => storage.getString('title_control_mode'),
        ).thenAnswer((_) async => 'invalid');
      },
      build: () => TitleControlModeCubit(storage: storage),
      act: (cubit) => cubit.init(),
      expect: () => <GameControlMode>[],
    );

    blocTest<TitleControlModeCubit, GameControlMode>(
      'setControlMode salva e emite o modo selecionado',
      build: () => TitleControlModeCubit(storage: storage),
      act: (cubit) => cubit.setControlMode(GameControlMode.joystick),
      expect: () => [GameControlMode.joystick],
      verify: (_) {
        verify(
          () => storage.setString('title_control_mode', 'joystick'),
        ).called(1);
      },
    );

    blocTest<TitleControlModeCubit, GameControlMode>(
      'setControlMode com mesmo modo não emite novo estado',
      build: () => TitleControlModeCubit(storage: storage),
      act: (cubit) => cubit.setControlMode(GameControlMode.touch),
      expect: () => <GameControlMode>[],
    );
  });
}
