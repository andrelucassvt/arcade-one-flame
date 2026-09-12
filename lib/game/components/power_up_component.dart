import 'dart:math' as math;

import 'package:arcade_one/game/entities/entities.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

const double powerUpRadius = 16;
const double powerUpPulseSpeed = 3.2;
const Color shieldPowerUpColor = Color(0xFF57E4FF);
const Color slowMotionPowerUpColor = Color(0xFFB95CFF);

enum PowerUpType {
  shield,
  slowMotion,
}

extension PowerUpTypeColor on PowerUpType {
  Color get color => switch (this) {
    PowerUpType.shield => shieldPowerUpColor,
    PowerUpType.slowMotion => slowMotionPowerUpColor,
  };
}

class PowerUpComponent extends PositionComponent {
  PowerUpComponent({
    required Vector2 gameSize,
    required Vector2 position,
    required this.type,
    this.horizontalDrift = 0,
  }) : gameSize = gameSize.clone(),
       super(
         anchor: Anchor.center,
         position: position,
         size: Vector2.all(powerUpRadius * 2),
       );

  final Paint _glowPaint = Paint();
  final Paint _bodyPaint = Paint();
  final Paint _ringPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  final Paint _iconPaint = Paint()
    ..style = PaintingStyle.fill
    ..color = Colors.white;

  final Vector2 gameSize;
  final PowerUpType type;
  final double horizontalDrift;

  double _phase = 0;

  bool get isOffscreen => position.y > gameSize.y + powerUpRadius;

  @override
  void update(double dt) {
    super.update(dt);
    _phase += dt;
  }

  void moveByScroll(double scrollSpeed, double dt) {
    position
      ..x += horizontalDrift * dt
      ..y += scrollSpeed * dt;
  }

  bool collidesWith(Ship ship) {
    final collisionDistance = powerUpRadius + ship.collisionRadius;
    return position.distanceToSquared(ship.position) <=
        collisionDistance * collisionDistance;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final color = type.color;
    const center = Offset(powerUpRadius, powerUpRadius);
    final pulse = 0.85 + math.sin(_phase * powerUpPulseSpeed) * 0.15;

    _glowPaint.color = color.withValues(alpha: 0.28);
    canvas.drawCircle(center, powerUpRadius * (1.1 + 0.14 * pulse), _glowPaint);
    _bodyPaint.color = color.withValues(alpha: 0.2);
    canvas.drawCircle(center, powerUpRadius * 0.84, _bodyPaint);
    _ringPaint.color = color;
    canvas.drawCircle(center, powerUpRadius * 0.84, _ringPaint);

    switch (type) {
      case PowerUpType.shield:
        _renderShieldIcon(canvas, center);
      case PowerUpType.slowMotion:
        _renderSlowMotionIcon(canvas, center);
    }
  }

  void _renderShieldIcon(Canvas canvas, Offset center) {
    const width = powerUpRadius * 0.62;
    final shield = Path()
      ..moveTo(center.dx - width * 0.5, center.dy - width * 0.62)
      ..lineTo(center.dx + width * 0.5, center.dy - width * 0.62)
      ..lineTo(center.dx + width * 0.5, center.dy + width * 0.08)
      ..quadraticBezierTo(
        center.dx + width * 0.5,
        center.dy + width * 0.62,
        center.dx,
        center.dy + width * 0.8,
      )
      ..quadraticBezierTo(
        center.dx - width * 0.5,
        center.dy + width * 0.62,
        center.dx - width * 0.5,
        center.dy + width * 0.08,
      )
      ..close();
    canvas.drawPath(shield, _iconPaint);
  }

  void _renderSlowMotionIcon(Canvas canvas, Offset center) {
    const width = powerUpRadius * 0.56;
    const height = powerUpRadius * 0.72;
    final top = Path()
      ..moveTo(center.dx - width * 0.5, center.dy - height * 0.62)
      ..lineTo(center.dx + width * 0.5, center.dy - height * 0.62)
      ..lineTo(center.dx, center.dy - height * 0.06)
      ..close();
    final bottom = Path()
      ..moveTo(center.dx - width * 0.5, center.dy + height * 0.62)
      ..lineTo(center.dx + width * 0.5, center.dy + height * 0.62)
      ..lineTo(center.dx, center.dy + height * 0.06)
      ..close();
    canvas
      ..drawPath(top, _iconPaint)
      ..drawPath(bottom, _iconPaint);
  }
}
