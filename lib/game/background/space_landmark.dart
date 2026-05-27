import 'dart:ui';

import 'package:flutter/foundation.dart';

@immutable
class SpaceLandmark {
  const SpaceLandmark({
    required this.id,
    required this.assetPath,
    required this.startKm,
    required this.visibleKm,
    required this.scale,
    required this.startAnchor,
    required this.endAnchor,
    required this.opacity,
    required this.parallaxFactor,
  });

  final String id;
  final String assetPath;
  final double startKm;
  final double visibleKm;
  final double scale;
  final Offset startAnchor;
  final Offset endAnchor;
  final double opacity;
  final double parallaxFactor;

  double progressAt(double distanceKm) {
    return ((distanceKm - startKm) / visibleKm).clamp(0, 1);
  }

  bool isVisibleAt(double distanceKm) {
    return distanceKm >= startKm && distanceKm <= startKm + visibleKm;
  }

  SpaceLandmark copyWith({
    String? id,
    String? assetPath,
    double? startKm,
    double? visibleKm,
    double? scale,
    Offset? startAnchor,
    Offset? endAnchor,
    double? opacity,
    double? parallaxFactor,
  }) {
    return SpaceLandmark(
      id: id ?? this.id,
      assetPath: assetPath ?? this.assetPath,
      startKm: startKm ?? this.startKm,
      visibleKm: visibleKm ?? this.visibleKm,
      scale: scale ?? this.scale,
      startAnchor: startAnchor ?? this.startAnchor,
      endAnchor: endAnchor ?? this.endAnchor,
      opacity: opacity ?? this.opacity,
      parallaxFactor: parallaxFactor ?? this.parallaxFactor,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SpaceLandmark &&
            other.id == id &&
            other.assetPath == assetPath &&
            other.startKm == startKm &&
            other.visibleKm == visibleKm &&
            other.scale == scale &&
            other.startAnchor == startAnchor &&
            other.endAnchor == endAnchor &&
            other.opacity == opacity &&
            other.parallaxFactor == parallaxFactor;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      assetPath,
      startKm,
      visibleKm,
      scale,
      startAnchor,
      endAnchor,
      opacity,
      parallaxFactor,
    );
  }
}
