import 'dart:io';

class AdConfig {
  const AdConfig._();

  static String get banner {
    if (Platform.isAndroid) return 'ca-app-pub-3652623512305285/5819814218';
    if (Platform.isIOS) return 'ca-app-pub-3652623512305285/2431233541';
    throw UnsupportedError('Plataforma não suportada para anúncios');
  }
}
