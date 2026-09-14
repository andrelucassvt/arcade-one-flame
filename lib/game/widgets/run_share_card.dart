import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:arcade_one/game/player_ship/player_ship.dart';
import 'package:arcade_one/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

Future<Uint8List?> captureRunShareCard(GlobalKey boundaryKey) async {
  final renderObject = boundaryKey.currentContext?.findRenderObject();
  if (renderObject is! RenderRepaintBoundary) {
    return null;
  }

  final image = await renderObject.toImage(pixelRatio: 3);
  try {
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  } finally {
    image.dispose();
  }
}

class RunShareCard extends StatelessWidget {
  const RunShareCard({
    required this.distanceKm,
    required this.bestDistanceKm,
    required this.maxCombo,
    required this.isNewRecord,
    required this.playerShip,
    super.key,
  });

  final int distanceKm;
  final int bestDistanceKm;
  final int maxCombo;
  final bool isNewRecord;
  final PlayerShipSkin playerShip;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF17224D), Color(0xFF080A19)],
        ),
        border: Border.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.gameOverTitle,
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(
                color: Colors.white70,
                fontWeight: FontWeight.w800,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 16),
            Image.asset(
              playerShip.assetPath,
              height: 72,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.distanceText(distanceKm),
              textAlign: TextAlign.center,
              style: textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (isNewRecord) ...[
              const SizedBox(height: 10),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFFFFC857),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  child: Text(
                    l10n.gameOverNewRecord,
                    style: textTheme.labelSmall?.copyWith(
                      color: const Color(0xFF111827),
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),
            Text(
              l10n.bestDistanceText(bestDistanceKm),
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(color: Colors.white70),
            ),
            if (maxCombo > 0) ...[
              const SizedBox(height: 4),
              Text(
                l10n.gameOverMaxCombo(maxCombo),
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(color: Colors.white70),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
