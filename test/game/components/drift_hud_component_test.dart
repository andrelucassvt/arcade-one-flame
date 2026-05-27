// Make test files more explicit rather than collapsing calls
// ignore_for_file: cascade_invocations

import 'package:arcade_one/game/game.dart';
import 'package:arcade_one/l10n/l10n.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flame/cache.dart';
import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAppLocalizations extends Mock implements AppLocalizations {}

class _MockAudioPlayer extends Mock implements AudioPlayer {}

class _ArcadeOne extends ArcadeOne {
  _ArcadeOne({
    required super.l10n,
    required super.enginePlayer,
    required super.deathPlayer,
    required super.textStyle,
    required super.images,
  });

  @override
  Future<void> onLoad() async {}
}

void main() {
  group('DriftHudComponent', () {
    late AppLocalizations l10n;

    setUp(() {
      l10n = _MockAppLocalizations();
      when(() => l10n.distanceText(any())).thenAnswer(
        (invocation) => '${invocation.positionalArguments.first} km',
      );
      when(() => l10n.bestDistanceText(any())).thenAnswer(
        (invocation) => 'Best ${invocation.positionalArguments.first} km',
      );
      when(() => l10n.gameOverTitle).thenReturn('GAME OVER');
      when(() => l10n.restartHint).thenReturn('Tap to restart');
    });

    ArcadeOne createGame() {
      final game = _ArcadeOne(
        l10n: l10n,
        enginePlayer: _MockAudioPlayer(),
        deathPlayer: _MockAudioPlayer(),
        textStyle: const TextStyle(),
        images: Images(),
      );
      game.onGameResize(Vector2(390, 700));
      return game;
    }

    testWithGame('shows distance and best distance', createGame, (game) async {
      final hud = DriftHudComponent(position: Vector2.zero());
      await game.ensureAdd(hud);

      game.distanceKm = 42;
      game.bestDistanceKm = 128;
      game.update(0.1);

      expect(hud.distanceText.text, equals('42 km'));
      expect(hud.bestText.text, equals('Best 128 km'));
    });

    testWithGame('keeps game over messaging out of the Flame HUD', createGame, (
      game,
    ) async {
      final hud = DriftHudComponent(position: Vector2.zero());
      await game.ensureAdd(hud);

      game.isGameOver = true;
      game.update(0.1);

      expect(hud.distanceText.text, equals('0 km'));
      expect(hud.bestText.text, equals('Best 0 km'));
    });
  });
}
