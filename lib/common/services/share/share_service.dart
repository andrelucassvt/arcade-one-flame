import 'dart:typed_data';
import 'dart:ui';

/// Dados de uma run usados no compartilhamento.
class RunShareResult {
  const RunShareResult({
    required this.message,
    this.cardPng,
    this.sharePositionOrigin,
  });

  final String message;
  final Uint8List? cardPng;
  final Rect? sharePositionOrigin;
}

/// Interface abstrata de compartilhamento.
///
/// Widgets e serviços devem depender desta interface,
/// nunca do share_plus diretamente.
// ignore: one_member_abstracts
abstract class ShareService {
  Future<void> shareRunResult(RunShareResult result);
}
