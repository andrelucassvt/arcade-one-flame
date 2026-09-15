import 'dart:async';

import 'package:arcade_one/app/cubit/cubit.dart';
import 'package:arcade_one/common/services/in_app_purchase/in_app_purchase_service.dart';
import 'package:arcade_one/common/services/in_app_purchase/purchase_ids.dart';
import 'package:arcade_one/common/services/storage_service.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:mocktail/mocktail.dart';

class _MockInAppPurchaseService extends Mock
    implements InAppPurchaseService {}

class _MockStorageService extends Mock implements StorageService {}

class _FakePurchaseParam extends Fake implements PurchaseParam {}

class _FakePurchaseDetails extends Fake implements PurchaseDetails {}

void main() {
  group('RemoveAdsCubit', () {
    late StorageService storage;
    late InAppPurchaseService service;
    late StreamController<List<PurchaseDetails>> purchaseController;

    final productDetails = ProductDetails(
      id: removeAdsProductId,
      title: 'Remove ads',
      description: 'Play without banners',
      price: r'R$ 6,99',
      rawPrice: 6.99,
      currencyCode: 'BRL',
    );

    PurchaseDetails buildPurchase(PurchaseStatus status) {
      return PurchaseDetails(
        productID: removeAdsProductId,
        purchaseID: 'purchase-1',
        status: status,
        transactionDate: '2026-01-01',
        verificationData: PurchaseVerificationData(
          localVerificationData: 'local',
          serverVerificationData: 'server',
          source: 'test',
        ),
      );
    }

    setUpAll(() {
      registerFallbackValue(_FakePurchaseParam());
      registerFallbackValue(_FakePurchaseDetails());
      registerFallbackValue(<String>{});
    });

    setUp(() {
      storage = _MockStorageService();
      when(() => storage.getBool(any())).thenAnswer((_) async => null);
      when(
        () => storage.setBool(any(), value: any(named: 'value')),
      ).thenAnswer((_) async {});

      service = _MockInAppPurchaseService();
      purchaseController = StreamController<List<PurchaseDetails>>();
      when(
        () => service.purchaseStream,
      ).thenAnswer((_) => purchaseController.stream);
    });

    tearDown(() {
      unawaited(purchaseController.close());
    });

    test('estado inicial não tem entitlement nem loja disponível', () {
      expect(
        RemoveAdsCubit(storage: storage, service: service).state,
        const RemoveAdsState(),
      );
    });

    blocTest<RemoveAdsCubit, RemoveAdsState>(
      'init emite hasRemovedAds quando o storage tem o entitlement',
      setUp: () {
        when(
          () => storage.getBool('remove_ads_purchased'),
        ).thenAnswer((_) async => true);
      },
      build: () => RemoveAdsCubit(storage: storage, service: service),
      act: (cubit) => cubit.init(),
      expect: () => [
        isA<RemoveAdsState>().having(
          (state) => state.hasRemovedAds,
          'hasRemovedAds',
          isTrue,
        ),
      ],
    );

    blocTest<RemoveAdsCubit, RemoveAdsState>(
      'init não emite quando o storage está vazio',
      build: () => RemoveAdsCubit(storage: storage, service: service),
      act: (cubit) => cubit.init(),
      expect: () => <RemoveAdsState>[],
    );

    blocTest<RemoveAdsCubit, RemoveAdsState>(
      'buy chama buyNonConsumable com o produto de remover anúncios',
      setUp: () {
        when(() => service.isAvailable()).thenAnswer((_) async => true);
        when(() => service.queryProductDetails(any())).thenAnswer(
          (_) async => ProductDetailsResponse(
            productDetails: [productDetails],
            notFoundIDs: const [],
          ),
        );
        when(
          () => service.buyNonConsumable(any()),
        ).thenAnswer((_) async => true);
      },
      build: () => RemoveAdsCubit(storage: storage, service: service),
      act: (cubit) async {
        await cubit.loadProduct();
        await cubit.buy();
      },
      verify: (_) {
        final captured = verify(
          () => service.buyNonConsumable(captureAny()),
        ).captured;
        final param = captured.single as PurchaseParam;
        expect(param.productDetails.id, equals(removeAdsProductId));
      },
    );

    for (final status in [PurchaseStatus.purchased, PurchaseStatus.restored]) {
      blocTest<RemoveAdsCubit, RemoveAdsState>(
        'evento $status persiste o entitlement, completa a compra e '
        'emite sucesso',
        setUp: () {
          when(
            () => service.completePurchase(any()),
          ).thenAnswer((_) async {});
        },
        build: () => RemoveAdsCubit(storage: storage, service: service),
        act: (cubit) async {
          await cubit.init();
          purchaseController.add([buildPurchase(status)]);
          await pumpEventQueue();
        },
        expect: () => [
          isA<RemoveAdsState>()
              .having(
                (state) => state.hasRemovedAds,
                'hasRemovedAds',
                isTrue,
              )
              .having(
                (state) => state.notice,
                'notice',
                RemoveAdsNotice.purchaseSuccess,
              ),
        ],
        verify: (_) {
          verify(
            () => storage.setBool('remove_ads_purchased', value: true),
          ).called(1);
          verify(() => service.completePurchase(any())).called(1);
        },
      );
    }

    for (final status in [PurchaseStatus.canceled, PurchaseStatus.error]) {
      blocTest<RemoveAdsCubit, RemoveAdsState>(
        'evento $status não persiste, completa a compra e emite falha',
        setUp: () {
          when(
            () => service.completePurchase(any()),
          ).thenAnswer((_) async {});
        },
        build: () => RemoveAdsCubit(storage: storage, service: service),
        act: (cubit) async {
          await cubit.init();
          purchaseController.add([buildPurchase(status)]);
          await pumpEventQueue();
        },
        expect: () => [
          isA<RemoveAdsState>().having(
            (state) => state.notice,
            'notice',
            RemoveAdsNotice.purchaseFailed,
          ),
        ],
        verify: (_) {
          verifyNever(
            () => storage.setBool('remove_ads_purchased', value: true),
          );
          verify(() => service.completePurchase(any())).called(1);
        },
      );
    }

    blocTest<RemoveAdsCubit, RemoveAdsState>(
      'evento pending emite purchasePending sem persistir',
      build: () => RemoveAdsCubit(storage: storage, service: service),
      act: (cubit) async {
        await cubit.init();
        purchaseController.add([buildPurchase(PurchaseStatus.pending)]);
        await pumpEventQueue();
      },
      expect: () => [
        isA<RemoveAdsState>().having(
          (state) => state.purchasePending,
          'purchasePending',
          isTrue,
        ),
      ],
      verify: (_) {
        verifyNever(
          () => storage.setBool('remove_ads_purchased', value: true),
        );
        verifyNever(() => service.completePurchase(any()));
      },
    );

    blocTest<RemoveAdsCubit, RemoveAdsState>(
      'restore com stream vazio emite restoreNothingFound',
      setUp: () {
        when(() => service.restorePurchases()).thenAnswer((_) async {});
      },
      build: () => RemoveAdsCubit(storage: storage, service: service),
      act: (cubit) async {
        await cubit.init();
        await cubit.restore();
        purchaseController.add(const <PurchaseDetails>[]);
        await pumpEventQueue();
      },
      expect: () => [
        isA<RemoveAdsState>().having(
          (state) => state.purchasePending,
          'purchasePending',
          isTrue,
        ),
        isA<RemoveAdsState>().having(
          (state) => state.notice,
          'notice',
          RemoveAdsNotice.restoreNothingFound,
        ),
      ],
      verify: (_) {
        verify(() => service.restorePurchases()).called(1);
      },
    );

    blocTest<RemoveAdsCubit, RemoveAdsState>(
      'erro na subscription emite storeUnavailable',
      build: () => RemoveAdsCubit(storage: storage, service: service),
      act: (cubit) async {
        await cubit.init();
        purchaseController.addError(Exception('store failure'));
        await pumpEventQueue();
      },
      expect: () => [
        isA<RemoveAdsState>().having(
          (state) => state.notice,
          'notice',
          RemoveAdsNotice.storeUnavailable,
        ),
      ],
    );
  });
}
