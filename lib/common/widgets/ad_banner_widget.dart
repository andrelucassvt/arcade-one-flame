import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdBannerWidget extends StatefulWidget {
  const AdBannerWidget({
    required this.adUnitId,
    this.fallbackAdUnitId,
    this.adSize = AdSize.banner,
    super.key,
  });

  final String adUnitId;
  final String? fallbackAdUnitId;
  final AdSize adSize;

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _usedFallback = false;

  @override
  void initState() {
    super.initState();
    _loadAd(widget.adUnitId);
  }

  void _loadAd(String adUnitId) {
    final ad = BannerAd(
      adUnitId: adUnitId,
      size: widget.adSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          log('AdBannerWidget: failed to load ($adUnitId) — $error');
          unawaited(ad.dispose());
          _bannerAd = null;

          final fallback = widget.fallbackAdUnitId;
          if (!_usedFallback && fallback != null) {
            _usedFallback = true;
            _loadAd(fallback);
          }
        },
      ),
    );
    _bannerAd = ad;
    unawaited(ad.load());
  }

  @override
  void dispose() {
    unawaited(_bannerAd?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _bannerAd == null) return const SizedBox.shrink();

    return SizedBox(
      width: widget.adSize.width.toDouble(),
      height: widget.adSize.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
