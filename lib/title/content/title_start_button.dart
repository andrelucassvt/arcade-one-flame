import 'package:arcade_one/game/game.dart';
import 'package:arcade_one/l10n/l10n.dart';
import 'package:flutter/material.dart';

class TitleStartButton extends StatelessWidget {
  const TitleStartButton({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SizedBox(
      width: 260,
      height: 64,
      child: ElevatedButton.icon(
        onPressed: () async {
          await Navigator.of(
            context,
          ).pushReplacement<void, void>(GamePage.route());
        },
        icon: const Icon(Icons.rocket_launch_rounded),
        label: Text(l10n.titleButtonStart),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFC857),
          foregroundColor: const Color(0xFF111827),
          textStyle: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 12,
          shadowColor: const Color(0x88FFC857),
        ),
      ),
    );
  }
}
