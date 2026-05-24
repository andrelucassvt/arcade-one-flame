import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:arcade_one/game/entities/entities.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

const double asteroidPairHeight = 58;
const double asteroidBaseGap = 150;
const double asteroidMinGap = 76;

class AsteroidPairComponent extends PositionComponent {
  AsteroidPairComponent({
    required Vector2 gameSize,
    required double y,
    required double difficulty,
    double? gapCenterX,
    this.asteroidTileImage,
  }) : gameSize = gameSize.clone(),
       difficulty = difficulty.clamp(0, 1),
       gapSize = math.max(
         asteroidMinGap,
         asteroidBaseGap - (difficulty.clamp(0, 1) * 64),
       ),
       gapCenterX = gapCenterX ?? gameSize.x / 2,
       super(
         position: Vector2(0, y),
         size: Vector2(gameSize.x, asteroidPairHeight),
       );

  final Vector2 gameSize;
  final double difficulty;
  final double gapSize;
  final double gapCenterX;
  final ui.Image? asteroidTileImage;

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

  bool get isOffscreen => position.y > gameSize.y + height;

  void moveByScroll(double scrollSpeed, double dt) {
    position.y += scrollSpeed * dt;
  }

  bool collidesWith(Ship ship) {
    final center = Offset(ship.position.x - position.x, ship.position.y - y);
    return _circleIntersectsRect(center, ship.collisionRadius, leftRect) ||
        _circleIntersectsRect(center, ship.collisionRadius, rightRect);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final asteroidPaint = Paint()..color = const Color(0xFF6C6A7C);
    final highlightPaint = Paint()..color = const Color(0xFF9E94B8);

    final tileImage = asteroidTileImage;
    if (tileImage == null) {
      _drawAsteroidBlock(canvas, leftRect, asteroidPaint, highlightPaint);
      _drawAsteroidBlock(canvas, rightRect, asteroidPaint, highlightPaint);
      return;
    }

    _drawSpriteBlock(canvas, leftRect, tileImage, asteroidPaint);
    _drawSpriteBlock(canvas, rightRect, tileImage, asteroidPaint);
  }

  void _drawAsteroidBlock(
    Canvas canvas,
    Rect rect,
    Paint asteroidPaint,
    Paint highlightPaint,
  ) {
    if (rect.width <= 0) {
      return;
    }

    final block = RRect.fromRectAndRadius(rect, const Radius.circular(4));
    canvas.drawRRect(block, asteroidPaint);

    for (var x = rect.left + 12; x < rect.right; x += 36) {
      final yOffset = ((x / 12).round().isEven ? 12 : 34).toDouble();
      canvas.drawRect(
        Rect.fromLTWH(x, rect.top + yOffset, 10, 8),
        highlightPaint,
      );
    }
  }

  void _drawSpriteBlock(
    Canvas canvas,
    Rect rect,
    ui.Image image,
    Paint basePaint,
  ) {
    if (rect.width <= 0) {
      return;
    }

    final block = RRect.fromRectAndRadius(rect, const Radius.circular(4));
    final spritePaint = Paint()
      ..isAntiAlias = false
      ..filterQuality = FilterQuality.medium;
    final source = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    final tileSize = height * 1.05;

    canvas
      ..drawRRect(block, basePaint)
      ..save()
      ..clipRRect(block);

    for (
      var x = rect.left - tileSize * 0.18;
      x < rect.right;
      x += tileSize * 0.7
    ) {
      final index = ((x - rect.left) / tileSize).round();
      final yOffset = index.isEven ? -tileSize * 0.12 : tileSize * 0.03;
      final destination = Rect.fromLTWH(
        x,
        rect.top + yOffset,
        tileSize,
        tileSize,
      );
      canvas.drawImageRect(image, source, destination, spritePaint);
    }

    canvas.restore();
  }

  bool _circleIntersectsRect(Offset center, double radius, Rect rect) {
    if (rect.isEmpty) {
      return false;
    }

    final nearestX = center.dx.clamp(rect.left, rect.right);
    final nearestY = center.dy.clamp(rect.top, rect.bottom);
    final dx = center.dx - nearestX;
    final dy = center.dy - nearestY;
    return dx * dx + dy * dy <= radius * radius;
  }
}
