// Make test files more explicit rather than collapsing calls
// ignore_for_file: cascade_invocations

import 'dart:math' as math;

import 'package:arcade_one/game/game.dart';
import 'package:arcade_one/l10n/l10n.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flame/cache.dart';
import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _FakeAssetSource extends Fake implements AssetSource {}

class _MockAppLocalizations extends Mock implements AppLocalizations {}

class _MockAudioPlayer extends Mock implements AudioPlayer {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ArcadeOne', () {
    late AppLocalizations l10n;
    late AudioPlayer audioPlayer;

    setUpAll(() {
      registerFallbackValue(_FakeAssetSource());
    });

    setUp(() {
      l10n = _MockAppLocalizations();
      when(() => l10n.distanceText(any())).thenReturn('0 km');
      when(() => l10n.bestDistanceText(any())).thenReturn('Best 0 km');
      when(() => l10n.gameOverTitle).thenReturn('GAME OVER');
      when(() => l10n.restartHint).thenReturn('Tap to restart');

      audioPlayer = _MockAudioPlayer();
      when(() => audioPlayer.play(any())).thenAnswer((_) async {});
    });

    ArcadeOne createGame() {
      final game = ArcadeOne(
        l10n: l10n,
        effectPlayer: audioPlayer,
        textStyle: const TextStyle(),
        images: Images(),
        random: math.Random(1),
      );
      game.onGameResize(Vector2(390, 700));
      return game;
    }

    testWithGame('loads DRIFT components', createGame, (game) async {
      expect(game.ship, isNotNull);
      expect(game.hud, isNotNull);
      expect(game.starfield, isNotNull);
      expect(game.obstacles, isNotEmpty);
    });

    testWithGame('increases distance and scroll speed over time', createGame, (
      game,
    ) async {
      final initialScrollSpeed = game.scrollSpeed;

      game.update(1);

      expect(game.distanceKm, greaterThan(0));
      expect(game.scrollSpeed, greaterThanOrEqualTo(initialScrollSpeed));
    });

    testWithGame('ends run when ship touches the edge', createGame, (
      game,
    ) async {
      game.ship!.position = Vector2(1, game.playArea.y / 2);

      game.update(0.1);

      expect(game.isGameOver, isTrue);
      verify(() => audioPlayer.play(any())).called(1);
    });

    testWithGame('restart resets run and keeps best distance', createGame, (
      game,
    ) async {
      game.distanceKm = 120;
      game.endRun();

      await game.restartRun();

      expect(game.isGameOver, isFalse);
      expect(game.distanceKm, equals(0));
      expect(game.bestDistanceKm, equals(120));
      expect(
        game.ship!.position,
        equals(Vector2(game.playArea.x / 2, game.playArea.y * 0.72)),
      );
      expect(game.obstacles, isNotEmpty);
    });
  });
}
