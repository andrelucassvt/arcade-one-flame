import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

const double defaultShipThrustPower = 520;
const double defaultShipMaxSpeed = 250;
const double defaultShipTurnSpeed = 12;
const double shipThrustDeadZone = 6;
const double shipDirectionSmoothing = 16;
const double shipIdleDamping = 0.6;
const double shipTrailInterval = 0.024;
const double shipTrailLifetime = 0.35;
const double _shieldRadiusFactor = 0.72;

class Ship extends PositionComponent {
  Ship({
    required super.position,
    Vector2? size,
    this.thrustPower = defaultShipThrustPower,
    this.maxSpeed = defaultShipMaxSpeed,
    this.turnSpeed = defaultShipTurnSpeed,
    this.shipImage,
    math.Random? random,
  }) : _random = random ?? math.Random(),
       super(
         anchor: Anchor.center,
         size: size ?? Vector2(30, 38),
       );

  final double thrustPower;
  final double maxSpeed;
  final double turnSpeed;
  final ui.Image? shipImage;
  final math.Random _random;

  final Vector2 velocity = Vector2.zero();

  final Paint _shipPaint = Paint()..color = const Color(0xFFE8F7FF);
  final Paint _cockpitPaint = Paint()..color = const Color(0xFF57E4FF);
  final Paint _wingPaint = Paint()..color = const Color(0xFF8A7CFF);
  final Paint _flamePaint = Paint()..color = const Color(0xFFFFB000);
  final Paint _flameCorePaint = Paint()..color = const Color(0xFFFFF1A8);
  final Paint _trailPaint = Paint();
  final Paint _spritePaint = Paint()
    ..isAntiAlias = false
    ..filterQuality = FilterQuality.medium;
  final Paint _shieldOuterPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  final Paint _shieldInnerPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.4;

  final List<_TrailParticle> _trailParticles = [];

  Vector2? _thrustTarget;
  Vector2 _thrustDirection = Vector2.zero();
  double _thrustAnimationTime = 0;
  double _elapsedTime = 0;
  double _trailTimer = 0;
  bool invulnerable = false;
  bool _hasShield = false;

  bool get isThrusting => _thrustDirection.length2 > 0;

  bool get hasThrustTarget => _thrustTarget != null;

  bool get hasShield => _hasShield;

  double get collisionRadius => math.min(size.x, size.y) * 0.38;

  void setThrustTarget(Vector2 target) {
    _thrustTarget = target.clone();
  }

  void setThrustDirection(Vector2 direction) {
    _thrustTarget = null;
    if (direction.length2 < 0.0001) {
      clearThrust();
      return;
    }

    _thrustDirection = direction.normalized();
  }

  void clearThrust() {
    _thrustTarget = null;
    _thrustDirection = Vector2.zero();
  }

  void grantShield() => _hasShield = true;

  bool consumeShield() {
    if (!_hasShield) {
      return false;
    }
    _hasShield = false;
    return true;
  }

  void reset(Vector2 newPosition) {
    position = newPosition;
    velocity.setZero();
    angle = 0;
    _thrustTarget = null;
    _thrustDirection = Vector2.zero();
    _thrustAnimationTime = 0;
    _elapsedTime = 0;
    _trailTimer = 0;
    _trailParticles.clear();
    invulnerable = false;
    _hasShield = false;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsedTime += dt;

    final target = _thrustTarget;
    if (target != null) {
      _steerTowardsTarget(target, dt);
    }

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
      velocity.scale(math.exp(-shipIdleDamping * dt));
    } else {
      _thrustAnimationTime = 0;
    }

    position.add(velocity * dt);
    _updateTrail(dt);
  }

  void _steerTowardsTarget(Vector2 target, double dt) {
    final desired = target - position;
    if (desired.length < shipThrustDeadZone) {
      _thrustDirection = Vector2.zero();
      return;
    }

    desired.normalize();
    if (_thrustDirection.length2 < 0.0001) {
      _thrustDirection = desired;
      return;
    }

    final current = _thrustDirection.normalized();
    final cross = current.x * desired.y - current.y * desired.x;
    final dot = current.dot(desired).clamp(-1.0, 1.0);
    final maxStep = shipDirectionSmoothing * dt;
    final step = math.atan2(cross, dot).clamp(-maxStep, maxStep);
    final cos = math.cos(step);
    final sin = math.sin(step);
    _thrustDirection.setValues(
      current.x * cos - current.y * sin,
      current.x * sin + current.y * cos,
    );
  }

  void _updateTrail(double dt) {
    for (var i = _trailParticles.length - 1; i >= 0; i--) {
      final particle = _trailParticles[i]..life -= dt;
      if (particle.life <= 0) {
        _trailParticles.removeAt(i);
        continue;
      }
      particle.offset.addScaled(particle.velocity, dt);
    }

    if (!isThrusting) {
      _trailTimer = 0;
      return;
    }

    _trailTimer += dt;
    while (_trailTimer >= shipTrailInterval) {
      _trailTimer -= shipTrailInterval;
      _spawnTrailParticle();
    }
  }

  void _spawnTrailParticle() {
    _trailParticles.add(
      _TrailParticle(
        offset: Vector2(
          size.x / 2 + (_random.nextDouble() * 2 - 1) * 4,
          size.y * 0.95,
        ),
        velocity: Vector2(
          (_random.nextDouble() * 2 - 1) * 24,
          55 + _random.nextDouble() * 45,
        ),
        maxLife: shipTrailLifetime * (0.7 + _random.nextDouble() * 0.6),
        radius: 2.2 + _random.nextDouble() * 1.6,
      ),
    );
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    _renderTrail(canvas);

    if (_isBlinking) {
      return;
    }

    final currentImage = shipImage;
    if (currentImage != null) {
      _renderSpriteShip(canvas, currentImage);
    } else {
      _renderProceduralShip(canvas);
    }
    _renderShield(canvas);
  }

  bool get _isBlinking => invulnerable && (_elapsedTime % 0.24) >= 0.12;

  void _renderProceduralShip(Canvas canvas) {
    final body = Path()
      ..moveTo(size.x / 2, 0)
      ..lineTo(size.x * 0.78, size.y * 0.78)
      ..lineTo(size.x / 2, size.y)
      ..lineTo(size.x * 0.22, size.y * 0.78)
      ..close();
    canvas.drawPath(body, _shipPaint);

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
      ..drawPath(leftWing, _wingPaint)
      ..drawPath(rightWing, _wingPaint)
      ..drawCircle(
        Offset(size.x / 2, size.y * 0.38),
        size.x * 0.16,
        _cockpitPaint,
      );

    if (isThrusting) {
      _drawAnimatedFlame(canvas, _flamePaint);
    }
  }

  void _renderSpriteShip(Canvas canvas, ui.Image image) {
    canvas.save();
    if (isThrusting) {
      final pulse = 1 + math.sin(_thrustAnimationTime) * 0.055;
      canvas
        ..translate(size.x / 2, size.y / 2)
        ..scale(pulse, pulse)
        ..translate(-size.x / 2, -size.y / 2);
      _drawAnimatedFlame(canvas, _flamePaint);
    }

    canvas
      ..drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        Rect.fromLTWH(0, 0, size.x, size.y),
        _spritePaint,
      )
      ..restore();
  }

  void _renderTrail(Canvas canvas) {
    for (final particle in _trailParticles) {
      final lifeRatio = (particle.life / particle.maxLife).clamp(0.0, 1.0);
      _trailPaint.color = Color.fromARGB(
        (lifeRatio * 170).round(),
        255,
        176,
        0,
      );
      canvas.drawCircle(
        Offset(particle.offset.x, particle.offset.y),
        particle.radius * lifeRatio,
        _trailPaint,
      );
    }
  }

  void _renderShield(Canvas canvas) {
    if (!_hasShield) {
      return;
    }

    final center = Offset(size.x / 2, size.y / 2);
    final radius = math.max(size.x, size.y) * _shieldRadiusFactor;
    _shieldOuterPaint.color = const Color(0xCC57E4FF);
    _shieldInnerPaint.color = const Color(0x6657E4FF);
    canvas
      ..drawCircle(center, radius, _shieldOuterPaint)
      ..drawCircle(center, radius * 0.84, _shieldInnerPaint);
  }

  void _drawAnimatedFlame(Canvas canvas, Paint flamePaint) {
    final flicker = 0.82 + math.sin(_thrustAnimationTime * 1.7) * 0.18;
    final flame = Path()
      ..moveTo(size.x * 0.36, size.y * 0.84)
      ..lineTo(size.x / 2, size.y * (1.12 + 0.12 * flicker))
      ..lineTo(size.x * 0.64, size.y * 0.84)
      ..close();

    canvas.drawPath(flame, flamePaint);

    final core = Path()
      ..moveTo(size.x * 0.43, size.y * 0.87)
      ..lineTo(size.x / 2, size.y * (1.04 + 0.08 * flicker))
      ..lineTo(size.x * 0.57, size.y * 0.87)
      ..close();
    canvas.drawPath(core, _flameCorePaint);
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

class _TrailParticle {
  _TrailParticle({
    required this.offset,
    required this.velocity,
    required this.maxLife,
    required this.radius,
  }) : life = maxLife;

  final Vector2 offset;
  final Vector2 velocity;
  final double maxLife;
  final double radius;
  double life;
}
