import 'dart:async';
import 'dart:math' as math;

import 'package:arcade_one/game/game.dart';
import 'package:arcade_one/gen/assets.gen.dart';
import 'package:arcade_one/l10n/l10n.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flame/cache.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/painting.dart';

const double initialDriftSpeed = 2;
const double driftSpeedGrowth = 0.0008;
const double driftVisualSpeedScale = 42;
const double obstacleSpacing = 190;
const double looseMeteorSpacing = 150;
const int asteroidPairSequenceLength = 4;
const int looseMeteorBaseSequenceLength = 4;
const int looseMeteorDifficultyBonus = 2;

enum ObstacleSequence {
  asteroidPairs,
  looseMeteors,
}

class ArcadeOne extends FlameGame with TapCallbacks, DragCallbacks {
  ArcadeOne({
    required this.l10n,
    required this.effectPlayer,
    required this.textStyle,
    required Images images,
    math.Random? random,
  }) : _random = random ?? math.Random() {
    this.images = images;
  }

  final AppLocalizations l10n;

  final AudioPlayer effectPlayer;

  final TextStyle textStyle;

  final math.Random _random;

  double distanceKm = 0;
  double bestDistanceKm = 0;
  double scrollSpeed = initialDriftSpeed * driftVisualSpeedScale;
  bool isGameOver = false;

  Ship? ship;
  DriftHudComponent? hud;
  StarfieldComponent? starfield;

  final List<AsteroidPairComponent> obstacles = [];
  final List<LooseMeteorComponent> looseMeteors = [];

  double _nextObstacleY = -obstacleSpacing;
  double _nextLooseMeteorY = -obstacleSpacing * 0.75;
  ObstacleSequence _nextObstacleSequence = ObstacleSequence.asteroidPairs;
  bool _forceMeteorSequenceAfterFirstWalls = true;

  double get driftSpeed => initialDriftSpeed + distanceKm * driftSpeedGrowth;

  double get difficulty => (distanceKm / 3000).clamp(0, 1);

  Vector2 get playArea {
    if (size.x <= 0 || size.y <= 0) {
      return Vector2(390, 700);
    }
    return size;
  }

  @override
  Color backgroundColor() => const Color(0xFF080A19);

  @override
  Future<void> onLoad() async {
    await _buildRun();
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (isGameOver) {
      return;
    }

    distanceKm += driftSpeed * dt;
    scrollSpeed = driftSpeed * driftVisualSpeedScale;
    starfield?.advance(scrollSpeed, dt);

    for (final obstacle in obstacles.toList()) {
      obstacle.moveByScroll(scrollSpeed, dt);
      if (ship != null && obstacle.collidesWith(ship!)) {
        endRun();
        return;
      }
      if (obstacle.isOffscreen) {
        obstacles.remove(obstacle);
        obstacle.removeFromParent();
      }
    }

    for (final meteor in looseMeteors.toList()) {
      meteor.moveByScroll(scrollSpeed, dt);
      if (ship != null && meteor.collidesWith(ship!)) {
        endRun();
        return;
      }
      if (meteor.isOffscreen) {
        looseMeteors.remove(meteor);
        meteor.removeFromParent();
      }
    }

    _spawnNextObstacleSequenceIfNeeded();
    _checkBounds();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    hud?.reposition(size);
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (isGameOver) {
      unawaited(restartRun());
      return;
    }

    ship?.setThrustTarget(event.canvasPosition);
  }

  @override
  void onTapUp(TapUpEvent event) {
    ship?.clearThrust();
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    ship?.clearThrust();
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (!isGameOver) {
      ship?.setThrustTarget(event.canvasPosition);
    }
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (!isGameOver) {
      ship?.setThrustTarget(event.canvasEndPosition);
    }
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    ship?.clearThrust();
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
    ship?.clearThrust();
  }

  void endRun() {
    if (isGameOver) {
      return;
    }

    isGameOver = true;
    bestDistanceKm = math.max(bestDistanceKm, distanceKm);
    unawaited(effectPlayer.play(AssetSource(Assets.audio.effect)));
    ship?.clearThrust();
    ship?.velocity.setZero();
  }

  Future<void> restartRun() async {
    isGameOver = false;
    distanceKm = 0;
    scrollSpeed = initialDriftSpeed * driftVisualSpeedScale;
    _nextObstacleY = -obstacleSpacing;
    _nextLooseMeteorY = -obstacleSpacing * 0.75;
    _nextObstacleSequence = ObstacleSequence.asteroidPairs;
    _forceMeteorSequenceAfterFirstWalls = true;
    ship?.reset(_shipStartPosition());

    for (final obstacle in obstacles.toList()) {
      obstacle.removeFromParent();
    }
    obstacles.clear();

    for (final meteor in looseMeteors.toList()) {
      meteor.removeFromParent();
    }
    looseMeteors.clear();

    _spawnNextObstacleSequence();
  }

  Future<void> _buildRun() async {
    final area = playArea;

    starfield = StarfieldComponent(gameSize: area);
    ship = Ship(position: _shipStartPosition());
    hud = DriftHudComponent(position: Vector2(12, 12));

    await addAll([
      starfield!,
      ship!,
      hud!,
    ]);

    _spawnNextObstacleSequence();
  }

  Vector2 _shipStartPosition() {
    final area = playArea;
    return Vector2(area.x / 2, area.y * 0.72);
  }

  void _spawnNextObstacleSequenceIfNeeded() {
    if (obstacles.isNotEmpty || looseMeteors.isNotEmpty) {
      return;
    }

    _spawnNextObstacleSequence();
  }

  void _spawnNextObstacleSequence() {
    switch (_nextObstacleSequence) {
      case ObstacleSequence.asteroidPairs:
        _spawnAsteroidPairSequence();
      case ObstacleSequence.looseMeteors:
        _spawnLooseMeteorSequence();
    }
    _nextObstacleSequence = _chooseNextObstacleSequence();
  }

  ObstacleSequence _chooseNextObstacleSequence() {
    if (_forceMeteorSequenceAfterFirstWalls) {
      _forceMeteorSequenceAfterFirstWalls = false;
      return ObstacleSequence.looseMeteors;
    }

    return _random.nextBool()
        ? ObstacleSequence.asteroidPairs
        : ObstacleSequence.looseMeteors;
  }

  void _spawnAsteroidPairSequence() {
    _nextObstacleY = -obstacleSpacing;
    for (var i = 0; i < asteroidPairSequenceLength; i++) {
      _spawnObstacle();
    }
  }

  void _spawnLooseMeteorSequence() {
    _nextLooseMeteorY = -obstacleSpacing * 0.75;
    final sequenceLength =
        looseMeteorBaseSequenceLength +
        (difficulty * looseMeteorDifficultyBonus).round();
    for (var i = 0; i < sequenceLength; i++) {
      _spawnLooseMeteor();
    }
  }

  void _spawnObstacle() {
    final area = playArea;
    final margin = math.min(area.x / 2, asteroidBaseGap / 2 + 24);
    final span = math.max(0, area.x - margin * 2);
    final gapCenter = margin + _random.nextDouble() * span;
    final obstacle = AsteroidPairComponent(
      gameSize: area,
      y: _nextObstacleY,
      difficulty: difficulty,
      gapCenterX: gapCenter,
    );
    obstacles.add(obstacle);
    final addFuture = add(obstacle);
    if (addFuture is Future<void>) {
      unawaited(addFuture);
    }
    _nextObstacleY -= obstacleSpacing;
  }

  void _spawnLooseMeteor() {
    final area = playArea;
    final margin = math.min(
      area.x / 2,
      looseMeteorSpawnMargin,
    );
    final span = math.max(0, area.x - margin * 2);
    final radiusRange =
        (looseMeteorMaxRadius - looseMeteorMinRadius) *
        (0.65 + difficulty * 0.35);
    final radius = looseMeteorMinRadius + _random.nextDouble() * radiusRange;
    final meteor = LooseMeteorComponent(
      gameSize: area,
      position: Vector2(
        margin + _random.nextDouble() * span,
        _nextLooseMeteorY,
      ),
      radius: radius,
      horizontalDrift: (_random.nextDouble() * 2 - 1) * (14 + difficulty * 22),
    );
    looseMeteors.add(meteor);
    final addFuture = add(meteor);
    if (addFuture is Future<void>) {
      unawaited(addFuture);
    }
    _nextLooseMeteorY -= looseMeteorSpacing;
  }

  void _checkBounds() {
    final currentShip = ship;
    if (currentShip == null) {
      return;
    }

    final radius = currentShip.collisionRadius;
    if (currentShip.position.x - radius <= 0 ||
        currentShip.position.x + radius >= playArea.x ||
        currentShip.position.y - radius <= 0 ||
        currentShip.position.y + radius >= playArea.y) {
      endRun();
    }
  }
}
