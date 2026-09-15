import 'dart:async';

import 'package:arcade_one/app/app.dart';
import 'package:arcade_one/title/content/title_remove_ads_dialog.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/helpers.dart';

class _MockRemoveAdsCubit extends MockCubit<RemoveAdsState>
    implements RemoveAdsCubit {}

void main() {
  group('TitleRemoveAdsDialog', () {
    late _MockRemoveAdsCubit removeAdsCubit;
    late StreamController<RemoveAdsState> controller;

    setUp(() {
      removeAdsCubit = _MockRemoveAdsCubit();
      controller = StreamController<RemoveAdsState>();
      addTearDown(controller.close);
    });

    Future<void> pumpDialog(
      WidgetTester tester, {
      required RemoveAdsState state,
    }) {
      whenListen(removeAdsCubit, controller.stream, initialState: state);

      return tester.pumpApp(
        const Material(child: TitleRemoveAdsDialog()),
        removeAdsCubit: removeAdsCubit,
      );
    }

    testWidgets('shows the localized price and buys the product', (
      tester,
    ) async {
      when(removeAdsCubit.buy).thenAnswer((_) async {});

      await pumpDialog(
        tester,
        state: const RemoveAdsState(
          isStoreAvailable: true,
          productPriceLabel: r'R$ 19,90',
        ),
      );

      expect(find.text(r'Buy for R$ 19,90'), findsOneWidget);

      await tester.tap(find.text(r'Buy for R$ 19,90'));
      await tester.pump();

      verify(removeAdsCubit.buy).called(1);
    });

    testWidgets('disables buy and warns when the store is unavailable', (
      tester,
    ) async {
      await pumpDialog(tester, state: const RemoveAdsState());

      expect(find.text('Store unavailable. Try again later.'), findsOneWidget);

      final buyButton = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(buyButton.onPressed, isNull);
    });

    testWidgets('restores previous purchases', (tester) async {
      when(removeAdsCubit.restore).thenAnswer((_) async {});

      await pumpDialog(
        tester,
        state: const RemoveAdsState(
          isStoreAvailable: true,
          productPriceLabel: r'R$ 19,90',
        ),
      );

      await tester.tap(find.text('Restore purchases'));
      await tester.pump();

      verify(removeAdsCubit.restore).called(1);
    });

    testWidgets('keeps the dialog open showing the restore notice', (
      tester,
    ) async {
      await pumpDialog(
        tester,
        state: const RemoveAdsState(
          isStoreAvailable: true,
          notice: RemoveAdsNotice.restoreNothingFound,
        ),
      );

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('No purchases to restore.'), findsOneWidget);
    });

    testWidgets('hides the purchase actions after the entitlement is active', (
      tester,
    ) async {
      await pumpDialog(
        tester,
        state: const RemoveAdsState(
          hasRemovedAds: true,
          isStoreAvailable: true,
          notice: RemoveAdsNotice.purchaseSuccess,
        ),
      );

      expect(find.text('Purchase complete. Ads removed.'), findsOneWidget);
      expect(find.byType(FilledButton), findsNothing);
      expect(find.text('Restore purchases'), findsNothing);
    });
  });
}
