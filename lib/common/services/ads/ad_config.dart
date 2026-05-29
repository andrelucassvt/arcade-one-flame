import 'dart:io';

class AdConfig {
  const AdConfig._();

  static String? get maybeBanner {
    if (Platform.isAndroid) return 'ca-app-pub-3652623512305285/5819814218';
    if (Platform.isIOS) return 'ca-app-pub-3652623512305285/2431233541';
    return null;
  }

  static String? get maybeFallbackBanner {
    if (Platform.isAndroid) return 'ca-app-pub-3652623512305285/1913109829';
    if (Platform.isIOS) return 'ca-app-pub-3652623512305285/9015528627';
    return null;
  }

  static String get banner {
    final adUnitId = maybeBanner;
    if (adUnitId != null) {
      return adUnitId;
    }

    throw UnsupportedError('Plataforma não suportada para anúncios');
  }
}
