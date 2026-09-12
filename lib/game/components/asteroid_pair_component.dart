import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:arcade_one/game/entities/entities.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

const double asteroidPairHeight = 58;
const double asteroidBaseGap = 150;
const double asteroidMinGap = 76;
const double asteroidGapEdgeMargin = 10;

class AsteroidPairComponent extends PositionComponent {
  AsteroidPairComponent({
    required Vector2 gameSize,
    required double y,
    required double difficulty,
    double? gapCenterX,
    this.gapDriftAmplitude = 0,
    this.gapDriftSpeed = 0,
    this.gapPhase = 0,
    this.asteroidTileImage,
  }) : gameSize = gameSize.clone(),
       difficulty = difficulty.clamp(0, 1),
       gapSize = math.max(
         asteroidMinGap,
         asteroidBaseGap - (difficulty.clamp(0, 1) * 64),
       ),
       _baseGapCenterX = gapCenterX ?? gameSize.x / 2,
       super(
         position: Vector2(0, y),
         size: Vector2(gameSize.x, asteroidPairHeight),
       );

  static final Paint _asteroidPaint = Paint()..color = const Color(0xFF6C6A7C);
  static final Paint _highlightPaint = Paint()..color = const Color(0xFF9E94B8);
  static final Paint _spritePaint = Paint()
    ..isAntiAlias = false
    ..filterQuality = FilterQuality.medium;

  final Vector2 gameSize;
  final double difficulty;
  final double gapSize;
  final double gapDriftAmplitude;
  final double gapDriftSpeed;
  final double gapPhase;
  final ui.Image? asteroidTileImage;

  final double _baseGapCenterX;
  double _gapPhaseTime = 0;

  bool nearMissRewarded = false;

  double get gapCenterX {
    if (gapDriftAmplitude <= 0 || gapDriftSpeed == 0) {
      return _baseGapCenterX;
    }

    final edge = gapSize / 2 + asteroidGapEdgeMargin;
    final offset =
        math.sin(_gapPhaseTime * gapDriftSpeed + gapPhase) * gapDriftAmplitude;
    return (_baseGapCenterX + offset).clamp(edge, gameSize.x - edge);
  }

  Rect get leftRect {
    final width = math.max<double>(0, gapCenterX - gapSize / 2);
    return Rect.fromLTWH(0, 0, width, height);
  }

  Rect get rightRect {
    final start = math.min<double>(width, gapCenterX + gapSize / 2);
    return Rect.fromLTWH(
      start,
      0,
      math.max<double>(0, width - start),
      height,
    );
  }

  bool get isMovingGap => gapDriftAmplitude > 0 && gapDriftSpeed != 0;

  bool get isOffscreen => position.y > gameSize.y + height;

  @override
  void update(double dt) {
    super.update(dt);
    _gapPhaseTime += dt;
  }

  void moveByScroll(double scrollSpeed, double dt) {
    position.y += scrollSpeed * dt;
  }

  bool collidesWith(Ship ship) => clearanceTo(ship) <= 0;

  double clearanceTo(Ship ship) {
    final center = Offset(ship.position.x - position.x, ship.position.y - y);
    final leftClearance = _circleRectClearance(
      center,
      ship.collisionRadius,
      leftRect,
    );
    final rightClearance = _circleRectClearance(
      center,
      ship.collisionRadius,
      rightRect,
    );
    return math.min(leftClearance, rightClearance);
  }

  bool tryRegisterNearMiss(Ship ship, double threshold) {
    if (nearMissRewarded) {
      return false;
    }

    final clearance = clearanceTo(ship);
    if (clearance > 0 && clearance <= threshold) {
      nearMissRewarded = true;
      return true;
    }

    return false;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final tileImage = asteroidTileImage;
    if (tileImage == null) {
      _drawAsteroidBlock(canvas, leftRect);
      _drawAsteroidBlock(canvas, rightRect);
      return;
    }

    _drawSpriteBlock(canvas, leftRect, tileImage);
    _drawSpriteBlock(canvas, rightRect, tileImage);
  }

  void _drawAsteroidBlock(Canvas canvas, Rect rect) {
    if (rect.width <= 0) {
      return;
    }

    final block = RRect.fromRectAndRadius(rect, const Radius.circular(4));
    canvas.drawRRect(block, _asteroidPaint);

    for (var x = rect.left + 12; x < rect.right; x += 36) {
      final yOffset = ((x / 12).round().isEven ? 12 : 34).toDouble();
      canvas.drawRect(
        Rect.fromLTWH(x, rect.top + yOffset, 10, 8),
        _highlightPaint,
      );
    }
  }

  void _drawSpriteBlock(Canvas canvas, Rect rect, ui.Image image) {
    if (rect.width <= 0) {
      return;
    }

    final source = _asteroidTileSourceRect(image);
    final tileHeight = height;
    final tileWidth = tileHeight * source.width / source.height;

    canvas
      ..save()
      ..clipRect(rect);

    for (var x = rect.left; x < rect.right; x += tileWidth) {
      final destination = Rect.fromLTWH(
        x,
        rect.top,
        tileWidth,
        tileHeight,
      );
      canvas.drawImageRect(image, source, destination, _spritePaint);
    }

    canvas.restore();
  }

  Rect _asteroidTileSourceRect(ui.Image image) {
    final imageWidth = image.width.toDouble();
    final imageHeight = image.height.toDouble();
    return Rect.fromLTRB(
      imageWidth * 0.08,
      imageHeight * 0.07,
      imageWidth * 0.91,
      imageHeight * 0.93,
    );
  }

  double _circleRectClearance(Offset center, double radius, Rect rect) {
    if (rect.isEmpty) {
      return double.infinity;
    }

    final nearestX = center.dx.clamp(rect.left, rect.right);
    final nearestY = center.dy.clamp(rect.top, rect.bottom);
    final dx = center.dx - nearestX;
    final dy = center.dy - nearestY;
    return math.sqrt(dx * dx + dy * dy) - radius;
  }
}
