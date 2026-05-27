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

class _FixedDoubleRandom implements math.Random {
  const _FixedDoubleRandom(this.value);

  final double value;

  @override
  bool nextBool() => value < 0.5;

  @override
  double nextDouble() => value;

  @override
  int nextInt(int max) => (value * max).floor().clamp(0, max - 1);
}

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

    ArcadeOne createGame({math.Random? random}) {
      final game = ArcadeOne(
        l10n: l10n,
        effectPlayer: audioPlayer,
        textStyle: const TextStyle(),
        images: Images(),
        random: random ?? math.Random(1),
      );
      game.onGameResize(Vector2(390, 700));
      return game;
    }

    void removeAsteroidPairs(ArcadeOne game) {
      for (final obstacle in game.obstacles.toList()) {
        obstacle.removeFromParent();
      }
      game.obstacles.clear();
    }

    void removeLooseMeteors(ArcadeOne game) {
      for (final meteor in game.looseMeteors.toList()) {
        meteor.removeFromParent();
      }
      game.looseMeteors.clear();
    }

    void removeActiveSequences(ArcadeOne game) {
      removeAsteroidPairs(game);
      removeLooseMeteors(game);
    }

    testWithGame('loads DRIFT components', createGame, (game) async {
      expect(game.ship, isNotNull);
      expect(game.hud, isNotNull);
      expect(game.background, isNotNull);
      expect(game.starfield, isNotNull);
      expect(game.background!.activeLandmark.id, equals('earth_moon'));
      expect(game.obstacles, hasLength(asteroidPairSequenceLength));
      expect(game.obstacles.first.position.y, greaterThan(-100));
      expect(game.looseMeteors, isEmpty);
    });

    testWithGame(
      'delays meteor sequences until after enough wall sequences',
      () => createGame(random: const _FixedDoubleRandom(0)),
      (game) async {
        removeActiveSequences(game);
        game.update(0.1);

        expect(game.obstacles, hasLength(asteroidPairSequenceLength));
        expect(game.looseMeteors, isEmpty);

        removeActiveSequences(game);
        game.update(0.1);

        expect(game.obstacles, hasLength(asteroidPairSequenceLength));
        expect(game.looseMeteors, isEmpty);

        removeActiveSequences(game);
        game.update(0.1);

        expect(game.obstacles, isEmpty);
        expect(game.looseMeteors, hasLength(looseMeteorBaseSequenceLength));
        expect(game.looseMeteors.first.position.y, greaterThan(-50));
      },
    );

    testWithGame(
      'favors walls when meteor sequences are eligible',
      () => createGame(random: const _FixedDoubleRandom(0.99)),
      (game) async {
        removeActiveSequences(game);
        game.update(0.1);
        removeActiveSequences(game);
        game.update(0.1);
        removeActiveSequences(game);
        game.update(0.1);

        expect(game.obstacles, hasLength(asteroidPairSequenceLength));
        expect(game.looseMeteors, isEmpty);
      },
    );

    testWithGame(
      'limits meteor runs to two consecutive sequences',
      () => createGame(random: const _FixedDoubleRandom(0)),
      (game) async {
        removeActiveSequences(game);
        game.update(0.1);
        removeActiveSequences(game);
        game.update(0.1);
        removeActiveSequences(game);
        game.update(0.1);

        expect(game.looseMeteors, hasLength(looseMeteorBaseSequenceLength));

        removeActiveSequences(game);
        game.update(0.1);

        expect(game.looseMeteors, hasLength(looseMeteorBaseSequenceLength));

        removeActiveSequences(game);
        game.update(0.1);

        expect(game.obstacles, hasLength(asteroidPairSequenceLength));
        expect(game.looseMeteors, isEmpty);
      },
    );

    testWithGame(
      'starts the next wall sequence before the current one leaves the screen',
      createGame,
      (game) async {
        for (var i = 0; i < game.obstacles.length; i++) {
          game.obstacles[i].position.y = obstacleSequenceHandoffY + i;
        }
        final previousTopMostWallY = game.obstacles
            .map((obstacle) => obstacle.position.y)
            .reduce(math.min);

        game.update(0.1);

        expect(game.obstacles, isNotEmpty);
        expect(game.looseMeteors, isEmpty);
        final newTopMostWallY = game.obstacles
            .map((obstacle) => obstacle.position.y)
            .reduce(math.min);
        expect(
          newTopMostWallY,
          lessThan(previousTopMostWallY - obstacleSpacing * 0.8),
        );
      },
    );

    testWithGame(
      'keeps existing obstacles visible during sequence handoff',
      createGame,
      (game) async {
        expect(game.obstacles, isNotEmpty);
        expect(game.looseMeteors, isEmpty);

        final previousObstacle = game.obstacles.first;
        for (var i = 0; i < game.obstacles.length; i++) {
          game.obstacles[i].position.y = obstacleSequenceHandoffY + i;
        }

        game.update(0.1);

        expect(game.obstacles, contains(previousObstacle));
        expect(game.obstacles, hasLength(asteroidPairSequenceLength * 2));
        expect(game.looseMeteors, isEmpty);
      },
    );

    testWithGame('increases distance and scroll speed over time', createGame, (
      game,
    ) async {
      final initialScrollSpeed = game.scrollSpeed;

      game.update(1);

      expect(game.distanceKm, greaterThan(0));
      expect(game.scrollSpeed, greaterThanOrEqualTo(initialScrollSpeed));
    });

    testWithGame('updates background landmark as distance grows', createGame, (
      game,
    ) async {
      game.distanceKm = 249;

      game.update(1);

      expect(game.background!.activeLandmark.id, equals('mars'));
    });

    testWithGame('ends run when ship touches the edge', createGame, (
      game,
    ) async {
      game.ship!.position = Vector2(1, game.playArea.y / 2);

      game.update(0.1);

      expect(game.isGameOver, isTrue);
      verify(() => audioPlayer.play(any())).called(1);
    });

    testWithGame('ends run when ship hits a loose meteor', createGame, (
      game,
    ) async {
      removeAsteroidPairs(game);
      removeLooseMeteors(game);

      final meteor = LooseMeteorComponent(
        gameSize: game.playArea,
        position: game.ship!.position.clone(),
        radius: 16,
      );
      game.looseMeteors.add(meteor);
      await game.add(meteor);

      game.update(0.1);

      expect(game.isGameOver, isTrue);
      verify(() => audioPlayer.play(any())).called(1);
    });

    testWithGame('restart resets run and keeps best distance', createGame, (
      game,
    ) async {
      game.distanceKm = 120;
      game.endRun();
      final previousObstacle = game.obstacles.first;

      await game.restartRun();

      expect(game.isGameOver, isFalse);
      expect(game.distanceKm, equals(0));
      expect(game.bestDistanceKm, equals(120));
      expect(game.background!.activeLandmark.id, equals('earth_moon'));
      expect(
        game.ship!.position,
        equals(Vector2(game.playArea.x / 2, game.playArea.y * 0.72)),
      );
      expect(game.obstacles, isNotEmpty);
      expect(game.looseMeteors, isEmpty);
      expect(game.obstacles, isNot(contains(previousObstacle)));
    });
  });
}
