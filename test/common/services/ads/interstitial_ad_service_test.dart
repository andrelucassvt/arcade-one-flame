import 'package:arcade_one/common/services/ads/interstitial_ad_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mocktail/mocktail.dart';

class _MockInterstitialAd extends Mock implements InterstitialAd {}

void main() {
  group('InterstitialAdService', () {
    late _MockInterstitialAd ad;

    setUp(() {
      ad = _MockInterstitialAd();
      when(ad.show).thenAnswer((_) async {});
      when(ad.dispose).thenAnswer((_) async {});
    });

    test('shows the loaded ad on game over', () {
      final service = InterstitialAdService()
        ..debugAd = ad
        ..showOnGameOver();

      expect(service.isReady, isTrue);
      verify(ad.show).called(1);
    });

    test('does not show again before the cooldown elapses', () {
      var now = DateTime(2026, 9, 14, 12);
      final service = InterstitialAdService(clock: () => now)
        ..debugAd = ad
        ..showOnGameOver();

      now = now.add(const Duration(seconds: 59));
      service.showOnGameOver();

      verify(ad.show).called(1);
    });

    test('shows again after the cooldown elapses', () {
      var now = DateTime(2026, 9, 14, 12);
      final service = InterstitialAdService(clock: () => now)
        ..debugAd = ad
        ..showOnGameOver();

      now = now.add(const Duration(seconds: 60));
      service.showOnGameOver();

      verify(ad.show).called(2);
    });

    test('accepts a custom cooldown', () {
      var now = DateTime(2026, 9, 14, 12);
      final service = InterstitialAdService(
        cooldown: const Duration(seconds: 5),
        clock: () => now,
      )
        ..debugAd = ad
        ..showOnGameOver();

      now = now.add(const Duration(seconds: 5));
      service.showOnGameOver();

      verify(ad.show).called(2);
    });

    test('clears the ad when disposed', () {
      final service = InterstitialAdService()..debugAd = ad;

      expect((service..dispose()).isReady, isFalse);
      verify(ad.dispose).called(1);
    });
  });
}
