import 'dart:math' as math;
import 'dart:ui';

import 'package:arcade_one/game/entities/entities.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

const double looseMeteorMinRadius = 10;
const double looseMeteorMaxRadius = 22;
const double looseMeteorSpawnMargin = looseMeteorMaxRadius + 12;

class LooseMeteorComponent extends PositionComponent {
  LooseMeteorComponent({
    required Vector2 gameSize,
    required Vector2 position,
    required double radius,
    this.horizontalDrift = 0,
  }) : gameSize = gameSize.clone(),
       radius = radius.clamp(looseMeteorMinRadius, looseMeteorMaxRadius),
       super(
         anchor: Anchor.center,
         position: position,
         size: Vector2.all(
           radius.clamp(looseMeteorMinRadius, looseMeteorMaxRadius) * 2,
         ),
       );

  final Vector2 gameSize;
  final double radius;
  final double horizontalDrift;

  bool get isOffscreen => position.y > gameSize.y + radius;

  void moveByScroll(double scrollSpeed, double dt) {
    position
      ..x += horizontalDrift * dt
      ..y += scrollSpeed * dt;
  }

  bool collidesWith(Ship ship) {
    final collisionDistance = radius + ship.collisionRadius;
    return position.distanceToSquared(ship.position) <=
        collisionDistance * collisionDistance;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final center = Offset(size.x / 2, size.y / 2);
    final meteorPaint = Paint()..color = const Color(0xFF8A8797);
    final shadowPaint = Paint()..color = const Color(0xFF4B4A5B);
    final highlightPaint = Paint()..color = const Color(0xFFC4B9D8);

    final rock = Path();
    for (var i = 0; i < 9; i++) {
      final angle = (math.pi * 2 / 9) * i;
      final wobble = i.isEven ? radius : radius * 0.78;
      final point = Offset(
        center.dx + math.cos(angle) * wobble,
        center.dy + math.sin(angle) * wobble,
      );
      if (i == 0) {
        rock.moveTo(point.dx, point.dy);
      } else {
        rock.lineTo(point.dx, point.dy);
      }
    }
    rock.close();

    canvas
      ..drawPath(rock, meteorPaint)
      ..drawCircle(
        Offset(center.dx + radius * 0.28, center.dy + radius * 0.24),
        radius * 0.24,
        shadowPaint,
      )
      ..drawCircle(
        Offset(center.dx - radius * 0.2, center.dy - radius * 0.28),
        radius * 0.18,
        highlightPaint,
      );
  }
}
