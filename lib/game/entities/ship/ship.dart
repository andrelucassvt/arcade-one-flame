import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

const double defaultShipThrustPower = 520;
const double defaultShipMaxSpeed = 250;
const double defaultShipTurnSpeed = 12;

class Ship extends PositionComponent {
  Ship({
    required super.position,
    Vector2? size,
    this.thrustPower = defaultShipThrustPower,
    this.maxSpeed = defaultShipMaxSpeed,
    this.turnSpeed = defaultShipTurnSpeed,
    this.shipImage,
  }) : super(
         anchor: Anchor.center,
         size: size ?? Vector2(30, 38),
       );

  final double thrustPower;
  final double maxSpeed;
  final double turnSpeed;
  final ui.Image? shipImage;

  final Vector2 velocity = Vector2.zero();

  Vector2 _thrustDirection = Vector2.zero();
  double _thrustAnimationTime = 0;

  bool get isThrusting => _thrustDirection.length2 > 0;

  double get collisionRadius => math.min(size.x, size.y) * 0.38;

  void setThrustTarget(Vector2 target) {
    final direction = target - position;
    if (direction.length2 < 0.0001) {
      clearThrust();
      return;
    }

    _thrustDirection = direction.normalized();
  }

  void clearThrust() {
    _thrustDirection = Vector2.zero();
  }

  void reset(Vector2 newPosition) {
    position = newPosition;
    velocity.setZero();
    clearThrust();
    angle = 0;
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (isThrusting) {
      _thrustAnimationTime += dt * 16;
      velocity.add(_thrustDirection * thrustPower * dt);
      if (velocity.length > maxSpeed) {
        velocity
          ..normalize()
          ..scale(maxSpeed);
      }
      _turnTowards(_thrustDirection, dt);
    } else if (velocity.length2 > 1) {
      _thrustAnimationTime = 0;
      _turnTowards(velocity.normalized(), dt);
    } else {
      _thrustAnimationTime = 0;
    }

    position.add(velocity * dt);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final currentImage = shipImage;
    if (currentImage != null) {
      _renderSpriteShip(canvas, currentImage);
      return;
    }

    final shipPaint = Paint()..color = const Color(0xFFE8F7FF);
    final cockpitPaint = Paint()..color = const Color(0xFF57E4FF);
    final wingPaint = Paint()..color = const Color(0xFF8A7CFF);
    final flamePaint = Paint()..color = const Color(0xFFFFB000);

    final body = Path()
      ..moveTo(size.x / 2, 0)
      ..lineTo(size.x * 0.78, size.y * 0.78)
      ..lineTo(size.x / 2, size.y)
      ..lineTo(size.x * 0.22, size.y * 0.78)
      ..close();
    canvas.drawPath(body, shipPaint);

    final leftWing = Path()
      ..moveTo(size.x * 0.26, size.y * 0.5)
      ..lineTo(0, size.y * 0.88)
      ..lineTo(size.x * 0.34, size.y * 0.78)
      ..close();
    final rightWing = Path()
      ..moveTo(size.x * 0.74, size.y * 0.5)
      ..lineTo(size.x, size.y * 0.88)
      ..lineTo(size.x * 0.66, size.y * 0.78)
      ..close();
    canvas
      ..drawPath(leftWing, wingPaint)
      ..drawPath(rightWing, wingPaint)
      ..drawCircle(
        Offset(size.x / 2, size.y * 0.38),
        size.x * 0.16,
        cockpitPaint,
      );

    if (isThrusting) {
      _drawAnimatedFlame(canvas, flamePaint);
    }
  }

  void _renderSpriteShip(Canvas canvas, ui.Image image) {
    final paint = Paint()
      ..isAntiAlias = false
      ..filterQuality = FilterQuality.medium;

    canvas.save();
    if (isThrusting) {
      final pulse = 1 + math.sin(_thrustAnimationTime) * 0.055;
      canvas
        ..translate(size.x / 2, size.y / 2)
        ..scale(pulse, pulse)
        ..translate(-size.x / 2, -size.y / 2);
      _drawAnimatedFlame(
        canvas,
        Paint()..color = const Color(0xFFFFB000),
      );
    }

    canvas
      ..drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        Rect.fromLTWH(0, 0, size.x, size.y),
        paint,
      )
      ..restore();
  }

  void _drawAnimatedFlame(Canvas canvas, Paint flamePaint) {
    final flicker = 0.82 + math.sin(_thrustAnimationTime * 1.7) * 0.18;
    final flame = Path()
      ..moveTo(size.x * 0.36, size.y * 0.84)
      ..lineTo(size.x / 2, size.y * (1.12 + 0.12 * flicker))
      ..lineTo(size.x * 0.64, size.y * 0.84)
      ..close();

    canvas.drawPath(flame, flamePaint);

    final corePaint = Paint()..color = const Color(0xFFFFF1A8);
    final core = Path()
      ..moveTo(size.x * 0.43, size.y * 0.87)
      ..lineTo(size.x / 2, size.y * (1.04 + 0.08 * flicker))
      ..lineTo(size.x * 0.57, size.y * 0.87)
      ..close();
    canvas.drawPath(core, corePaint);
  }

  void _turnTowards(Vector2 direction, double dt) {
    final targetAngle = math.atan2(direction.y, direction.x) + math.pi / 2;
    final delta = _normalizeAngle(targetAngle - angle);
    final maxStep = turnSpeed * dt;
    angle += delta.clamp(-maxStep, maxStep);
  }

  double _normalizeAngle(double value) {
    var angle = value;
    while (angle > math.pi) {
      angle -= math.pi * 2;
    }
    while (angle < -math.pi) {
      angle += math.pi * 2;
    }
    return angle;
  }
}
