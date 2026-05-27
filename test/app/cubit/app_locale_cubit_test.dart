import 'package:arcade_one/app/cubit/cubit.dart';
import 'package:arcade_one/common/services/storage_service.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockStorageService extends Mock implements StorageService {}

void main() {
  group('AppLocaleCubit', () {
    late StorageService storage;

    setUp(() {
      storage = _MockStorageService();
      when(() => storage.getString(any())).thenAnswer((_) async => null);
      when(() => storage.setString(any(), any())).thenAnswer((_) async {});
    });

    test('estado inicial é null', () {
      expect(
        AppLocaleCubit(storage: storage).state,
        isNull,
      );
    });

    blocTest<AppLocaleCubit, Locale?>(
      'init emite Locale("pt") quando storage retorna "pt"',
      setUp: () {
        when(() => storage.getString('app_locale'))
            .thenAnswer((_) async => 'pt');
      },
      build: () => AppLocaleCubit(storage: storage),
      act: (cubit) => cubit.init(),
      expect: () => [const Locale('pt')],
    );

    blocTest<AppLocaleCubit, Locale?>(
      'init não emite nada quando storage retorna null',
      setUp: () {
        when(() => storage.getString('app_locale'))
            .thenAnswer((_) async => null);
      },
      build: () => AppLocaleCubit(storage: storage),
      act: (cubit) => cubit.init(),
      expect: () => <Locale?>[],
    );

    blocTest<AppLocaleCubit, Locale?>(
      'setLocale salva o languageCode e emite o Locale',
      build: () => AppLocaleCubit(storage: storage),
      act: (cubit) => cubit.setLocale(const Locale('en')),
      expect: () => [const Locale('en')],
      verify: (_) {
        verify(() => storage.setString('app_locale', 'en')).called(1);
      },
    );

    blocTest<AppLocaleCubit, Locale?>(
      'setLocale com mesmo locale não emite novo estado',
      seed: () => const Locale('pt'),
      build: () => AppLocaleCubit(storage: storage),
      act: (cubit) => cubit.setLocale(const Locale('pt')),
      expect: () => <Locale?>[],
    );
  });
}
