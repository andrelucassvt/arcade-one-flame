import 'package:arcade_one/game/game_image_assets.dart';
import 'package:arcade_one/l10n/l10n.dart';
import 'package:flutter/material.dart';

class TitleHero extends StatelessWidget {
  const TitleHero({required this.isWide, super.key});

  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final headlineStyle = Theme.of(context).textTheme.displayLarge?.copyWith(
      color: Colors.white,
      fontSize: isWide ? 92 : 64,
      fontWeight: FontWeight.w900,
      height: 0.92,
      letterSpacing: 0,
      shadows: const [
        Shadow(
          color: Color(0xAA17D8FF),
          blurRadius: 22,
          offset: Offset(0, 8),
        ),
      ],
    );

    return Column(
      crossAxisAlignment:
          isWide ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            const SizedBox(width: 300, height: 230),
            Positioned(
              left: 12,
              top: 16,
              child: Transform.rotate(
                angle: -0.32,
                child: Image.asset(
                  looseMeteorImageAsset,
                  width: 56,
                  filterQuality: FilterQuality.none,
                ),
              ),
            ),
            Positioned(
              right: 14,
              bottom: 18,
              child: Transform.rotate(
                angle: 0.55,
                child: Image.asset(
                  looseMeteorImageAsset,
                  width: 42,
                  filterQuality: FilterQuality.none,
                ),
              ),
            ),
            Transform.rotate(
              angle: -0.14,
              child: Image.asset(
                playerShipImageAsset,
                width: isWide ? 260 : 220,
                filterQuality: FilterQuality.none,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: isWide ? Alignment.centerLeft : Alignment.center,
          child: Text(l10n.titleHeadline, style: headlineStyle),
        ),
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Text(
            l10n.titleSubtitle,
            textAlign: isWide ? TextAlign.start : TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: const Color(0xFFDCE9FF),
              height: 1.35,
              letterSpacing: 0,
            ),
          ),
        ),
      ],
    );
  }
}
