// Not needed for test files
// ignore_for_file: prefer_const_constructors

import 'dart:async';
import 'dart:ui';

import 'package:arcade_one/common/services/storage_service.dart';
import 'package:arcade_one/game/game.dart';
import 'package:arcade_one/gen/assets.gen.dart';
import 'package:arcade_one/loading/loading.dart';
import 'package:arcade_one/title/title.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flame/cache.dart';
import 'package:flutter/material.dart' hide Image;
import 'package:flutter_test/flutter_test.dart';
import 'package:mockingjay/mockingjay.dart';

import '../../helpers/helpers.dart';

class _MockImages extends Mock implements Images {}

class _MockAudioCache extends Mock implements AudioCache {}

class _MockStorageService extends Mock implements StorageService {}

void main() {
  group('LoadingPage', () {
    late PreloadCubit preloadCubit;
    late _MockImages images;
    late _MockAudioCache audio;

    setUp(() {
      preloadCubit = PreloadCubit(
        images = _MockImages(),
        audio = _MockAudioCache(),
      );

      when(() => images.loadAll(any())).thenAnswer((_) async => <Image>[]);

      when(
        () => audio.loadAll([Assets.audio.death, Assets.audio.engineFire]),
      ).thenAnswer(
        (_) async => [
          Uri.parse(Assets.audio.death),
          Uri.parse(Assets.audio.engineFire),
        ],
      );
    });

    testWidgets('basic layout', (tester) async {
      await tester.pumpApp(LoadingPage(), preloadCubit: preloadCubit);

      expect(find.byType(AnimatedProgressBar), findsOneWidget);
      expect(find.textContaining('Loading'), findsOneWidget);

      await tester.pumpAndSettle(Duration(seconds: 1));
    });

    testWidgets('loading text', (tester) async {
      Text textWidgetFinder() {
        return find.textContaining('Loading').evaluate().first.widget as Text;
      }

      final navigator = MockNavigator();
      when(navigator.canPop).thenReturn(true);
      when(
        () => navigator.pushReplacement<void, void>(any()),
      ).thenAnswer((_) async {});

      await tester.pumpApp(
        LoadingPage(),
        preloadCubit: preloadCubit,
        navigator: navigator,
      );

      expect(textWidgetFinder().data, 'Loading  ...');

      unawaited(preloadCubit.loadSequentially());

      await tester.pump();

      expect(textWidgetFinder().data, 'Loading Ship sounds...');
      await tester.pump(const Duration(milliseconds: 200));

      expect(textWidgetFinder().data, 'Loading Beautiful scenery...');
      await tester.pump(const Duration(milliseconds: 200));

      /// flush animation timers
      await tester.pumpAndSettle();
    });

    testWidgets('redirects after loading', (tester) async {
      final navigator = MockNavigator();
      when(navigator.canPop).thenReturn(true);
      when(
        () => navigator.pushReplacement<void, void>(any()),
      ).thenAnswer((_) async {});

      await tester.pumpApp(
        LoadingPage(),
        preloadCubit: preloadCubit,
        navigator: navigator,
      );

      unawaited(preloadCubit.loadSequentially());

      await tester.pump(const Duration(milliseconds: 800));

      await tester.pumpAndSettle();

      verify(() => navigator.pushReplacement<void, void>(any())).called(1);
    });

    testWidgets('opens quick play when there is no best distance', (
      tester,
    ) async {
      final navigator = MockNavigator();
      when(navigator.canPop).thenReturn(true);
      when(
        () => navigator.pushReplacement<void, void>(any()),
      ).thenAnswer((_) async {});

      await tester.pumpApp(
        LoadingPage(),
        preloadCubit: preloadCubit,
        navigator: navigator,
      );

      unawaited(preloadCubit.loadSequentially());

      await tester.pump(const Duration(milliseconds: 800));
      await tester.pumpAndSettle();

      final route =
          verify(
                () => navigator.pushReplacement<void, void>(captureAny()),
              ).captured.single
              as MaterialPageRoute<void>;
      final page = route.builder(tester.element(find.byType(LoadingPage)));

      expect(page, isA<GamePage>());
      expect((page as GamePage).quickPlay, isTrue);
    });

    testWidgets('opens the title when a best distance is stored', (
      tester,
    ) async {
      final navigator = MockNavigator();
      when(navigator.canPop).thenReturn(true);
      when(
        () => navigator.pushReplacement<void, void>(any()),
      ).thenAnswer((_) async {});

      final storage = _MockStorageService();
      when(() => storage.getString(any())).thenAnswer((_) async => null);
      when(() => storage.setString(any(), any())).thenAnswer((_) async {});
      when(() => storage.getDouble(any())).thenAnswer((_) async => 250);

      await tester.pumpApp(
        LoadingPage(),
        preloadCubit: preloadCubit,
        navigator: navigator,
        storageService: storage,
      );

      unawaited(preloadCubit.loadSequentially());

      await tester.pump(const Duration(milliseconds: 800));
      await tester.pumpAndSettle();

      final route =
          verify(
                () => navigator.pushReplacement<void, void>(captureAny()),
              ).captured.single
              as MaterialPageRoute<void>;
      final page = route.builder(tester.element(find.byType(LoadingPage)));

      expect(page, isA<TitleView>());
    });
  });
}
