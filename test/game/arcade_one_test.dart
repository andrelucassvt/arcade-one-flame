// Make test files more explicit rather than collapsing calls
// ignore_for_file: cascade_invocations

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:arcade_one/common/services/storage_service.dart';
import 'package:arcade_one/game/game.dart';
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

class _MockImages extends Mock implements Images {}

class _FakeImage extends Fake implements ui.Image {}

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
    late int gameOverHapticCount;

    setUpAll(() {
      registerFallbackValue(_FakeAssetSource());
      registerFallbackValue(ReleaseMode.stop);
    });

    setUp(() {
      l10n = _MockAppLocalizations();
      when(() => l10n.distanceText(any())).thenReturn('0 km');
      when(() => l10n.bestDistanceText(any())).thenReturn('Best 0 km');
      when(() => l10n.comboText(any())).thenReturn('COMBO');
      when(() => l10n.gameOverTitle).thenReturn('GAME OVER');
      when(() => l10n.restartHint).thenReturn('Tap to restart');

      deathPlayer = _MockAudioPlayer();
      storage = _MockStorageService();
      gameOverHapticCount = 0;
      when(() => deathPlayer.play(any())).thenAnswer((_) async {});
      when(() => storage.getDouble(any())).thenAnswer((_) async => null);
      when(() => storage.setDouble(any(), any())).thenAnswer((_) async {});
    });

    ArcadeOne createGame({
      math.Random? random,
      GameControlMode controlMode = GameControlMode.touch,
      Images? images,
      PlayerShipSkin playerShip = defaultPlayerShipSkin,
      double invulnerabilityGraceSeconds = 0,
      bool waitingToStart = false,
    }) {
      final game = ArcadeOne(
        l10n: l10n,
        deathPlayer: deathPlayer,
        triggerGameOverHaptic: () async {
          gameOverHapticCount += 1;
        },
        textStyle: const TextStyle(),
        images: images ?? Images(),
        storage: storage,
        controlMode: controlMode,
        playerShip: playerShip,
        invulnerabilityGraceSeconds: invulnerabilityGraceSeconds,
        waitingToStart: waitingToStart,
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

    final selectedShipLoadedPaths = <String>[];

    testWithGame(
      'loads the selected player ship asset',
      () {
        final images = _MockImages();
        selectedShipLoadedPaths.clear();
        when(() => images.fromCache(any())).thenAnswer((invocation) {
          selectedShipLoadedPaths.add(
            invocation.positionalArguments.single as String,
          );
          return _FakeImage();
        });

        return createGame(
          images: images,
          playerShip: playerShipSkinById('mars'),
        );
      },
      (game) async {
        expect(
          selectedShipLoadedPaths,
          contains(playerShipSkinById('mars').assetPath),
        );
      },
    );

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

    testWithGame(
      'stays frozen until startRun is called',
      () => createGame(waitingToStart: true),
      (game) async {
        expect(game.isWaitingToStart, isTrue);

        game.update(1);

        expect(game.distanceKm, equals(0));

        game.startRun();
        game.update(1);

        expect(game.isWaitingToStart, isFalse);
        expect(game.distanceKm, greaterThan(0));
      },
    );

    testWithGame('updates background landmark as distance grows', createGame, (
      game,
    ) async {
      game.distanceKm = 250;

      game.update(1);

      expect(game.background!.activeLandmark.id, equals('mars'));
    });

    testWithGame('bounces off the edge without ending the run', createGame, (
      game,
    ) async {
      final ship = game.ship!;
      ship.position = Vector2(1, game.playArea.y / 2);
      ship.velocity.x = -100;

      game.update(0.1);

      expect(game.isGameOver, isFalse);
      expect(gameOverHapticCount, equals(0));
      expect(ship.position.x, closeTo(ship.collisionRadius, 1e-6));
      expect(ship.velocity.x, greaterThanOrEqualTo(0));
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

    testWithGame(
      'holds fire during the start grace period',
      () =>
          createGame(invulnerabilityGraceSeconds: startInvulnerabilitySeconds),
      (game) async {
        expect(game.isInvulnerable, isTrue);

        removeAsteroidPairs(game);
        final meteor = LooseMeteorComponent(
          gameSize: game.playArea,
          position: game.ship!.position.clone(),
          radius: 16,
        );
        game.looseMeteors.add(meteor);
        await game.add(meteor);

        game.update(1 / 30);

        expect(game.isGameOver, isFalse);

        for (var i = 0; i < 60 && game.isInvulnerable; i++) {
          meteor.position = game.ship!.position.clone();
          game.update(1 / 30);
        }

        expect(game.isInvulnerable, isFalse);
        expect(game.isGameOver, isTrue);
      },
    );

    testWithGame('shield absorbs a hit before ending the run', createGame, (
      game,
    ) async {
      removeActiveSequences(game);

      final powerUp = PowerUpComponent(
        gameSize: game.playArea,
        position: game.ship!.position.clone(),
        type: PowerUpType.shield,
      );
      game.powerUps.add(powerUp);
      await game.add(powerUp);

      game.update(1 / 30);

      expect(game.ship!.hasShield, isTrue);
      expect(game.powerUps, isEmpty);

      final meteor = LooseMeteorComponent(
        gameSize: game.playArea,
        position: game.ship!.position.clone(),
        radius: 16,
      );
      game.looseMeteors.add(meteor);
      await game.add(meteor);

      game.update(1 / 30);

      expect(game.isGameOver, isFalse);
      expect(game.ship!.hasShield, isFalse);
      expect(game.looseMeteors, isNot(contains(meteor)));
    });

    testWithGame('slow motion power-up scales the run speed', createGame, (
      game,
    ) async {
      removeActiveSequences(game);

      final powerUp = PowerUpComponent(
        gameSize: game.playArea,
        position: game.ship!.position.clone(),
        type: PowerUpType.slowMotion,
      );
      game.powerUps.add(powerUp);
      await game.add(powerUp);

      game.update(1 / 30);

      expect(game.isSlowMotionActive, isTrue);
      expect(game.timeScale, equals(slowMotionTimeScale));

      for (var i = 0; i < 130; i++) {
        game.update(1 / 30);
      }

      expect(game.isSlowMotionActive, isFalse);
      expect(game.timeScale, equals(1));
    });

    testWithGame('near miss builds a combo', createGame, (game) async {
      removeActiveSequences(game);

      final ship = game.ship!;
      final meteor = LooseMeteorComponent(
        gameSize: game.playArea,
        position: Vector2(
          ship.position.x,
          ship.position.y - (ship.collisionRadius + looseMeteorMinRadius + 6),
        ),
        radius: looseMeteorMinRadius,
      );
      game.looseMeteors.add(meteor);
      await game.add(meteor);

      game.update(1 / 30);

      expect(game.combo, equals(1));
      expect(game.comboMultiplier, greaterThan(1));
    });

    testWithGame('tracks the maximum combo of the run', createGame, (
      game,
    ) async {
      removeActiveSequences(game);

      final ship = game.ship!;
      for (var i = 0; i < 2; i++) {
        final meteor = LooseMeteorComponent(
          gameSize: game.playArea,
          position: Vector2(
            ship.position.x,
            ship.position.y - (ship.collisionRadius + looseMeteorMinRadius + 6),
          ),
          radius: looseMeteorMinRadius,
        );
        game.looseMeteors.add(meteor);
        await game.add(meteor);
        game.update(1 / 30);
      }

      expect(game.combo, equals(2));
      expect(game.maxCombo, equals(2));
    });

    testWithGame('clamps huge frame deltas', createGame, (game) async {
      game.update(1);

      expect(
        game.distanceKm,
        closeTo(initialDriftSpeed * maxGameUpdateDt, 1e-9),
      );
      expect(
        game.scrollSpeed,
        equals(game.driftSpeed * driftVisualSpeedScale),
      );
    });

    testWithGame('pauses the engine after the death hit-stop', createGame, (
      game,
    ) async {
      game.endRun();

      expect(game.paused, isFalse);

      for (var i = 0; i < 30; i++) {
        game.update(1 / 30);
      }

      expect(game.paused, isTrue);
    });

    testWithGame(
      'uses joystick direction in joystick control mode',
      () => createGame(controlMode: GameControlMode.joystick),
      (game) async {
        expect(game.ship!.thrustPower, equals(joystickShipThrustPower));
        expect(game.ship!.maxSpeed, equals(joystickShipMaxSpeed));
        expect(game.ship!.maxSpeed, lessThan(defaultShipMaxSpeed));

        game.onTapDown(tapDown(game));

        expect(game.ship!.isThrusting, isFalse);

        game.setJoystickDirection(Vector2(1, 0));

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

        expect(game.ship!.isThrusting, isFalse);
      },
    );

    testWithGame('endRun triggers haptic and death sound', createGame, (
      game,
    ) async {
      game.endRun();

      expect(gameOverHapticCount, equals(1));
      verify(() => deathPlayer.play(any())).called(1);
      game.endRun();
      expect(gameOverHapticCount, equals(1));
      verifyNever(() => deathPlayer.play(any()));
    });

    testWithGame('restart resets run and keeps best distance', createGame, (
      game,
    ) async {
      game.distanceKm = 120;
      game.maxCombo = 3;
      game.endRun();
      final previousObstacle = game.obstacles.first;

      await game.restartRun();

      expect(game.isGameOver, isFalse);
      expect(game.distanceKm, equals(0));
      expect(game.maxCombo, equals(0));
      expect(game.isNewRecord, isFalse);
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
      'endRun marca isNewRecord quando a distância supera o recorde',
      createGame,
      (game) async {
        game.distanceKm = 10;
        game.endRun();

        expect(game.isNewRecord, isTrue);
      },
    );

    testWithGame(
      'endRun mantém isNewRecord falso quando não supera o recorde',
      createGame,
      (game) async {
        game.bestDistanceKm = 20;
        game.distanceKm = 5;
        game.endRun();

        expect(game.isNewRecord, isFalse);
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
