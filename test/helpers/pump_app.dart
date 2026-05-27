import 'package:arcade_one/app/app.dart';
import 'package:arcade_one/common/services/storage_service.dart';
import 'package:arcade_one/game/cubit/cubit.dart';
import 'package:arcade_one/l10n/l10n.dart';
import 'package:arcade_one/loading/loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockingjay/mockingjay.dart';

import 'helpers.dart';

class _MockStorageService extends Mock implements StorageService {}

StorageService _buildMockStorage() {
  final storage = _MockStorageService();
  when(() => storage.getString(any())).thenAnswer((_) async => null);
  when(() => storage.setString(any(), any())).thenAnswer((_) async {});
  when(() => storage.getDouble(any())).thenAnswer((_) async => null);
  when(() => storage.setDouble(any(), any())).thenAnswer((_) async {});
  when(() => storage.getInt(any())).thenAnswer((_) async => null);
  when(() => storage.setInt(any(), any())).thenAnswer((_) async {});
  when(() => storage.getBool(any())).thenAnswer((_) async => null);
  when(() => storage.setBool(any(), value: any(named: 'value')))
      .thenAnswer((_) async {});
  when(() => storage.remove(any())).thenAnswer((_) async {});
  return storage;
}

extension PumpApp on WidgetTester {
  Future<void> pumpApp(
    Widget widget, {
    MockNavigator? navigator,
    AppLocaleCubit? appLocaleCubit,
    PreloadCubit? preloadCubit,
    AudioCubit? audioCubit,
    StorageService? storageService,
  }) {
    final storage = storageService ?? _buildMockStorage();
    final localeCubit =
        appLocaleCubit ?? AppLocaleCubit(storage: storage);
    return pumpWidget(
      RepositoryProvider<StorageService>.value(
        value: storage,
        child: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: localeCubit),
            BlocProvider.value(value: preloadCubit ?? MockPreloadCubit()),
          ],
          child: BlocBuilder<AppLocaleCubit, Locale?>(
            builder: (context, locale) {
              return MaterialApp(
                locale: locale,
                localizationsDelegates:
                    AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: navigator != null
                    ? MockNavigatorProvider(
                        navigator: navigator,
                        child: widget,
                      )
                    : widget,
              );
            },
          ),
        ),
      ),
    );
  }
}
