import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class StarfieldComponent extends PositionComponent {
  StarfieldComponent({
    required Vector2 gameSize,
    this.seed = 7,
  }) : gameSize = gameSize.clone(),
       super(size: gameSize.clone());

  final Vector2 gameSize;
  final int seed;

  final List<_Star> _stars = [];
  double _offset = 0;

  @override
  Future<void> onLoad() async {
    final random = math.Random(seed);
    for (var i = 0; i < 95; i++) {
      _stars.add(
        _Star(
          x: random.nextDouble() * gameSize.x,
          y: random.nextDouble() * gameSize.y,
          radius: random.nextBool() ? 1 : 1.6,
          speedFactor: random.nextBool() ? 0.28 : 0.55,
        ),
      );
    }
  }

  void advance(double scrollSpeed, double dt) {
    _offset = (_offset + scrollSpeed * dt) % gameSize.y;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final backgroundPaint = Paint()..color = const Color(0xFF080A19);
    final starPaint = Paint()..color = const Color(0xFFEAF7FF);
    canvas.drawRect(
      Offset.zero & Size(gameSize.x, gameSize.y),
      backgroundPaint,
    );

    for (final star in _stars) {
      final y = (star.y + _offset * star.speedFactor) % gameSize.y;
      canvas.drawCircle(Offset(star.x, y), star.radius, starPaint);
    }
  }
}

class _Star {
  const _Star({
    required this.x,
    required this.y,
    required this.radius,
    required this.speedFactor,
  });

  final double x;
  final double y;
  final double radius;
  final double speedFactor;
}
