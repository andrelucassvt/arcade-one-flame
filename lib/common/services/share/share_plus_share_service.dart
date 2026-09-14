import 'dart:io';

import 'package:arcade_one/common/services/share/share_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Implementação de [ShareService] usando o share sheet nativo.
class SharePlusShareService implements ShareService {
  const SharePlusShareService();

  static const String _cardFileName = 'drift_run_card.png';

  @override
  Future<void> shareRunResult(RunShareResult result) async {
    final cardPng = result.cardPng;
    if (cardPng == null) {
      await SharePlus.instance.share(
        ShareParams(
          text: result.message,
          sharePositionOrigin: result.sharePositionOrigin,
        ),
      );
      return;
    }

    final directory = await getTemporaryDirectory();
    final cardFile = File('${directory.path}/$_cardFileName');
    await cardFile.writeAsBytes(cardPng, flush: true);

    await SharePlus.instance.share(
      ShareParams(
        text: result.message,
        files: [XFile(cardFile.path)],
        sharePositionOrigin: result.sharePositionOrigin,
      ),
    );
  }
}
