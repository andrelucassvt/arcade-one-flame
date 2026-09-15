import 'package:arcade_one/app/app.dart';
import 'package:arcade_one/common/services/in_app_purchase/in_app_purchase_service.dart';
import 'package:arcade_one/common/services/share/share_service.dart';
import 'package:arcade_one/common/services/storage_service.dart';
import 'package:arcade_one/game/cubit/cubit.dart';
import 'package:arcade_one/l10n/l10n.dart';
import 'package:arcade_one/loading/loading.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:mockingjay/mockingjay.dart';

import 'helpers.dart';

class _MockInAppPurchaseService extends Mock
    implements InAppPurchaseService {}

class _MockStorageService extends Mock implements StorageService {}

class _NoopShareService implements ShareService {
  @override
  Future<void> shareRunResult(RunShareResult result) async {}
}

StorageService _buildMockStorage() {
  final storage = _MockStorageService();
  when(() => storage.getString(any())).thenAnswer((_) async => null);
  when(() => storage.setString(any(), any())).thenAnswer((_) async {});
  when(() => storage.getDouble(any())).thenAnswer((_) async => null);
  when(() => storage.setDouble(any(), any())).thenAnswer((_) async {});
  when(() => storage.getInt(any())).thenAnswer((_) async => null);
  when(() => storage.setInt(any(), any())).thenAnswer((_) async {});
  when(() => storage.getBool(any())).thenAnswer((_) async => null);
  when(
    () => storage.setBool(any(), value: any(named: 'value')),
  ).thenAnswer((_) async {});
  when(() => storage.remove(any())).thenAnswer((_) async {});
  return storage;
}

ShareService _buildNoopShareService() => _NoopShareService();

InAppPurchaseService _buildMockInAppPurchaseService() {
  final service = _MockInAppPurchaseService();
  when(
    () => service.purchaseStream,
  ).thenAnswer((_) => const Stream<List<PurchaseDetails>>.empty());
  when(service.isAvailable).thenAnswer((_) async => false);
  when(() => service.queryProductDetails(any())).thenAnswer(
    (_) async => ProductDetailsResponse(
      productDetails: const [],
      notFoundIDs: const [],
    ),
  );
  return service;
}

extension PumpApp on WidgetTester {
  Future<void> pumpApp(
    Widget widget, {
    MockNavigator? navigator,
    AppLocaleCubit? appLocaleCubit,
    PreloadCubit? preloadCubit,
    AudioCubit? audioCubit,
    RemoveAdsCubit? removeAdsCubit,
    StorageService? storageService,
    ShareService? shareService,
  }) {
    final storage = storageService ?? _buildMockStorage();
    final localeCubit = appLocaleCubit ?? AppLocaleCubit(storage: storage);
    final resolvedRemoveAdsCubit =
        removeAdsCubit ??
        RemoveAdsCubit(
          storage: storage,
          service: _buildMockInAppPurchaseService(),
        );
    final resolvedAudioCubit =
        audioCubit ??
        AudioCubit.test(
          deathPlayer: AudioPlayer(),
          bgmPlayer: AudioPlayer(),
        );
    return pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<StorageService>.value(value: storage),
          RepositoryProvider<ShareService>.value(
            value: shareService ?? _buildNoopShareService(),
          ),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: localeCubit),
            BlocProvider.value(value: preloadCubit ?? MockPreloadCubit()),
            BlocProvider.value(value: resolvedAudioCubit),
            BlocProvider.value(value: resolvedRemoveAdsCubit),
          ],
          child: BlocBuilder<AppLocaleCubit, Locale?>(
            builder: (context, locale) {
              return MaterialApp(
                locale: locale,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
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
