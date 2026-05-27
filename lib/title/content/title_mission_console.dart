import 'dart:ui';

import 'package:arcade_one/l10n/l10n.dart';
import 'package:arcade_one/title/content/title_mission_metric.dart';
import 'package:flutter/material.dart';

class TitleMissionConsole extends StatelessWidget {
  const TitleMissionConsole({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0x44FFFFFF)),
            borderRadius: BorderRadius.circular(24),
            color: const Color(0x33101835),
          ),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.titleConsoleTitle,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 18),
                TitleMissionMetric(
                  icon: Icons.public_rounded,
                  label: l10n.titleMissionDistance,
                  value: l10n.titleMissionDistanceValue,
                ),
                const SizedBox(height: 14),
                TitleMissionMetric(
                  icon: Icons.warning_amber_rounded,
                  label: l10n.titleMissionThreat,
                  value: l10n.titleMissionThreatValue,
                ),
                const SizedBox(height: 14),
                TitleMissionMetric(
                  icon: Icons.bolt_rounded,
                  label: l10n.titleShipStatus,
                  value: l10n.titleShipStatusValue,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
