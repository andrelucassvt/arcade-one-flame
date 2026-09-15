import 'package:arcade_one/common/services/in_app_purchase/in_app_purchase_service.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// Implementação de [InAppPurchaseService] sobre [InAppPurchase.instance].
class InAppPurchaseServiceImpl implements InAppPurchaseService {
  InAppPurchaseServiceImpl({InAppPurchase? inAppPurchase})
    : _inAppPurchase = inAppPurchase ?? InAppPurchase.instance;

  final InAppPurchase _inAppPurchase;

  @override
  Future<bool> isAvailable() => _inAppPurchase.isAvailable();

  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> ids) =>
      _inAppPurchase.queryProductDetails(ids);

  @override
  Future<bool> buyNonConsumable(PurchaseParam param) =>
      _inAppPurchase.buyNonConsumable(purchaseParam: param);

  @override
  Future<void> completePurchase(PurchaseDetails purchase) =>
      _inAppPurchase.completePurchase(purchase);

  @override
  Future<void> restorePurchases() => _inAppPurchase.restorePurchases();

  @override
  Stream<List<PurchaseDetails>> get purchaseStream =>
      _inAppPurchase.purchaseStream;
}
