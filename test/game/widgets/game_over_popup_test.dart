import 'dart:typed_data';

import 'package:arcade_one/common/services/share/share_service.dart';
import 'package:arcade_one/game/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/helpers.dart';

class _MockShareService extends Mock implements ShareService {}

void main() {
  setUpAll(() {
    registerFallbackValue(const RunShareResult(message: ''));
  });

  testWidgets('shows the run stats and the new record badge', (tester) async {
    await tester.pumpApp(
      Material(
        child: GameOverPopup(
          distanceKm: 4213,
          bestDistanceKm: 4213,
          maxCombo: 8,
          isNewRecord: true,
          onRestart: () {},
          onReturnToTitle: () {},
        ),
      ),
    );

    expect(find.text('GAME OVER'), findsOneWidget);
    expect(find.text('4213 km'), findsOneWidget);
    expect(find.text('NEW RECORD'), findsOneWidget);
    expect(find.text('Best 4213 km'), findsOneWidget);
    expect(find.text('Max combo x8'), findsOneWidget);
    expect(find.text('Share run'), findsOneWidget);
  });

  testWidgets('shares the captured card through the share service', (
    tester,
  ) async {
    final shareService = _MockShareService();
    when(() => shareService.shareRunResult(any())).thenAnswer((_) async {});
    final cardBytes = Uint8List.fromList([1, 2, 3]);

    await tester.pumpApp(
      Material(
        child: GameOverPopup(
          distanceKm: 4213,
          onRestart: () {},
          onReturnToTitle: () {},
          captureCard: () async => cardBytes,
        ),
      ),
      shareService: shareService,
    );

    await tester.tap(find.text('Share run'));
    await tester.pumpAndSettle();

    final result =
        verify(
              () => shareService.shareRunResult(captureAny()),
            ).captured.single
            as RunShareResult;

    expect(
      result.message,
      equals('I drifted 4213 km in DRIFT SPACE. Can you beat me?'),
    );
    expect(result.cardPng, equals(cardBytes));
  });

  testWidgets('shares text only when the capture fails', (tester) async {
    final shareService = _MockShareService();
    when(() => shareService.shareRunResult(any())).thenAnswer((_) async {});

    await tester.pumpApp(
      Material(
        child: GameOverPopup(
          distanceKm: 10,
          onRestart: () {},
          onReturnToTitle: () {},
          captureCard: () async => null,
        ),
      ),
      shareService: shareService,
    );

    await tester.tap(find.text('Share run'));
    await tester.pumpAndSettle();

    final result =
        verify(
              () => shareService.shareRunResult(captureAny()),
            ).captured.single
            as RunShareResult;

    expect(result.cardPng, isNull);
  });
}
