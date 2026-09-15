import 'dart:async';
import 'dart:developer';

import 'package:arcade_one/common/services/ads/ad_config.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class InterstitialAdService {
  InterstitialAdService({
    this.cooldown = const Duration(seconds: 60),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final Duration cooldown;
  final DateTime Function() _clock;

  InterstitialAd? _interstitialAd;
  bool _isLoading = false;
  DateTime? _lastShownAt;

  bool get isReady => _interstitialAd != null;

  Future<void> load() async {
    final adUnitId = AdConfig.maybeInterstitial;
    if (adUnitId == null || _isLoading || _interstitialAd != null) {
      return;
    }

    _isLoading = true;
    try {
      await InterstitialAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _isLoading = false;
            _interstitialAd = ad;
            log('InterstitialAdService: ad loaded');

            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                unawaited(ad.dispose());
                _interstitialAd = null;
                unawaited(load());
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                log('InterstitialAdService: failed to show — $error');
                unawaited(ad.dispose());
                _interstitialAd = null;
              },
            );
          },
          onAdFailedToLoad: (error) {
            _isLoading = false;
            log('InterstitialAdService: failed to load — $error');
          },
        ),
      );
    } on Object catch (error) {
      _isLoading = false;
      log('InterstitialAdService: load threw — $error');
    }
  }

  void showOnGameOver() {
    final ad = _interstitialAd;
    if (ad == null) {
      unawaited(load());
      return;
    }

    final now = _clock();
    final lastShownAt = _lastShownAt;
    if (lastShownAt != null && now.difference(lastShownAt) < cooldown) {
      return;
    }

    _lastShownAt = now;
    unawaited(ad.show());
  }

  void dispose() {
    unawaited(_interstitialAd?.dispose());
    _interstitialAd = null;
  }

  @visibleForTesting
  InterstitialAd? get debugAd => _interstitialAd;

  @visibleForTesting
  set debugAd(InterstitialAd? ad) => _interstitialAd = ad;
}
