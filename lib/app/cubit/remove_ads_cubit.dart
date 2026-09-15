import 'dart:async';

import 'package:arcade_one/app/cubit/remove_ads_state.dart';
import 'package:arcade_one/common/services/in_app_purchase/in_app_purchase_service.dart';
import 'package:arcade_one/common/services/in_app_purchase/purchase_ids.dart';
import 'package:arcade_one/common/services/storage_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class RemoveAdsCubit extends Cubit<RemoveAdsState> {
  RemoveAdsCubit({
    required StorageService storage,
    required InAppPurchaseService service,
  }) : _storage = storage,
       _service = service,
       super(const RemoveAdsState());

  final StorageService _storage;
  final InAppPurchaseService _service;

  static const storageKey = 'remove_ads_purchased';

  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  ProductDetails? _productDetails;
  bool _restorePending = false;

  /// Restaura o entitlement persistido e passa a escutar a loja.
  Future<void> init() async {
    final purchased = await _storage.getBool(storageKey);
    if (isClosed) {
      return;
    }
    if (purchased ?? false) {
      emit(state.copyWith(hasRemovedAds: true));
    }

    _purchaseSubscription = _service.purchaseStream.listen(
      _onPurchaseUpdates,
      onError: (Object _) {
        if (isClosed) {
          return;
        }
        emit(state.copyWith(notice: RemoveAdsNotice.storeUnavailable));
      },
    );
  }

  /// Busca o preço localizado do produto. Ausência ou falha vira loja
  /// indisponível.
  Future<void> loadProduct() async {
    try {
      final available = await _service.isAvailable();
      if (!available) {
        _emitStoreUnavailable();
        return;
      }

      final response = await _service.queryProductDetails(
        const {removeAdsProductId},
      );
      if (isClosed) {
        return;
      }

      final details = response.productDetails.isEmpty
          ? null
          : response.productDetails.first;
      if (details == null) {
        _emitStoreUnavailable();
        return;
      }

      _productDetails = details;
      emit(
        state.copyWith(
          isStoreAvailable: true,
          productPriceLabel: details.price,
        ),
      );
    } on Exception catch (_) {
      _emitStoreUnavailable();
    }
  }

  /// Inicia a compra não-consumível do produto de remover anúncios.
  Future<void> buy() async {
    final details = _productDetails;
    if (details == null || state.purchasePending) {
      return;
    }

    emit(state.copyWith(purchasePending: true, clearNotice: true));
    try {
      final started = await _service.buyNonConsumable(
        PurchaseParam(productDetails: details),
      );
      if (!started && !isClosed) {
        emit(
          state.copyWith(
            purchasePending: false,
            notice: RemoveAdsNotice.purchaseFailed,
          ),
        );
      }
    } on Exception catch (_) {
      if (!isClosed) {
        emit(
          state.copyWith(
            purchasePending: false,
            notice: RemoveAdsNotice.purchaseFailed,
          ),
        );
      }
    }
  }

  /// Pede à loja a restauração das compras anteriores.
  Future<void> restore() async {
    if (state.hasRemovedAds || state.purchasePending) {
      return;
    }

    _restorePending = true;
    emit(state.copyWith(purchasePending: true, clearNotice: true));
    try {
      await _service.restorePurchases();
    } on Exception catch (_) {
      _restorePending = false;
      if (!isClosed) {
        emit(
          state.copyWith(
            purchasePending: false,
            notice: RemoveAdsNotice.storeUnavailable,
          ),
        );
      }
    }
  }

  void clearNotice() {
    if (state.notice == null) {
      return;
    }

    emit(state.copyWith(clearNotice: true));
  }

  Future<void> _onPurchaseUpdates(List<PurchaseDetails> purchases) async {
    if (_restorePending) {
      _restorePending = false;
      if (purchases.isEmpty) {
        if (!isClosed) {
          emit(
            state.copyWith(
              purchasePending: false,
              notice: RemoveAdsNotice.restoreNothingFound,
            ),
          );
        }
        return;
      }
    }

    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          if (!isClosed) {
            emit(state.copyWith(purchasePending: true));
          }
        case PurchaseStatus.purchased || PurchaseStatus.restored:
          await _service.completePurchase(purchase);
          await _storage.setBool(storageKey, value: true);
          if (!isClosed) {
            emit(
              state.copyWith(
                hasRemovedAds: true,
                purchasePending: false,
                notice: RemoveAdsNotice.purchaseSuccess,
              ),
            );
          }
        case PurchaseStatus.canceled || PurchaseStatus.error:
          await _service.completePurchase(purchase);
          if (!isClosed) {
            emit(
              state.copyWith(
                purchasePending: false,
                notice: RemoveAdsNotice.purchaseFailed,
              ),
            );
          }
      }
    }
  }

  void _emitStoreUnavailable() {
    if (isClosed) {
      return;
    }

    emit(
      state.copyWith(
        isStoreAvailable: false,
        notice: RemoveAdsNotice.storeUnavailable,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _purchaseSubscription?.cancel();
    return super.close();
  }
}
