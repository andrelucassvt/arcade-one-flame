import 'dart:ui';

import 'package:arcade_one/game/background/space_landmark.dart';
import 'package:arcade_one/game/game_image_assets.dart';

const List<SpaceLandmark> spaceLandmarks = [
  SpaceLandmark(
    id: 'earth_moon',
    assetPath: spaceEarthMoonBackgroundAsset,
    startKm: -80,
    visibleKm: 500,
    scale: 0.62,
    startAnchor: Offset(0.2, -0.18),
    endAnchor: Offset(0.12, 1.18),
    opacity: 0.88,
    parallaxFactor: 0.16,
  ),
  SpaceLandmark(
    id: 'mars',
    assetPath: spaceMarsBackgroundAsset,
    startKm: 250,
    visibleKm: 470,
    scale: 0.5,
    startAnchor: Offset(0.83, -0.16),
    endAnchor: Offset(0.9, 1.16),
    opacity: 0.86,
    parallaxFactor: 0.18,
  ),
  SpaceLandmark(
    id: 'asteroid_belt',
    assetPath: spaceAsteroidBeltBackgroundAsset,
    startKm: 600,
    visibleKm: 520,
    scale: 0.72,
    startAnchor: Offset(0.48, -0.14),
    endAnchor: Offset(0.55, 1.14),
    opacity: 0.72,
    parallaxFactor: 0.22,
  ),
  SpaceLandmark(
    id: 'jupiter',
    assetPath: spaceJupiterBackgroundAsset,
    startKm: 1000,
    visibleKm: 620,
    scale: 0.78,
    startAnchor: Offset(0.15, -0.24),
    endAnchor: Offset(0.08, 1.2),
    opacity: 0.82,
    parallaxFactor: 0.14,
  ),
  SpaceLandmark(
    id: 'saturn',
    assetPath: spaceSaturnBackgroundAsset,
    startKm: 1500,
    visibleKm: 650,
    scale: 0.9,
    startAnchor: Offset(0.78, -0.18),
    endAnchor: Offset(0.9, 1.18),
    opacity: 0.84,
    parallaxFactor: 0.14,
  ),
  SpaceLandmark(
    id: 'ice_giants',
    assetPath: spaceIceGiantsBackgroundAsset,
    startKm: 2100,
    visibleKm: 560,
    scale: 0.64,
    startAnchor: Offset(0.28, -0.16),
    endAnchor: Offset(0.2, 1.14),
    opacity: 0.8,
    parallaxFactor: 0.16,
  ),
  SpaceLandmark(
    id: 'kuiper_belt',
    assetPath: spaceKuiperBeltBackgroundAsset,
    startKm: 2800,
    visibleKm: 600,
    scale: 0.7,
    startAnchor: Offset(0.62, -0.16),
    endAnchor: Offset(0.54, 1.12),
    opacity: 0.7,
    parallaxFactor: 0.22,
  ),
  SpaceLandmark(
    id: 'orion_nebula',
    assetPath: spaceOrionNebulaBackgroundAsset,
    startKm: 3600,
    visibleKm: 720,
    scale: 0.9,
    startAnchor: Offset(0.18, -0.18),
    endAnchor: Offset(0.14, 1.16),
    opacity: 0.62,
    parallaxFactor: 0.1,
  ),
  SpaceLandmark(
    id: 'pillars_creation',
    assetPath: spacePillarsCreationBackgroundAsset,
    startKm: 4500,
    visibleKm: 720,
    scale: 0.86,
    startAnchor: Offset(0.78, -0.18),
    endAnchor: Offset(0.84, 1.18),
    opacity: 0.64,
    parallaxFactor: 0.1,
  ),
  SpaceLandmark(
    id: 'black_hole',
    assetPath: spaceBlackHoleBackgroundAsset,
    startKm: 5600,
    visibleKm: 760,
    scale: 0.74,
    startAnchor: Offset(0.42, -0.18),
    endAnchor: Offset(0.34, 1.14),
    opacity: 0.76,
    parallaxFactor: 0.09,
  ),
  SpaceLandmark(
    id: 'andromeda',
    assetPath: spaceAndromedaBackgroundAsset,
    startKm: 7000,
    visibleKm: 860,
    scale: 0.92,
    startAnchor: Offset(0.7, -0.18),
    endAnchor: Offset(0.76, 1.12),
    opacity: 0.58,
    parallaxFactor: 0.08,
  ),
  SpaceLandmark(
    id: 'deep_quasar',
    assetPath: spaceDeepQuasarBackgroundAsset,
    startKm: 8500,
    visibleKm: 920,
    scale: 0.76,
    startAnchor: Offset(0.5, -0.2),
    endAnchor: Offset(0.46, 1.16),
    opacity: 0.7,
    parallaxFactor: 0.08,
  ),
];

SpaceLandmark landmarkForDistance(double distanceKm) {
  for (final landmark in spaceLandmarks.reversed) {
    if (distanceKm >= landmark.startKm) {
      return landmark;
    }
  }

  return spaceLandmarks.first;
}

List<SpaceLandmark> visibleLandmarksForDistance(double distanceKm) {
  return spaceLandmarks
      .where((landmark) => landmark.isVisibleAt(distanceKm))
      .toList(growable: false);
}

const List<String> spaceLandmarkAssetPaths = [
  spaceEarthMoonBackgroundAsset,
  spaceMarsBackgroundAsset,
  spaceAsteroidBeltBackgroundAsset,
  spaceJupiterBackgroundAsset,
  spaceSaturnBackgroundAsset,
  spaceIceGiantsBackgroundAsset,
  spaceKuiperBeltBackgroundAsset,
  spaceOrionNebulaBackgroundAsset,
  spacePillarsCreationBackgroundAsset,
  spaceBlackHoleBackgroundAsset,
  spaceAndromedaBackgroundAsset,
  spaceDeepQuasarBackgroundAsset,
];
