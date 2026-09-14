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
import 'package:flutter/services.dart';

typedef TriggerGameOverHaptic = Future<void> Function();

const String gameOverOverlayKey = 'game_over';
const String bestDistanceStorageKey = 'best_distance_km';
const double initialDriftSpeed = 2;
const double driftSpeedGrowth = 0.0008;
const double driftVisualSpeedScale = 42;
const double joystickShipThrustPower = 360;
const double joystickShipMaxSpeed = 170;
const double obstacleSpacing = 145;
const double looseMeteorSpacing = 95;
const double initialObstacleY = -42;
const double initialLooseMeteorY = -22;
const double obstacleSequenceHandoffY = -32;
const int asteroidPairSequenceLength = 7;
const int looseMeteorBaseSequenceLength = 9;
const int looseMeteorDifficultyBonus = 5;
const int looseMeteorDeepDifficultyBonus = 3;
const int asteroidPairSequencesBeforeLooseMeteors = 3;
const int maxConsecutiveLooseMeteorSequences = 2;
const double looseMeteorSequenceChance = 0.25;
const double maxGameUpdateDt = 1 / 30;
const double startInvulnerabilitySeconds = 1.6;
const double shieldInvulnerabilitySeconds = 1.2;
const double nearMissThreshold = 18;
const double nearMissShakeIntensity = 4;
const double bounceShakeIntensity = 2;
const double shieldShakeIntensity = 6;
const double deathShakeIntensity = 11;
const double shakeDecayPerSecond = 42;
const double comboDurationSeconds = 2.5;
const double comboMultiplierStep = 0.1;
const double maxComboMultiplier = 2.5;
const double slowMotionDurationSeconds = 4;
const double slowMotionTimeScale = 0.55;
const double deathSlowMotionTimeScale = 0.22;
const double deathSlowMotionRecovery = 2.4;
const double deathOverlayDelaySeconds = 0.55;
const double deepSpaceStartKm = 3000;
const double deepSpaceRangeKm = 6000;
const double deepSpaceSpeedBonus = 1.2;
const double movingGapBaseChance = 0.12;
const double movingGapDifficultyChance = 0.33;
const double movingGapDeepChance = 0.2;
const double movingGapMaxChance = 0.7;
const double movingGapBaseAmplitude = 18;
const double movingGapDifficultyAmplitude = 34;
const double movingGapRandomAmplitude = 26;
const double movingGapBaseSpeed = 0.9;
const double movingGapSpeedRange = 1.1;
const double powerUpSpawnChance = 0.16;
const double powerUpHorizontalDrift = 12;
const double bounceRestitution = 0.5;
const Color deathBurstColor = Color(0xFFFFB000);
const Color shieldBurstColor = Color(0xFF57E4FF);
const Color slowMotionTintColor = Color(0x2257E4FF);

enum ObstacleSequence {
  asteroidPairs,
  looseMeteors,
}

class ArcadeOne extends FlameGame with TapCallbacks, DragCallbacks {
  ArcadeOne({
    required this.l10n,
    required this.deathPlayer,
    required this.textStyle,
    required Images images,
    required this.storage,
    this.controlMode = GameControlMode.touch,
    this.playerShip = defaultPlayerShipSkin,
    this.invulnerabilityGraceSeconds = startInvulnerabilitySeconds,
    this.waitingToStart = false,
    math.Random? random,
    TriggerGameOverHaptic? triggerGameOverHaptic,
  }) : triggerGameOverHaptic = triggerGameOverHaptic ?? _triggerGameOverHaptic,
       _random = random ?? math.Random(),
       _effectsRandom = math.Random(),
       _isWaitingToStart = waitingToStart {
    this.images = images;
  }

  static const String _keyBestDistance = bestDistanceStorageKey;

  final AppLocalizations l10n;

  final AudioPlayer deathPlayer;

  final TriggerGameOverHaptic triggerGameOverHaptic;

  final TextStyle textStyle;

  final math.Random _random;

  final math.Random _effectsRandom;

  final StorageService storage;

  final GameControlMode controlMode;
  final PlayerShipSkin playerShip;
  final double invulnerabilityGraceSeconds;
  final bool waitingToStart;

  double distanceKm = 0;
  double bestDistanceKm = 0;
  double scrollSpeed = initialDriftSpeed * driftVisualSpeedScale;
  bool isGameOver = false;
  bool isNewRecord = false;
  int combo = 0;
  int maxCombo = 0;

  Ship? ship;
  DriftHudComponent? hud;
  SpaceBackgroundComponent? background;
  StarfieldComponent? get starfield => background?.starfield;

  EdgeInsets _safeAreaPadding = EdgeInsets.zero;
  final List<AsteroidPairComponent> obstacles = [];
  final List<LooseMeteorComponent> looseMeteors = [];
  final List<PowerUpComponent> powerUps = [];
  final Paint _slowMotionPaint = Paint()..color = slowMotionTintColor;

  double _invulnerabilitySeconds = 0;
  double _slowMotionSeconds = 0;
  double _comboSeconds = 0;
  double _shake = 0;
  double _deathTimeScale = 1;
  double _deathElapsed = 0;
  bool _deathOverlayShown = false;
  bool _isWaitingToStart;

  ui.Image? _asteroidTileImage;
  ui.Image? _looseMeteorImage;
  ui.Image? _playerShipImage;
  final Map<String, ui.Image?> _asteroidTileImages = {};
  final Map<String, ui.Image?> _spaceLandmarkImages = {};

  double _nextObstacleY = initialObstacleY;
  double _nextLooseMeteorY = initialLooseMeteorY;
  ObstacleSequence _nextObstacleSequence = ObstacleSequence.asteroidPairs;
  int _consecutiveAsteroidPairSequences = 0;
  int _consecutiveLooseMeteorSequences = 0;

  double get driftSpeed =>
      initialDriftSpeed +
      distanceKm * driftSpeedGrowth +
      deepDifficulty * deepSpaceSpeedBonus;

  double get difficulty => (distanceKm / 3000).clamp(0, 1);

  double get deepDifficulty =>
      ((distanceKm - deepSpaceStartKm) / deepSpaceRangeKm).clamp(0, 1);

  bool get isInvulnerable => _invulnerabilitySeconds > 0;

  bool get isWaitingToStart => _isWaitingToStart;

  bool get isSlowMotionActive => _slowMotionSeconds > 0;

  double get timeScale => isSlowMotionActive ? slowMotionTimeScale : 1;

  double get comboMultiplier =>
      math.min(maxComboMultiplier, 1 + combo * comboMultiplierStep);

  double get shakeIntensity => _shake;

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
    final realDt = math.min(dt, maxGameUpdateDt);

    if (_isWaitingToStart) {
      return;
    }

    if (isGameOver) {
      _updateAfterDeath(realDt);
      return;
    }

    _tickTimers(realDt);
    final effectiveDt = realDt * timeScale;
    super.update(effectiveDt);

    distanceKm += driftSpeed * effectiveDt * comboMultiplier;
    scrollSpeed = driftSpeed * driftVisualSpeedScale;
    background?.advance(scrollSpeed, effectiveDt, distanceKm);

    _updateObstacles(effectiveDt);
    if (isGameOver) {
      return;
    }

    _updateLooseMeteors(effectiveDt);
    if (isGameOver) {
      return;
    }

    _updatePowerUps(effectiveDt);
    _advanceObstacleSequenceIfNeeded();
    _applySoftBounds();
    _updateShake(realDt);
  }

  void _updateAfterDeath(double dt) {
    _deathTimeScale = (_deathTimeScale + deathSlowMotionRecovery * dt).clamp(
      0.0,
      1.0,
    );
    super.update(dt * _deathTimeScale);
    _updateShake(dt);
    _deathElapsed += dt;

    if (!_deathOverlayShown && _deathElapsed >= deathOverlayDelaySeconds) {
      _deathOverlayShown = true;
      if (overlays.registeredOverlays.contains(gameOverOverlayKey)) {
        overlays.add(gameOverOverlayKey);
      }
      pauseEngine();
    }
  }

  void _tickTimers(double dt) {
    if (_invulnerabilitySeconds > 0) {
      _invulnerabilitySeconds = math.max(0, _invulnerabilitySeconds - dt);
    }
    if (_slowMotionSeconds > 0) {
      _slowMotionSeconds = math.max(0, _slowMotionSeconds - dt);
    }
    if (combo > 0) {
      _comboSeconds -= dt;
      if (_comboSeconds <= 0) {
        combo = 0;
        _comboSeconds = 0;
      }
    }
    ship?.invulnerable = isInvulnerable;
  }

  void _updateObstacles(double dt) {
    for (var i = obstacles.length - 1; i >= 0; i--) {
      final obstacle = obstacles[i]..moveByScroll(scrollSpeed, dt);

      final currentShip = ship;
      if (currentShip != null && !isInvulnerable) {
        if (obstacle.collidesWith(currentShip)) {
          if (_tryAbsorbHit(currentShip.position)) {
            obstacles.removeAt(i);
            obstacle.removeFromParent();
            continue;
          }
          endRun();
          return;
        }
        if (obstacle.tryRegisterNearMiss(currentShip, nearMissThreshold)) {
          _rewardNearMiss();
        }
      }

      if (obstacle.isOffscreen) {
        obstacles.removeAt(i);
        obstacle.removeFromParent();
      }
    }
  }

  void _updateLooseMeteors(double dt) {
    for (var i = looseMeteors.length - 1; i >= 0; i--) {
      final meteor = looseMeteors[i]..moveByScroll(scrollSpeed, dt);

      final currentShip = ship;
      if (currentShip != null && !isInvulnerable) {
        if (meteor.collidesWith(currentShip)) {
          if (_tryAbsorbHit(currentShip.position)) {
            looseMeteors.removeAt(i);
            meteor.removeFromParent();
            continue;
          }
          endRun();
          return;
        }
        if (meteor.tryRegisterNearMiss(currentShip, nearMissThreshold)) {
          _rewardNearMiss();
        }
      }

      if (meteor.isOffscreen) {
        looseMeteors.removeAt(i);
        meteor.removeFromParent();
      }
    }
  }

  void _updatePowerUps(double dt) {
    for (var i = powerUps.length - 1; i >= 0; i--) {
      final powerUp = powerUps[i]..moveByScroll(scrollSpeed, dt);

      final currentShip = ship;
      if (currentShip != null && powerUp.collidesWith(currentShip)) {
        _collectPowerUp(powerUp);
        continue;
      }

      if (powerUp.isOffscreen) {
        powerUps.removeAt(i);
        powerUp.removeFromParent();
      }
    }
  }

  void _collectPowerUp(PowerUpComponent powerUp) {
    switch (powerUp.type) {
      case PowerUpType.shield:
        ship?.grantShield();
      case PowerUpType.slowMotion:
        _slowMotionSeconds = slowMotionDurationSeconds;
    }

    _spawnBurst(powerUp.position, powerUp.type.color);
    powerUps.remove(powerUp);
    powerUp.removeFromParent();
  }

  bool _tryAbsorbHit(Vector2 hitPosition) {
    final currentShip = ship;
    if (currentShip == null || !currentShip.consumeShield()) {
      return false;
    }

    _invulnerabilitySeconds = math.max(
      _invulnerabilitySeconds,
      shieldInvulnerabilitySeconds,
    );
    _spawnBurst(hitPosition, shieldBurstColor);
    _addShake(shieldShakeIntensity);
    return true;
  }

  void _rewardNearMiss() {
    combo += 1;
    maxCombo = math.max(maxCombo, combo);
    _comboSeconds = comboDurationSeconds;
    _addShake(nearMissShakeIntensity);
  }

  void _applySoftBounds() {
    final currentShip = ship;
    if (currentShip == null) {
      return;
    }

    final radius = currentShip.collisionRadius;
    final area = playArea;
    var bounced = false;

    if (currentShip.position.x - radius < 0) {
      currentShip.position.x = radius;
      currentShip.velocity.x = currentShip.velocity.x.abs() * bounceRestitution;
      bounced = true;
    } else if (currentShip.position.x + radius > area.x) {
      currentShip.position.x = area.x - radius;
      currentShip.velocity.x =
          -currentShip.velocity.x.abs() * bounceRestitution;
      bounced = true;
    }

    if (currentShip.position.y - radius < 0) {
      currentShip.position.y = radius;
      currentShip.velocity.y = currentShip.velocity.y.abs() * bounceRestitution;
      bounced = true;
    } else if (currentShip.position.y + radius > area.y) {
      currentShip.position.y = area.y - radius;
      currentShip.velocity.y =
          -currentShip.velocity.y.abs() * bounceRestitution;
      bounced = true;
    }

    if (bounced) {
      _addShake(bounceShakeIntensity);
    }
  }

  void _addShake(double intensity) {
    _shake = math.max(_shake, intensity);
  }

  void _updateShake(double dt) {
    if (_shake <= 0) {
      return;
    }
    _shake = math.max(0, _shake - shakeDecayPerSecond * dt);
  }

  void _spawnBurst(Vector2 position, Color color) {
    final burst = ParticleBurstComponent(
      position: position.clone(),
      color: color,
      random: _effectsRandom,
    );
    final addFuture = add(burst);
    if (addFuture is Future<void>) {
      unawaited(addFuture);
    }
  }

  @override
  void render(Canvas canvas) {
    final shake = _shake;
    final hasShake = shake > 0.05;
    if (hasShake) {
      canvas
        ..save()
        ..translate(
          (_effectsRandom.nextDouble() * 2 - 1) * shake,
          (_effectsRandom.nextDouble() * 2 - 1) * shake,
        );
    }

    super.render(canvas);

    if (hasShake) {
      canvas.restore();
    }

    if (isSlowMotionActive) {
      canvas.drawRect(Offset.zero & Size(size.x, size.y), _slowMotionPaint);
    }
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
    if (controlMode != GameControlMode.touch || isGameOver) {
      return;
    }

    ship?.setThrustTarget(event.canvasPosition);
  }

  @override
  void onTapUp(TapUpEvent event) {
    if (controlMode != GameControlMode.touch) {
      return;
    }

    ship?.clearThrust();
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    if (controlMode != GameControlMode.touch) {
      return;
    }

    ship?.clearThrust();
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (controlMode == GameControlMode.touch && !isGameOver) {
      ship?.setThrustTarget(event.canvasPosition);
    }
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (controlMode == GameControlMode.touch && !isGameOver) {
      ship?.setThrustTarget(event.canvasEndPosition);
    }
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    if (controlMode != GameControlMode.touch) {
      return;
    }

    ship?.clearThrust();
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
    if (controlMode != GameControlMode.touch) {
      return;
    }

    ship?.clearThrust();
  }

  void setJoystickDirection(Vector2 direction) {
    if (controlMode != GameControlMode.joystick || isGameOver) {
      return;
    }

    if (direction.length2 < 0.0001) {
      clearJoystick();
      return;
    }

    ship?.setThrustDirection(direction);
  }

  void clearJoystick() {
    if (controlMode != GameControlMode.joystick) {
      return;
    }

    ship?.clearThrust();
  }

  void startRun() {
    _isWaitingToStart = false;
  }

  void endRun() {
    if (isGameOver) {
      return;
    }

    isGameOver = true;
    _deathTimeScale = deathSlowMotionTimeScale;
    _deathElapsed = 0;
    _deathOverlayShown = false;

    if (distanceKm > bestDistanceKm) {
      bestDistanceKm = distanceKm;
      isNewRecord = true;
      unawaited(storage.setDouble(_keyBestDistance, bestDistanceKm));
    }

    unawaited(triggerGameOverHaptic());
    unawaited(deathPlayer.play(AssetSource(Assets.audio.death)));

    final currentShip = ship;
    if (currentShip != null) {
      _spawnBurst(currentShip.position, deathBurstColor);
      currentShip.clearThrust();
      currentShip.velocity.setZero();
    }
    _addShake(deathShakeIntensity);
  }

  Future<void> restartRun() async {
    resumeEngine();
    isGameOver = false;
    _deathTimeScale = 1;
    _deathElapsed = 0;
    _deathOverlayShown = false;
    overlays.remove(gameOverOverlayKey);
    distanceKm = 0;
    scrollSpeed = initialDriftSpeed * driftVisualSpeedScale;
    combo = 0;
    maxCombo = 0;
    isNewRecord = false;
    _comboSeconds = 0;
    _slowMotionSeconds = 0;
    _invulnerabilitySeconds = invulnerabilityGraceSeconds;
    _shake = 0;
    _nextObstacleY = initialObstacleY;
    _nextLooseMeteorY = initialLooseMeteorY;
    _nextObstacleSequence = ObstacleSequence.asteroidPairs;
    _consecutiveAsteroidPairSequences = 0;
    _consecutiveLooseMeteorSequences = 0;

    _removeBursts();
    _removePowerUps();
    ship?.reset(_shipStartPosition());
    ship?.invulnerable = isInvulnerable;
    background?.reset();

    _removeAsteroidPairs();
    _removeLooseMeteors();

    _spawnNextObstacleSequence();
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
      thrustPower: _shipThrustPower,
      maxSpeed: _shipMaxSpeed,
      shipImage: _playerShipImage,
    );
    hud = DriftHudComponent(position: Vector2(12, 12));

    await addAll([
      background!,
      ship!,
      hud!,
    ]);

    _invulnerabilitySeconds = invulnerabilityGraceSeconds;
    ship?.invulnerable = isInvulnerable;
    _spawnNextObstacleSequence();
    hud?.reposition(playArea, safeAreaPadding: _safeAreaPadding);
  }

  Vector2 _shipStartPosition() {
    final area = playArea;
    return Vector2(area.x / 2, area.y * 0.72);
  }

  double get _shipThrustPower => switch (controlMode) {
    GameControlMode.touch => defaultShipThrustPower,
    GameControlMode.joystick => joystickShipThrustPower,
  };

  double get _shipMaxSpeed => switch (controlMode) {
    GameControlMode.touch => defaultShipMaxSpeed,
    GameControlMode.joystick => joystickShipMaxSpeed,
  };

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

  void _removePowerUps() {
    for (final powerUp in powerUps.toList()) {
      powerUp.removeFromParent();
    }
    powerUps.clear();
  }

  void _removeBursts() {
    final bursts = children.whereType<ParticleBurstComponent>().toList();
    for (final burst in bursts) {
      burst.removeFromParent();
    }
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
    final spawned = <AsteroidPairComponent>[];
    for (var i = 0; i < asteroidPairSequenceLength; i++) {
      spawned.add(_spawnObstacle());
    }
    _maybeSpawnPowerUp(spawned);
  }

  void _spawnLooseMeteorSequence({double? afterY}) {
    _nextLooseMeteorY = afterY == null
        ? initialLooseMeteorY
        : math.min(initialLooseMeteorY, afterY - looseMeteorSpacing);
    final sequenceLength =
        looseMeteorBaseSequenceLength +
        (difficulty * looseMeteorDifficultyBonus).round() +
        (deepDifficulty * looseMeteorDeepDifficultyBonus).round();
    final area = playArea;
    final formationCenter =
        area.x / 2 + (_random.nextDouble() * 2 - 1) * area.x * 0.15;
    final formationAmplitude = area.x * (0.12 + _random.nextDouble() * 0.16);
    final formationWave = 0.7 + _random.nextDouble() * 0.6;
    final formationPhase = _random.nextDouble() * math.pi * 2;
    for (var i = 0; i < sequenceLength; i++) {
      final x =
          (formationCenter +
                  math.sin(i * formationWave + formationPhase) *
                      formationAmplitude)
              .clamp(0.0, area.x);
      _spawnLooseMeteor(x: x);
    }
  }

  AsteroidPairComponent _spawnObstacle() {
    final area = playArea;
    final margin = math.min(area.x / 2, asteroidBaseGap / 2 + 24);
    final span = math.max(0, area.x - margin * 2);
    final gapCenter = margin + _random.nextDouble() * span;
    final movingGap = _random.nextDouble() < _movingGapChance;
    final obstacle = AsteroidPairComponent(
      gameSize: area,
      y: _nextObstacleY,
      difficulty: difficulty,
      gapCenterX: gapCenter,
      gapDriftAmplitude: movingGap ? _movingGapAmplitude : 0,
      gapDriftSpeed: movingGap ? _movingGapSpeed : 0,
      gapPhase: _random.nextDouble() * math.pi * 2,
      asteroidTileImage: _asteroidTileImageForDistance(distanceKm),
    );
    obstacles.add(obstacle);
    final addFuture = add(obstacle);
    if (addFuture is Future<void>) {
      unawaited(addFuture);
    }
    _nextObstacleY -= obstacleSpacing;
    return obstacle;
  }

  double get _movingGapChance =>
      (movingGapBaseChance +
              difficulty * movingGapDifficultyChance +
              deepDifficulty * movingGapDeepChance)
          .clamp(0, movingGapMaxChance);

  double get _movingGapAmplitude =>
      movingGapBaseAmplitude +
      difficulty * movingGapDifficultyAmplitude +
      _random.nextDouble() * movingGapRandomAmplitude;

  double get _movingGapSpeed =>
      movingGapBaseSpeed + _random.nextDouble() * movingGapSpeedRange;

  void _maybeSpawnPowerUp(List<AsteroidPairComponent> spawned) {
    final staticHosts = spawned
        .where((obstacle) => !obstacle.isMovingGap)
        .toList(growable: false);
    if (staticHosts.isEmpty || _random.nextDouble() >= powerUpSpawnChance) {
      return;
    }

    final host = staticHosts[_random.nextInt(staticHosts.length)];
    final type = _random.nextBool()
        ? PowerUpType.shield
        : PowerUpType.slowMotion;
    final powerUp = PowerUpComponent(
      gameSize: playArea,
      position: Vector2(host.gapCenterX, host.position.y),
      type: type,
      horizontalDrift: (_random.nextDouble() * 2 - 1) * powerUpHorizontalDrift,
    );
    powerUps.add(powerUp);
    final addFuture = add(powerUp);
    if (addFuture is Future<void>) {
      unawaited(addFuture);
    }
  }

  void _spawnLooseMeteor({double? x}) {
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
        x ?? (margin + _random.nextDouble() * span),
        _nextLooseMeteorY,
      ),
      radius: radius,
      horizontalDrift:
          (_random.nextDouble() * 2 - 1) *
          (14 + difficulty * 22 + deepDifficulty * 14),
      rotationSpeed: (_random.nextDouble() * 2 - 1) * (0.6 + difficulty * 0.9),
      meteorImage: _looseMeteorImage,
    );
    looseMeteors.add(meteor);
    final addFuture = add(meteor);
    if (addFuture is Future<void>) {
      unawaited(addFuture);
    }
    _nextLooseMeteorY -= looseMeteorSpacing;
  }

  Future<void> _loadGameImages() async {
    _asteroidTileImage = await _loadGameImage(asteroidTileImageAsset);
    _asteroidTileImages.clear();
    for (final entry in asteroidTileImageAssetsByLandmarkId.entries) {
      _asteroidTileImages[entry.key] = await _loadGameImage(entry.value);
    }
    _looseMeteorImage = await _loadGameImage(looseMeteorImageAsset);
    _playerShipImage = await _loadGameImage(playerShip.assetPath);
    _spaceLandmarkImages.clear();
    for (final assetPath in spaceLandmarkAssetPaths) {
      _spaceLandmarkImages[assetPath] = await _loadGameImage(assetPath);
    }
  }

  ui.Image? _asteroidTileImageForDistance(double distanceKm) {
    final landmarkId = landmarkForDistance(distanceKm).id;
    return _asteroidTileImages[landmarkId] ?? _asteroidTileImage;
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

Future<void> _triggerGameOverHaptic() async {
  try {
    await HapticFeedback.lightImpact();
  } on Object {
    // Haptic feedback is best-effort and should never block game over.
  }
}
