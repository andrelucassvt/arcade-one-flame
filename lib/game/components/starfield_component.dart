import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:flame/components.dart';

const double _starfieldLoopScreens = 100;
const double _smallStarRadius = 1;
const double _largeStarRadius = 1.6;

class StarfieldComponent extends PositionComponent {
  StarfieldComponent({
    required Vector2 gameSize,
    this.seed = 7,
  }) : gameSize = gameSize.clone(),
       super(size: gameSize.clone());

  Vector2 gameSize;
  final int seed;

  final Paint _backgroundPaint = Paint()..color = const Color(0xFF080A19);
  final Paint _smallStarPaint = Paint()
    ..color = const Color(0xFFEAF7FF)
    ..strokeCap = StrokeCap.round
    ..strokeWidth = _smallStarRadius * 2;
  final Paint _largeStarPaint = Paint()
    ..color = const Color(0xFFEAF7FF)
    ..strokeCap = StrokeCap.round
    ..strokeWidth = _largeStarRadius * 2;

  final List<_Star> _stars = [];
  final List<_Star> _smallStars = [];
  final List<_Star> _largeStars = [];
  Float32List _smallPoints = Float32List(0);
  Float32List _largePoints = Float32List(0);
  double _scrollDistance = 0;

  @override
  Future<void> onLoad() async {
    _seedStars();
  }

  void resizeGame(Vector2 gameSize) {
    this.gameSize = gameSize.clone();
    size = gameSize.clone();
    if (_stars.isNotEmpty) {
      _seedStars();
    }
  }

  void _seedStars() {
    _stars.clear();
    _smallStars.clear();
    _largeStars.clear();
    final random = math.Random(seed);
    for (var i = 0; i < 95; i++) {
      final x = random.nextDouble() * gameSize.x;
      final y = random.nextDouble() * gameSize.y;
      final isLarge = !random.nextBool();
      final star = _Star(
        x: x,
        y: y,
        isLarge: isLarge,
        speedFactor: random.nextBool() ? 0.28 : 0.55,
      );
      _stars.add(star);
      if (isLarge) {
        _largeStars.add(star);
      } else {
        _smallStars.add(star);
      }
    }

    _smallPoints = Float32List(_smallStars.length * 2);
    _largePoints = Float32List(_largeStars.length * 2);
  }

  void advance(double scrollSpeed, double dt) {
    _scrollDistance =
        (_scrollDistance + scrollSpeed * dt) %
        (gameSize.y * _starfieldLoopScreens);
  }

  List<double> debugStarYs() {
    return _stars.map(_starY).toList(growable: false);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    canvas.drawRect(
      Offset.zero & Size(gameSize.x, gameSize.y),
      _backgroundPaint,
    );

    _fillPoints(_smallPoints, _smallStars);
    canvas.drawRawPoints(PointMode.points, _smallPoints, _smallStarPaint);
    _fillPoints(_largePoints, _largeStars);
    canvas.drawRawPoints(PointMode.points, _largePoints, _largeStarPaint);
  }

  void _fillPoints(Float32List points, List<_Star> stars) {
    for (var i = 0; i < stars.length; i++) {
      final star = stars[i];
      points[i * 2] = star.x;
      points[i * 2 + 1] = _starY(star);
    }
  }

  double _starY(_Star star) {
    return (star.y + _scrollDistance * star.speedFactor) % gameSize.y;
  }
}

class _Star {
  const _Star({
    required this.x,
    required this.y,
    required this.isLarge,
    required this.speedFactor,
  });

  final double x;
  final double y;
  final bool isLarge;
  final double speedFactor;
}
