import 'package:equatable/equatable.dart';

enum RemoveAdsNotice {
  purchaseSuccess,
  purchaseFailed,
  restoreNothingFound,
  storeUnavailable,
}

class RemoveAdsState extends Equatable {
  const RemoveAdsState({
    this.hasRemovedAds = false,
    this.productPriceLabel,
    this.isStoreAvailable = false,
    this.purchasePending = false,
    this.notice,
  });

  final bool hasRemovedAds;
  final String? productPriceLabel;
  final bool isStoreAvailable;
  final bool purchasePending;
  final RemoveAdsNotice? notice;

  RemoveAdsState copyWith({
    bool? hasRemovedAds,
    String? productPriceLabel,
    bool? isStoreAvailable,
    bool? purchasePending,
    RemoveAdsNotice? notice,
    bool clearNotice = false,
  }) {
    return RemoveAdsState(
      hasRemovedAds: hasRemovedAds ?? this.hasRemovedAds,
      productPriceLabel: productPriceLabel ?? this.productPriceLabel,
      isStoreAvailable: isStoreAvailable ?? this.isStoreAvailable,
      purchasePending: purchasePending ?? this.purchasePending,
      notice: clearNotice ? null : notice ?? this.notice,
    );
  }

  @override
  List<Object?> get props => [
    hasRemovedAds,
    productPriceLabel,
    isStoreAvailable,
    purchasePending,
    notice,
  ];
}
