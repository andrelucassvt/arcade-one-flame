import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:arcade_one/game/background/space_landmark.dart';
import 'package:arcade_one/game/background/space_landmark_catalog.dart';
import 'package:arcade_one/game/components/starfield_component.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

const double _landmarkFadeFraction = 0.14;
const double _landmarkParallaxRange = 16;

class SpaceBackgroundComponent extends PositionComponent {
  SpaceBackgroundComponent({
    required Vector2 gameSize,
    Map<String, ui.Image?> landmarkImages = const {},
  }) : _gameSize = gameSize.clone(),
       _starfield = StarfieldComponent(gameSize: gameSize),
       _landmarkImages = landmarkImages,
       super(size: gameSize.clone(), priority: -100);

  Vector2 _gameSize;
  final StarfieldComponent _starfield;
  final Map<String, ui.Image?> _landmarkImages;

  double _distanceKm = 0;
  double _landmarkScrollDistance = 0;

  StarfieldComponent get starfield => _starfield;

  SpaceLandmark get activeLandmark => landmarkForDistance(_distanceKm);

  @visibleForTesting
  List<SpaceLandmark> get visibleLandmarks =>
      visibleLandmarksForDistance(_distanceKm);

  @override
  Future<void> onLoad() async {
    await _starfield.onLoad();
  }

  void advance(double scrollSpeed, double dt, double distanceKm) {
    _starfield.advance(scrollSpeed, dt);
    _landmarkScrollDistance += scrollSpeed * dt;
    _distanceKm = distanceKm;
  }

  void reset({double distanceKm = 0}) {
    _distanceKm = distanceKm;
    _landmarkScrollDistance = 0;
  }

  void resizeGame(Vector2 gameSize) {
    _gameSize = gameSize.clone();
    size = gameSize.clone();
    _starfield.resizeGame(gameSize);
  }

  @visibleForTesting
  List<double> debugStarYs() {
    return _starfield.debugStarYs();
  }

  @override
  void render(Canvas canvas) {
    _starfield.render(canvas);

    for (final landmark in visibleLandmarksForDistance(_distanceKm)) {
      _renderLandmark(canvas, landmark);
    }
  }

  void _renderLandmark(
    Canvas canvas,
    SpaceLandmark landmark,
  ) {
    final progress = landmark.progressAt(_distanceKm);
    final opacity = landmark.opacity * _visibilityOpacity(progress);
    if (opacity <= 0) {
      return;
    }

    final image = _landmarkImages[landmark.assetPath];
    if (image == null) {
      _renderFallbackLandmark(canvas, landmark, progress, opacity);
      return;
    }

    final source = ui.Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    final coverScale = math.max(
      (math.min(_gameSize.x, _gameSize.y) * landmark.scale) / image.width,
      (math.min(_gameSize.x, _gameSize.y) * landmark.scale) / image.height,
    );
    final drawSize = ui.Size(
      image.width * coverScale * landmark.scale,
      image.height * coverScale * landmark.scale,
    );
    final center = _landmarkCenter(landmark, progress);
    final destination = ui.Rect.fromCenter(
      center: center,
      width: drawSize.width,
      height: drawSize.height,
    );
    final paint = Paint()
      ..filterQuality = FilterQuality.medium
      ..color = Color.fromARGB((opacity * 255).round(), 255, 255, 255);

    canvas.drawImageRect(image, source, destination, paint);
  }

  void _renderFallbackLandmark(
    Canvas canvas,
    SpaceLandmark landmark,
    double progress,
    double opacity,
  ) {
    final center = _landmarkCenter(landmark, progress);
    final radius = math.min(_gameSize.x, _gameSize.y) * landmark.scale * 0.5;
    final paint = Paint()
      ..color = _fallbackColor(landmark).withAlpha((opacity * 180).round())
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);

    canvas.drawCircle(center, radius, paint);
  }

  ui.Offset _landmarkCenter(SpaceLandmark landmark, double progress) {
    final easedProgress = Curves.easeInOut.transform(progress);
    final anchor = ui.Offset.lerp(
      landmark.startAnchor,
      landmark.endAnchor,
      easedProgress,
    )!;
    final parallaxOffset =
        math.sin(_landmarkScrollDistance * landmark.parallaxFactor * 0.01) *
        _landmarkParallaxRange;
    return ui.Offset(
      _gameSize.x * anchor.dx,
      _gameSize.y * anchor.dy + parallaxOffset,
    );
  }

  double _visibilityOpacity(double progress) {
    final fadeIn = (progress / _landmarkFadeFraction).clamp(0, 1).toDouble();
    final fadeOut = ((1 - progress) / _landmarkFadeFraction)
        .clamp(0, 1)
        .toDouble();
    return math.min(fadeIn, fadeOut);
  }

  Color _fallbackColor(SpaceLandmark landmark) {
    return switch (landmark.id) {
      'earth_moon' => const Color(0xFF3EA2FF),
      'mars' => const Color(0xFFE07042),
      'asteroid_belt' => const Color(0xFFB7A186),
      'jupiter' => const Color(0xFFD9A46A),
      'saturn' => const Color(0xFFE2C779),
      'ice_giants' => const Color(0xFF5CC7E8),
      'kuiper_belt' => const Color(0xFFC4D6E8),
      'orion_nebula' => const Color(0xFFB95CFF),
      'pillars_creation' => const Color(0xFF71C07B),
      'black_hole' => const Color(0xFFFFA34E),
      'andromeda' => const Color(0xFF8FA8FF),
      'deep_quasar' => const Color(0xFFFFF0A8),
      _ => const Color(0xFFEAF7FF),
    };
  }
}
