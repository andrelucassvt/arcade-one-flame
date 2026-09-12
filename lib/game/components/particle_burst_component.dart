import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

const double particleBurstLifetime = 0.5;

class ParticleBurstComponent extends PositionComponent {
  ParticleBurstComponent({
    required Vector2 position,
    this.color = const Color(0xFFFFB000),
    this.particleCount = 26,
    this.speed = 260,
    double lifetime = particleBurstLifetime,
    math.Random? random,
  }) : _lifetime = lifetime,
       _random = random ?? math.Random(),
       super(
         anchor: Anchor.center,
         position: position,
         priority: 900,
       );

  final Color color;
  final int particleCount;
  final double speed;
  final double _lifetime;
  final math.Random _random;
  final Paint _particlePaint = Paint();
  final Paint _corePaint = Paint();

  final List<_BurstParticle> _particles = [];
  double _elapsed = 0;

  bool get isFinished => _elapsed >= _lifetime;

  double get progress => (_elapsed / _lifetime).clamp(0.0, 1.0);

  @override
  Future<void> onLoad() async {
    for (var i = 0; i < particleCount; i++) {
      final angle = _random.nextDouble() * math.pi * 2;
      _particles.add(
        _BurstParticle(
          direction: Vector2(math.cos(angle), math.sin(angle)),
          speed: speed * (0.35 + _random.nextDouble() * 0.65),
          radius: 1.6 + _random.nextDouble() * 2.4,
        ),
      );
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    if (isFinished) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final currentProgress = progress;
    _particlePaint.color = color.withValues(alpha: 1 - currentProgress);
    _corePaint.color = const Color(
      0xFFFFF3C4,
    ).withValues(alpha: ((1 - currentProgress * 2).clamp(0.0, 1.0)) * 0.8);

    for (final particle in _particles) {
      final distance = particle.speed * _elapsed * (1 - 0.4 * currentProgress);
      final localOffset = particle.direction * distance;
      final offset = Offset(localOffset.x, localOffset.y);
      final radius = particle.radius * (1 - currentProgress * 0.7);

      canvas
        ..drawCircle(offset, radius, _particlePaint)
        ..drawCircle(offset, radius * 0.5, _corePaint);
    }
  }
}

class _BurstParticle {
  _BurstParticle({
    required this.direction,
    required this.speed,
    required this.radius,
  });

  final Vector2 direction;
  final double speed;
  final double radius;
}
