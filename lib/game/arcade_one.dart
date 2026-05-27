import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:arcade_one/common/services/storage_service.dart';
import 'package:arcade_one/game/game.dart';
import 'package:arcade_one/game/game_image_assets.dart';
import 'package:arcade_one/gen/assets.gen.dart';
import 'package:arcade_one/l10n/l10n.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flame/cache.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/painting.dart';

const String gameOverOverlayKey = 'game_over';
const double initialDriftSpeed = 2;
const double driftSpeedGrowth = 0.0008;
const double driftVisualSpeedScale = 42;
const double obstacleSpacing = 145;
const double looseMeteorSpacing = 95;
const double initialObstacleY = -42;
const double initialLooseMeteorY = -22;
const double obstacleSequenceHandoffY = -32;
const int asteroidPairSequenceLength = 7;
const int looseMeteorBaseSequenceLength = 9;
const int looseMeteorDifficultyBonus = 5;
const int asteroidPairSequencesBeforeLooseMeteors = 3;
const int maxConsecutiveLooseMeteorSequences = 2;
const double looseMeteorSequenceChance = 0.25;
const Duration engineSoundStartDelay = Duration(milliseconds: 90);

enum ObstacleSequence {
  asteroidPairs,
  looseMeteors,
}

class ArcadeOne extends FlameGame with TapCallbacks, DragCallbacks {
  ArcadeOne({
    required this.l10n,
    required this.enginePlayer,
    required this.deathPlayer,
    required this.textStyle,
    required Images images,
    required this.storage,
    math.Random? random,
  }) : _random = random ?? math.Random() {
    this.images = images;
  }

  static const _keyBestDistance = 'best_distance_km';

  final AppLocalizations l10n;

  final AudioPlayer enginePlayer;

  final AudioPlayer deathPlayer;

  final TextStyle textStyle;

  final math.Random _random;

  final StorageService storage;

  double distanceKm = 0;
  double bestDistanceKm = 0;
  double scrollSpeed = initialDriftSpeed * driftVisualSpeedScale;
  bool isGameOver = false;

  Ship? ship;
  DriftHudComponent? hud;
  SpaceBackgroundComponent? background;
  StarfieldComponent? get starfield => background?.starfield;

  EdgeInsets _safeAreaPadding = EdgeInsets.zero;
  Timer? _engineSoundStartTimer;
  bool _isEngineSoundRequested = false;
  bool _isEngineSoundPlaying = false;

  final List<AsteroidPairComponent> obstacles = [];
  final List<LooseMeteorComponent> looseMeteors = [];

  ui.Image? _asteroidTileImage;
  ui.Image? _looseMeteorImage;
  ui.Image? _playerShipImage;
  final Map<String, ui.Image?> _spaceLandmarkImages = {};

  double _nextObstacleY = initialObstacleY;
  double _nextLooseMeteorY = initialLooseMeteorY;
  ObstacleSequence _nextObstacleSequence = ObstacleSequence.asteroidPairs;
  int _consecutiveAsteroidPairSequences = 0;
  int _consecutiveLooseMeteorSequences = 0;

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
    final saved = await storage.getDouble(_keyBestDistance);
    bestDistanceKm = saved ?? 0.0;
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
    background?.advance(scrollSpeed, dt, distanceKm);

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

    _advanceObstacleSequenceIfNeeded();
    _checkBounds();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    background?.resizeGame(size);
    hud?.reposition(size, safeAreaPadding: _safeAreaPadding);
  }

  void updateSafeAreaPadding(EdgeInsets padding) {
    if (_safeAreaPadding == padding) {
      return;
    }

    _safeAreaPadding = padding;
    hud?.reposition(playArea, safeAreaPadding: _safeAreaPadding);
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (isGameOver) {
      return;
    }

    _startEngineSound();
    ship?.setThrustTarget(event.canvasPosition);
  }

  @override
  void onTapUp(TapUpEvent event) {
    _stopEngineSound();
    ship?.clearThrust();
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    _stopEngineSound();
    ship?.clearThrust();
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (!isGameOver) {
      _startEngineSound();
      ship?.setThrustTarget(event.canvasPosition);
    }
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (!isGameOver) {
      _startEngineSound();
      ship?.setThrustTarget(event.canvasEndPosition);
    }
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    _stopEngineSound();
    ship?.clearThrust();
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
    _stopEngineSound();
    ship?.clearThrust();
  }

  void endRun() {
    if (isGameOver) {
      return;
    }

    isGameOver = true;
    if (distanceKm > bestDistanceKm) {
      bestDistanceKm = distanceKm;
      unawaited(storage.setDouble(_keyBestDistance, bestDistanceKm));
    }
    _stopEngineSound();
    unawaited(deathPlayer.play(AssetSource(Assets.audio.death)));
    if (overlays.registeredOverlays.contains(gameOverOverlayKey)) {
      overlays.add(gameOverOverlayKey);
    }
    ship?.clearThrust();
    ship?.velocity.setZero();
  }

  Future<void> restartRun() async {
    isGameOver = false;
    overlays.remove(gameOverOverlayKey);
    distanceKm = 0;
    scrollSpeed = initialDriftSpeed * driftVisualSpeedScale;
    _nextObstacleY = initialObstacleY;
    _nextLooseMeteorY = initialLooseMeteorY;
    _nextObstacleSequence = ObstacleSequence.asteroidPairs;
    _consecutiveAsteroidPairSequences = 0;
    _consecutiveLooseMeteorSequences = 0;
    ship?.reset(_shipStartPosition());
    background?.reset();

    _removeAsteroidPairs();
    _removeLooseMeteors();

    _spawnNextObstacleSequence();
  }

  @override
  void onRemove() {
    _engineSoundStartTimer?.cancel();
    super.onRemove();
  }

  Future<void> _buildRun() async {
    final area = playArea;

    await _loadGameImages();

    background = SpaceBackgroundComponent(
      gameSize: area,
      landmarkImages: _spaceLandmarkImages,
    );
    ship = Ship(
      position: _shipStartPosition(),
      shipImage: _playerShipImage,
    );
    hud = DriftHudComponent(position: Vector2(12, 12));

    await addAll([
      background!,
      ship!,
      hud!,
    ]);

    _spawnNextObstacleSequence();
    hud?.reposition(playArea, safeAreaPadding: _safeAreaPadding);
  }

  void _startEngineSound() {
    if (_isEngineSoundRequested || _isEngineSoundPlaying) {
      return;
    }

    _isEngineSoundRequested = true;
    _engineSoundStartTimer?.cancel();
    _engineSoundStartTimer = Timer(
      engineSoundStartDelay,
      _playEngineSoundIfStillRequested,
    );
  }

  void _playEngineSoundIfStillRequested() {
    if (!_isEngineSoundRequested || _isEngineSoundPlaying || isGameOver) {
      return;
    }

    unawaited(
      enginePlayer.setReleaseMode(ReleaseMode.loop).then((_) {
        if (!_isEngineSoundRequested || isGameOver) {
          return Future<void>.value();
        }
        _isEngineSoundPlaying = true;
        return enginePlayer.play(AssetSource(Assets.audio.engineFire));
      }),
    );
  }

  void _stopEngineSound() {
    if (!_isEngineSoundRequested && !_isEngineSoundPlaying) {
      return;
    }

    _engineSoundStartTimer?.cancel();
    _engineSoundStartTimer = null;
    _isEngineSoundRequested = false;
    if (!_isEngineSoundPlaying) {
      return;
    }

    _isEngineSoundPlaying = false;
    unawaited(enginePlayer.stop());
  }

  Vector2 _shipStartPosition() {
    final area = playArea;
    return Vector2(area.x / 2, area.y * 0.72);
  }

  void _advanceObstacleSequenceIfNeeded() {
    if (obstacles.isEmpty && looseMeteors.isEmpty) {
      _spawnNextObstacleSequence();
      return;
    }

    if (obstacles.isNotEmpty && looseMeteors.isNotEmpty) {
      return;
    }

    if (obstacles.isNotEmpty) {
      if (_topMostAsteroidPairY() < obstacleSequenceHandoffY) {
        return;
      }

      _spawnNextObstacleSequence(afterY: _topMostAsteroidPairY());
      return;
    }

    if (looseMeteors.isNotEmpty) {
      if (_topMostLooseMeteorY() < obstacleSequenceHandoffY) {
        return;
      }

      _spawnNextObstacleSequence(afterY: _topMostLooseMeteorY());
    }
  }

  double _topMostAsteroidPairY() {
    return obstacles.map((obstacle) => obstacle.position.y).reduce(math.min);
  }

  double _topMostLooseMeteorY() {
    return looseMeteors.map((meteor) => meteor.position.y).reduce(math.min);
  }

  void _removeAsteroidPairs() {
    for (final obstacle in obstacles.toList()) {
      obstacle.removeFromParent();
    }
    obstacles.clear();
  }

  void _removeLooseMeteors() {
    for (final meteor in looseMeteors.toList()) {
      meteor.removeFromParent();
    }
    looseMeteors.clear();
  }

  void _spawnNextObstacleSequence({double? afterY}) {
    final spawnedSequence = _nextObstacleSequence;
    switch (_nextObstacleSequence) {
      case ObstacleSequence.asteroidPairs:
        _spawnAsteroidPairSequence(afterY: afterY);
      case ObstacleSequence.looseMeteors:
        _spawnLooseMeteorSequence(afterY: afterY);
    }
    _recordSpawnedObstacleSequence(spawnedSequence);
    _nextObstacleSequence = _chooseNextObstacleSequence();
  }

  void _recordSpawnedObstacleSequence(ObstacleSequence sequence) {
    switch (sequence) {
      case ObstacleSequence.asteroidPairs:
        _consecutiveAsteroidPairSequences++;
        _consecutiveLooseMeteorSequences = 0;
      case ObstacleSequence.looseMeteors:
        _consecutiveLooseMeteorSequences++;
        _consecutiveAsteroidPairSequences = 0;
    }
  }

  ObstacleSequence _chooseNextObstacleSequence() {
    if (_consecutiveLooseMeteorSequences >=
        maxConsecutiveLooseMeteorSequences) {
      return ObstacleSequence.asteroidPairs;
    }

    final canStartLooseMeteorRun =
        _consecutiveAsteroidPairSequences >=
        asteroidPairSequencesBeforeLooseMeteors;
    final canContinueLooseMeteorRun = _consecutiveLooseMeteorSequences > 0;
    if (!canStartLooseMeteorRun && !canContinueLooseMeteorRun) {
      return ObstacleSequence.asteroidPairs;
    }

    if (_random.nextDouble() < looseMeteorSequenceChance) {
      return ObstacleSequence.looseMeteors;
    }

    return ObstacleSequence.asteroidPairs;
  }

  void _spawnAsteroidPairSequence({double? afterY}) {
    _nextObstacleY = afterY == null
        ? initialObstacleY
        : math.min(initialObstacleY, afterY - obstacleSpacing);
    for (var i = 0; i < asteroidPairSequenceLength; i++) {
      _spawnObstacle();
    }
  }

  void _spawnLooseMeteorSequence({double? afterY}) {
    _nextLooseMeteorY = afterY == null
        ? initialLooseMeteorY
        : math.min(initialLooseMeteorY, afterY - looseMeteorSpacing);
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
      asteroidTileImage: _asteroidTileImage,
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
      meteorImage: _looseMeteorImage,
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

  Future<void> _loadGameImages() async {
    _asteroidTileImage = await _loadGameImage(asteroidTileImageAsset);
    _looseMeteorImage = await _loadGameImage(looseMeteorImageAsset);
    _playerShipImage = await _loadGameImage(playerShipImageAsset);
    _spaceLandmarkImages.clear();
    for (final assetPath in spaceLandmarkAssetPaths) {
      _spaceLandmarkImages[assetPath] = await _loadGameImage(assetPath);
    }
  }

  Future<ui.Image?> _loadGameImage(String path) async {
    final cacheKey = _imageCacheKey(path);
    try {
      return images.fromCache(cacheKey);
    } on Object {
      try {
        return await images.load(cacheKey);
      } on Object {
        return null;
      }
    }
  }

  String _imageCacheKey(String path) {
    final prefix = _imagePrefix();
    if (prefix.isEmpty || !path.startsWith(prefix)) {
      return path;
    }
    return path.substring(prefix.length);
  }

  String _imagePrefix() {
    try {
      return (images as dynamic).prefix as String? ?? '';
    } on Object {
      return '';
    }
  }
}
