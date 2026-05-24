import 'dart:math' as math;
import 'dart:ui';

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
  }) : super(
         anchor: Anchor.center,
         size: size ?? Vector2(20, 28),
       );

  final double thrustPower;
  final double maxSpeed;
  final double turnSpeed;

  final Vector2 velocity = Vector2.zero();

  Vector2 _thrustDirection = Vector2.zero();

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
      velocity.add(_thrustDirection * thrustPower * dt);
      if (velocity.length > maxSpeed) {
        velocity
          ..normalize()
          ..scale(maxSpeed);
      }
      _turnTowards(_thrustDirection, dt);
    } else if (velocity.length2 > 1) {
      _turnTowards(velocity.normalized(), dt);
    }

    position.add(velocity * dt);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

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
      final flame = Path()
        ..moveTo(size.x * 0.38, size.y * 0.86)
        ..lineTo(size.x / 2, size.y * 1.18)
        ..lineTo(size.x * 0.62, size.y * 0.86)
        ..close();
      canvas.drawPath(flame, flamePaint);
    }
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
