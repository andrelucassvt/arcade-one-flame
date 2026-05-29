import 'dart:async';

import 'package:arcade_one/common/services/storage_service.dart';
import 'package:arcade_one/game/game.dart';
import 'package:arcade_one/title/title.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockingjay/mockingjay.dart';

import '../../helpers/helpers.dart';

class _MockAudioCubit extends MockCubit<AudioState> implements AudioCubit {}

class _MockStorageService extends Mock implements StorageService {}

void main() {
  group('TitleView', () {
    setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

    testWidgets('renders start button', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpApp(const TitleView());

      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.text('Launch'), findsOneWidget);
      expect(find.text('Choose ship'), findsOneWidget);
      expect(find.text('Scout'), findsOneWidget);
      expect(find.text('Controls'), findsOneWidget);
      expect(find.text('Tap'), findsOneWidget);
      expect(find.text('Joystick'), findsOneWidget);
    });

    testWidgets('changes language from the title screen', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpApp(const TitleView());

      await tester.tap(find.byIcon(Icons.language_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Português').last);
      await tester.pumpAndSettle();

      expect(find.text('Decolar'), findsOneWidget);
    });

    testWidgets('toggles audio from the title screen', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final audioCubit = _MockAudioCubit();
      final controller = StreamController<AudioState>();
      addTearDown(controller.close);
      when(audioCubit.toggleVolume).thenAnswer((_) async {});
      whenListen(
        audioCubit,
        controller.stream,
        initialState: const AudioState(),
      );

      await tester.pumpApp(const TitleView(), audioCubit: audioCubit);

      expect(find.byIcon(Icons.volume_up), findsOneWidget);

      await tester.tap(find.byIcon(Icons.volume_up));
      verify(audioCubit.toggleVolume).called(1);

      controller.add(const AudioState(volume: 0));
      await tester.pump();

      expect(find.byIcon(Icons.volume_off), findsOneWidget);
    });

    testWidgets('starts the game when start button is tapped', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final navigator = MockNavigator();
      when(navigator.canPop).thenReturn(true);
      when(
        () => navigator.pushReplacement<void, void>(any()),
      ).thenAnswer((_) async {});

      await tester.pumpApp(const TitleView(), navigator: navigator);

      await tester.ensureVisible(find.byType(ElevatedButton));
      await tester.tap(find.byType(ElevatedButton));

      verify(() => navigator.pushReplacement<void, void>(any())).called(1);
    });

    testWidgets('starts the game with the selected control mode', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final navigator = MockNavigator();
      when(navigator.canPop).thenReturn(true);
      when(
        () => navigator.pushReplacement<void, void>(any()),
      ).thenAnswer((_) async {});

      await tester.pumpApp(const TitleView(), navigator: navigator);

      await tester.tap(find.text('Joystick'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(ElevatedButton));
      await tester.tap(find.byType(ElevatedButton));

      final route =
          verify(
                () => navigator.pushReplacement<void, void>(captureAny()),
              ).captured.single
              as MaterialPageRoute<void>;
      final page =
          route.builder(
                tester.element(find.byType(TitleView)),
              )
              as GamePage;

      expect(page.controlMode, equals(GameControlMode.joystick));
      expect(page.playerShip, equals(defaultPlayerShipSkin));
    });

    testWidgets('opens ship selector and persists an unlocked ship', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final storage = _MockStorageService();
      when(() => storage.getString(any())).thenAnswer((_) async => null);
      when(() => storage.setString(any(), any())).thenAnswer((_) async {});
      when(() => storage.getDouble(any())).thenAnswer((_) async => null);
      when(
        () => storage.getDouble(bestDistanceStorageKey),
      ).thenAnswer((_) async => 250);

      await tester.pumpApp(const TitleView(), storageService: storage);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Choose ship'));
      await tester.pumpAndSettle();

      expect(find.text('Select ship'), findsOneWidget);
      expect(find.text('Mars Comet'), findsOneWidget);
      expect(find.text('Rockhopper'), findsOneWidget);

      await tester.tap(find.text('Rockhopper'));
      await tester.pumpAndSettle();

      verifyNever(
        () => storage.setString('title_player_ship', 'asteroid_belt'),
      );

      await tester.tap(find.text('Mars Comet'));
      await tester.pumpAndSettle();

      verify(() => storage.setString('title_player_ship', 'mars')).called(1);
      expect(find.text('Mars Comet'), findsOneWidget);
    });

    testWidgets('starts the game with the selected player ship', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final navigator = MockNavigator();
      when(navigator.canPop).thenReturn(true);
      when(
        () => navigator.pushReplacement<void, void>(any()),
      ).thenAnswer((_) async {});

      final storage = _MockStorageService();
      when(() => storage.getString(any())).thenAnswer((_) async => null);
      when(
        () => storage.getString('title_player_ship'),
      ).thenAnswer((_) async => 'mars');
      when(() => storage.setString(any(), any())).thenAnswer((_) async {});
      when(() => storage.getDouble(any())).thenAnswer((_) async => null);
      when(
        () => storage.getDouble(bestDistanceStorageKey),
      ).thenAnswer((_) async => 250);

      await tester.pumpApp(
        const TitleView(),
        navigator: navigator,
        storageService: storage,
      );
      await tester.pumpAndSettle();

      expect(find.text('Mars Comet'), findsOneWidget);

      await tester.ensureVisible(find.byType(ElevatedButton));
      await tester.tap(find.byType(ElevatedButton));

      final route =
          verify(
                () => navigator.pushReplacement<void, void>(captureAny()),
              ).captured.single
              as MaterialPageRoute<void>;
      final page =
          route.builder(
                tester.element(find.byType(TitleView)),
              )
              as GamePage;

      expect(page.playerShip, equals(playerShipSkinById('mars')));
    });

    testWidgets('persists the selected control mode', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final storage = _MockStorageService();
      when(() => storage.getString(any())).thenAnswer((_) async => null);
      when(() => storage.setString(any(), any())).thenAnswer((_) async {});
      when(() => storage.getDouble(any())).thenAnswer((_) async => null);

      await tester.pumpApp(const TitleView(), storageService: storage);

      await tester.tap(find.text('Joystick'));
      await tester.pumpAndSettle();

      verify(
        () => storage.setString('title_control_mode', 'joystick'),
      ).called(1);
    });

    testWidgets('restores the persisted control mode', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final navigator = MockNavigator();
      when(navigator.canPop).thenReturn(true);
      when(
        () => navigator.pushReplacement<void, void>(any()),
      ).thenAnswer((_) async {});

      final storage = _MockStorageService();
      when(() => storage.getString(any())).thenAnswer((_) async => null);
      when(
        () => storage.getString('title_control_mode'),
      ).thenAnswer((_) async => 'joystick');
      when(() => storage.getDouble(any())).thenAnswer((_) async => null);

      await tester.pumpApp(
        const TitleView(),
        navigator: navigator,
        storageService: storage,
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byType(ElevatedButton));
      await tester.tap(find.byType(ElevatedButton));

      final route =
          verify(
                () => navigator.pushReplacement<void, void>(captureAny()),
              ).captured.single
              as MaterialPageRoute<void>;
      final page =
          route.builder(
                tester.element(find.byType(TitleView)),
              )
              as GamePage;

      expect(page.controlMode, equals(GameControlMode.joystick));
    });
  });
}
