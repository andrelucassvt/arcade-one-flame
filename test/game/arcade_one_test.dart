// Make test files more explicit rather than collapsing calls
// ignore_for_file: cascade_invocations

import 'dart:math' as math;

import 'package:arcade_one/common/services/storage_service.dart';
import 'package:arcade_one/game/game.dart';
import 'package:arcade_one/gen/assets.gen.dart';
import 'package:arcade_one/l10n/l10n.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flame/cache.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _FakeAssetSource extends Fake implements AssetSource {}

class _MockAppLocalizations extends Mock implements AppLocalizations {}

class _MockAudioPlayer extends Mock implements AudioPlayer {}

class _MockStorageService extends Mock implements StorageService {}

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
    late AudioPlayer deathPlayer;
    late StorageService storage;
    late int thrustTapSoundCount;
    late int startEngineLoopCount;
    late int stopEngineLoopCount;

    setUpAll(() {
      registerFallbackValue(_FakeAssetSource());
      registerFallbackValue(ReleaseMode.stop);
    });

    setUp(() {
      l10n = _MockAppLocalizations();
      when(() => l10n.distanceText(any())).thenReturn('0 km');
      when(() => l10n.bestDistanceText(any())).thenReturn('Best 0 km');
      when(() => l10n.gameOverTitle).thenReturn('GAME OVER');
      when(() => l10n.restartHint).thenReturn('Tap to restart');

      deathPlayer = _MockAudioPlayer();
      storage = _MockStorageService();
      thrustTapSoundCount = 0;
      startEngineLoopCount = 0;
      stopEngineLoopCount = 0;
      when(() => deathPlayer.play(any())).thenAnswer((_) async {});
      when(() => storage.getDouble(any())).thenAnswer((_) async => null);
      when(() => storage.setDouble(any(), any())).thenAnswer((_) async {});
    });

    ArcadeOne createGame({
      math.Random? random,
      GameControlMode controlMode = GameControlMode.touch,
    }) {
      final game = ArcadeOne(
        l10n: l10n,
        deathPlayer: deathPlayer,
        playThrustTapSound: () async {
          thrustTapSoundCount += 1;
        },
        startEngineLoop: () async {
          startEngineLoopCount += 1;
        },
        stopEngineLoop: () async {
          stopEngineLoopCount += 1;
        },
        textStyle: const TextStyle(),
        images: Images(),
        storage: storage,
        controlMode: controlMode,
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

    TapDownEvent tapDown(ArcadeOne game) {
      return TapDownEvent(
        1,
        game,
        TapDownDetails(globalPosition: const Offset(120, 160)),
      );
    }

    TapUpEvent tapUp(ArcadeOne game) {
      return TapUpEvent(
        1,
        game,
        TapUpDetails(
          globalPosition: const Offset(120, 160),
          kind: PointerDeviceKind.touch,
        ),
      );
    }

    DragUpdateEvent dragUpdate(ArcadeOne game) {
      return DragUpdateEvent(
        1,
        game,
        DragUpdateDetails(
          globalPosition: const Offset(120, 160),
          delta: const Offset(8, 4),
        ),
      );
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
      verify(
        () => deathPlayer.play(
          any(
            that: isA<AssetSource>().having(
              (source) => source.path,
              'path',
              Assets.audio.death,
            ),
          ),
        ),
      ).called(1);
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
      verify(() => deathPlayer.play(any())).called(1);
    });

    testWithGame('plays engine fire sound while thrusting', createGame, (
      game,
    ) async {
      game.onTapDown(tapDown(game));
      await Future<void>.delayed(engineSoundStartDelay);
      await Future<void>.delayed(Duration.zero);

      game.onDragUpdate(dragUpdate(game));
      await Future<void>.delayed(Duration.zero);

      expect(startEngineLoopCount, equals(1));
    });

    testWithGame('does not play engine fire sound for quick taps', createGame, (
      game,
    ) async {
      game.onTapDown(tapDown(game));
      game.onTapUp(tapUp(game));
      await Future<void>.delayed(engineSoundStartDelay);
      await Future<void>.delayed(Duration.zero);

      expect(thrustTapSoundCount, equals(1));
      expect(startEngineLoopCount, equals(0));
      expect(stopEngineLoopCount, equals(0));
    });

    testWithGame('stops engine fire sound when thrust ends', createGame, (
      game,
    ) async {
      game.onTapDown(tapDown(game));
      await Future<void>.delayed(engineSoundStartDelay);
      await Future<void>.delayed(Duration.zero);

      game.onTapUp(tapUp(game));

      expect(stopEngineLoopCount, equals(1));
    });

    testWithGame(
      'uses joystick direction in joystick control mode',
      () => createGame(controlMode: GameControlMode.joystick),
      (game) async {
        expect(game.ship!.thrustPower, equals(joystickShipThrustPower));
        expect(game.ship!.maxSpeed, equals(joystickShipMaxSpeed));
        expect(game.ship!.maxSpeed, lessThan(defaultShipMaxSpeed));

        game.onTapDown(tapDown(game));

        expect(thrustTapSoundCount, equals(0));
        expect(game.ship!.isThrusting, isFalse);

        game.setJoystickDirection(Vector2(1, 0));

        expect(thrustTapSoundCount, equals(1));
        expect(game.ship!.isThrusting, isTrue);

        game.clearJoystick();

        expect(game.ship!.isThrusting, isFalse);
      },
    );

    testWithGame(
      'ignores joystick direction in touch control mode',
      createGame,
      (
        game,
      ) async {
        game.setJoystickDirection(Vector2(1, 0));

        expect(thrustTapSoundCount, equals(0));
        expect(game.ship!.isThrusting, isFalse);
      },
    );

    testWithGame('stops engine fire sound when the run ends', createGame, (
      game,
    ) async {
      game.onTapDown(tapDown(game));
      await Future<void>.delayed(engineSoundStartDelay);
      await Future<void>.delayed(Duration.zero);

      game.endRun();

      expect(stopEngineLoopCount, equals(1));
      verify(() => deathPlayer.play(any())).called(1);
      game.endRun();
      verifyNever(() => deathPlayer.play(any()));
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
      expect(game.overlays.isActive(gameOverOverlayKey), isFalse);
    });

    // ── Testes de persistência ────────────────────────────────────────────

    testWithGame(
      'carrega bestDistanceKm do storage no onLoad',
      () {
        when(
          () => storage.getDouble('best_distance_km'),
        ).thenAnswer((_) async => 3.5);
        return createGame();
      },
      (game) async {
        expect(game.bestDistanceKm, closeTo(3.5, 0.001));
      },
    );

    testWithGame(
      'bestDistanceKm é 0.0 quando storage retorna null',
      createGame,
      (game) async {
        expect(game.bestDistanceKm, equals(0.0));
      },
    );

    testWithGame(
      'endRun salva bestDistanceKm no storage quando distância é maior',
      createGame,
      (game) async {
        game.distanceKm = 10;
        game.endRun();

        verify(() => storage.setDouble('best_distance_km', 10)).called(1);
      },
    );

    testWithGame(
      'endRun não sobrescreve storage quando distância não supera recorde',
      createGame,
      (game) async {
        // Simula recorde já salvo carregado
        game.bestDistanceKm = 20;
        game.distanceKm = 5;
        game.endRun();

        verifyNever(() => storage.setDouble('best_distance_km', any()));
      },
    );
  });
}
