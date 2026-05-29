// Not needed for test files
// ignore_for_file: prefer_const_constructors

import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:arcade_one/common/services/storage_service.dart';
import 'package:arcade_one/game/game.dart';
import 'package:arcade_one/l10n/l10n.dart';
import 'package:arcade_one/loading/cubit/cubit.dart';
import 'package:arcade_one/title/title.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flame/cache.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/helpers.dart';

class _FakeImage extends Fake implements ui.Image {}

class _MockAppLocalizations extends Mock implements AppLocalizations {}

class _MockAudioCubit extends MockCubit<AudioState> implements AudioCubit {}

class _MockAudioPlayer extends Mock implements AudioPlayer {}

class _MockImages extends Mock implements Images {}

class _MockPreloadCubit extends MockCubit<PreloadState>
    implements PreloadCubit {}

class _MockStorageService extends Mock implements StorageService {}

class _OverlayGame extends ArcadeOne {
  _OverlayGame({
    required super.l10n,
    required super.deathPlayer,
    required super.textStyle,
    required super.images,
    required super.storage,
    super.controlMode,
  });

  @override
  Future<void> onLoad() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // https://github.com/material-foundation/flutter-packages/issues/286#issuecomment-1406343761
  HttpOverrides.global = null;

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          MethodChannel('xyz.luan/audioplayers'),
          (message) => null,
        );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (message) async => switch (message.method) {
            ('getTemporaryDirectory' || 'getApplicationSupportDirectory') =>
              Directory.systemTemp.createTempSync('fake').path,
            _ => null,
          },
        );
  });

  group('GamePage', () {
    late PreloadCubit preloadCubit;
    late Images images;

    setUp(() {
      images = _MockImages();
      when(() => images.fromCache(any())).thenReturn(_FakeImage());

      preloadCubit = _MockPreloadCubit();
      when(() => preloadCubit.audio).thenReturn(AudioCache(prefix: ''));
      when(() => preloadCubit.images).thenReturn(images);
    });

    testWidgets('is routable', (tester) async {
      await tester.pumpApp(
        Builder(
          builder: (context) => Scaffold(
            floatingActionButton: FloatingActionButton(
              onPressed: () => Navigator.of(context).push(GamePage.route()),
            ),
          ),
        ),
        preloadCubit: preloadCubit,
      );

      await tester.tap(find.byType(FloatingActionButton));

      await tester.pump();
      await tester.pump();

      expect(find.byType(GamePage), findsOneWidget);

      await tester.pumpWidget(Container());
    });

    testWidgets('renders GameView', (tester) async {
      await tester.pumpApp(const GamePage(), preloadCubit: preloadCubit);
      expect(find.byType(GameView), findsOneWidget);
    });

    testWidgets('passes the control mode to GameView', (tester) async {
      await tester.pumpApp(
        const GamePage(controlMode: GameControlMode.joystick),
        preloadCubit: preloadCubit,
      );

      final view = tester.widget<GameView>(find.byType(GameView));

      expect(view.controlMode, equals(GameControlMode.joystick));
    });

    testWidgets('passes the selected player ship to GameView', (tester) async {
      final playerShip = playerShipSkinById('mars');

      await tester.pumpApp(
        GamePage(playerShip: playerShip),
        preloadCubit: preloadCubit,
      );

      final view = tester.widget<GameView>(find.byType(GameView));

      expect(view.playerShip, equals(playerShip));
    });
  });

  group('GameView', () {
    late AudioCubit audioCubit;

    setUp(() {
      audioCubit = _MockAudioCubit();
      when(() => audioCubit.state).thenReturn(AudioState());

      final deathPlayer = _MockAudioPlayer();
      when(() => audioCubit.deathPlayer).thenReturn(deathPlayer);
      when(audioCubit.startEngineLoop).thenAnswer((_) async {});
      when(audioCubit.stopEngineLoop).thenAnswer((_) async {});
    });

    testWidgets('toggles mute button correctly', (tester) async {
      final controller = StreamController<AudioState>();
      whenListen(audioCubit, controller.stream, initialState: AudioState());

      final game = TestGame();
      await tester.pumpApp(
        BlocProvider.value(
          value: audioCubit,
          child: Material(child: GameView(game: game)),
        ),
      );

      expect(find.byIcon(Icons.volume_up), findsOneWidget);

      controller.add(AudioState(volume: 0));
      await tester.pump();

      expect(find.byIcon(Icons.volume_off), findsOneWidget);

      controller.add(AudioState());
      await tester.pump();

      expect(find.byIcon(Icons.volume_up), findsOneWidget);
    });

    testWidgets('calls correct method based on state', (tester) async {
      final controller = StreamController<AudioState>();
      when(audioCubit.toggleVolume).thenAnswer((_) async {});
      whenListen(audioCubit, controller.stream, initialState: AudioState());

      final game = TestGame();
      await tester.pumpApp(
        BlocProvider.value(
          value: audioCubit,
          child: Material(child: GameView(game: game)),
        ),
      );

      await tester.tap(find.byIcon(Icons.volume_up));
      controller.add(AudioState(volume: 0));
      await tester.pump();
      verify(audioCubit.toggleVolume).called(1);

      await tester.tap(find.byIcon(Icons.volume_off));
      controller.add(AudioState());
      await tester.pump();
      verify(audioCubit.toggleVolume).called(1);
    });

    testWidgets('renders game over popup and restarts the game', (
      tester,
    ) async {
      final l10n = _MockAppLocalizations();
      when(() => l10n.distanceText(any())).thenReturn('0 km');
      when(() => l10n.bestDistanceText(any())).thenReturn('Best 0 km');
      when(() => l10n.gameOverTitle).thenReturn('GAME OVER');
      when(() => l10n.restartHint).thenReturn('Tap to restart');

      final game = _OverlayGame(
        l10n: l10n,
        deathPlayer: _MockAudioPlayer(),
        textStyle: const TextStyle(),
        images: Images(),
        storage: _MockStorageService(),
      );

      await tester.pumpApp(
        BlocProvider.value(
          value: audioCubit,
          child: Material(child: GameView(game: game)),
        ),
      );
      await tester.pump();
      await tester.pump();

      game
        ..distanceKm = 73.8
        ..isGameOver = true;
      game.overlays.add(gameOverOverlayKey);
      await tester.pump();
      await tester.pump();

      expect(find.text('GAME OVER'), findsOneWidget);
      expect(find.text('You died in the drift.'), findsOneWidget);
      expect(find.text('Distance traveled: 73 km'), findsOneWidget);
      expect(find.text('Restart'), findsOneWidget);
      expect(find.text('Title screen'), findsOneWidget);

      await tester.tap(find.text('Restart'));
      await tester.pump();

      expect(game.isGameOver, isFalse);
      expect(game.overlays.isActive(gameOverOverlayKey), isFalse);
    });

    testWidgets('returns to the title screen from game over', (tester) async {
      final l10n = _MockAppLocalizations();
      when(() => l10n.distanceText(any())).thenReturn('0 km');
      when(() => l10n.bestDistanceText(any())).thenReturn('Best 0 km');
      when(() => l10n.gameOverTitle).thenReturn('GAME OVER');
      when(() => l10n.restartHint).thenReturn('Tap to restart');

      final game = _OverlayGame(
        l10n: l10n,
        deathPlayer: _MockAudioPlayer(),
        textStyle: const TextStyle(),
        images: Images(),
        storage: _MockStorageService(),
      );

      await tester.pumpApp(
        BlocProvider.value(
          value: audioCubit,
          child: Material(child: GameView(game: game)),
        ),
      );
      await tester.pump();
      await tester.pump();

      game
        ..distanceKm = 12.4
        ..isGameOver = true;
      game.overlays.add(gameOverOverlayKey);
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('Title screen'));
      await tester.pumpAndSettle();

      expect(find.byType(TitleView), findsOneWidget);
      expect(find.byType(GameView), findsNothing);
    });

    testWidgets('renders joystick controls for joystick games', (tester) async {
      final l10n = _MockAppLocalizations();
      when(() => l10n.distanceText(any())).thenReturn('0 km');
      when(() => l10n.bestDistanceText(any())).thenReturn('Best 0 km');
      when(() => l10n.gameOverTitle).thenReturn('GAME OVER');
      when(() => l10n.restartHint).thenReturn('Tap to restart');

      final game = _OverlayGame(
        l10n: l10n,
        deathPlayer: _MockAudioPlayer(),
        textStyle: const TextStyle(),
        images: Images(),
        storage: _MockStorageService(),
        controlMode: GameControlMode.joystick,
      );

      await tester.pumpApp(
        BlocProvider.value(
          value: audioCubit,
          child: Material(child: GameView(game: game)),
        ),
      );

      expect(find.byType(GameJoystick), findsOneWidget);
      expect(
        tester.getSize(find.byType(GameJoystick)),
        equals(const Size.square(104)),
      );
      expect(
        tester.getCenter(find.byType(GameJoystick)).dx,
        equals(tester.getCenter(find.byType(GameView)).dx),
      );
      expect(
        tester.getCenter(find.byType(GameJoystick)).dy,
        greaterThan(tester.getCenter(find.byType(GameView)).dy),
      );
      expect(
        tester.getBottomLeft(find.byType(GameView)).dy -
            tester.getBottomLeft(find.byType(GameJoystick)).dy,
        equals(16),
      );
    });
  });
}
