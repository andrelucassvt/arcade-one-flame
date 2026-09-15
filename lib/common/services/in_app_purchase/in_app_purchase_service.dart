import 'package:in_app_purchase/in_app_purchase.dart';

/// Interface fina sobre o plugin de compras.
///
/// Cubits dependem deste contrato, nunca de [InAppPurchase] diretamente.
abstract class InAppPurchaseService {
  Future<bool> isAvailable();

  Future<ProductDetailsResponse> queryProductDetails(Set<String> ids);

  Future<bool> buyNonConsumable(PurchaseParam param);

  Future<void> completePurchase(PurchaseDetails purchase);

  Future<void> restorePurchases();

  Stream<List<PurchaseDetails>> get purchaseStream;
}
